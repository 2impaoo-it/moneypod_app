package services

import (
	"errors"
	"fmt"

	"github.com/2impaoo-it/moneypod_app/backend/internal/models"
	"github.com/2impaoo-it/moneypod_app/backend/internal/repositories"
	"github.com/2impaoo-it/moneypod_app/backend/pkg/utils"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type GroupService struct {
	db           *gorm.DB
	notifService *NotificationService         // Dùng để gửi thông báo
	userRepo     *repositories.UserRepository // Dùng để tìm user qua SĐT
}

// Cập nhật hàm khởi tạo để nhận thêm dependency
func NewGroupService(db *gorm.DB, notif *NotificationService, userRepo *repositories.UserRepository) *GroupService {
	return &GroupService{
		db:           db,
		notifService: notif,
		userRepo:     userRepo,
	}
}

// CreateMemberInput: Input từ Client
type CreateMemberInput struct {
	UserID string `json:"user_id"` // Có thể là UUID hoặc Số điện thoại
}

func (s *GroupService) CreateGroup(creatorID uuid.UUID, name, description string, membersInput []CreateMemberInput) (*models.Group, error) {
	// Bắt đầu Transaction (Đảm bảo cả 2 việc cùng thành công)
	tx := s.db.Begin()

	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	// 1. Sinh InviteCode
	inviteCode := utils.GenerateInviteCode(6)

	// 2. Tạo nhóm
	newGroup := &models.Group{
		Name:        name,
		Description: description,
		InviteCode:  inviteCode,
	}

	if err := tx.Create(newGroup).Error; err != nil {
		tx.Rollback()
		return nil, err
	}

	// 4. Xử lý danh sách members
	var leaderFound bool
	for _, memberInput := range membersInput {
		var memberUserID uuid.UUID
		var role string

		// Xử lý logic "current_user"
		if memberInput.UserID == "current_user" {
			memberUserID = creatorID
			role = "leader" // Người tạo là leader
			leaderFound = true
		} else {
			// 🔥 LOGIC MỚI: Kiểm tra xem là UUID hay SĐT

			// A. Thử parse xem có phải UUID không
			parsedID, err := uuid.Parse(memberInput.UserID)
			if err == nil {
				var count int64
				s.db.Model(&models.User{}).Where("id = ?", parsedID).Count(&count)
				if count == 0 {
					tx.Rollback()
					// Bỏ qua hoặc báo lỗi tùy bạn. Ở đây mình báo lỗi để dễ debug.
					return nil, errors.New("không tìm thấy User ID: " + memberInput.UserID)
				}

				memberUserID = parsedID
			} else {
				// B. Không phải UUID -> Coi như là SĐT -> Tìm trong DB
				// Lưu ý: Cần đảm bảo UserRepo có hàm FindByPhone
				user, err := s.userRepo.FindByPhone(memberInput.UserID)
				if err != nil {
					tx.Rollback()
					return nil, errors.New("không tìm thấy thành viên có SĐT hoặc ID: " + memberInput.UserID)
				}
				memberUserID = user.ID
			}
			role = "member"
		}

		// Tạo member
		member := &models.GroupMember{
			GroupID: newGroup.ID,
			UserID:  memberUserID,
			Role:    role,
		}

		if err := tx.Create(member).Error; err != nil {
			tx.Rollback()
			return nil, err
		}
	}

	// 5. Kiểm tra phải có ít nhất 1 leader (người tạo)
	if !leaderFound {
		tx.Rollback()
		return nil, errors.New("danh sách members phải có \"current_user\" làm leader")
	}

	// 6. Commit transaction
	if err := tx.Commit().Error; err != nil {
		return nil, err
	}

	return newGroup, nil
}

// Lấy danh sách nhóm mình đã tham gia
func (s *GroupService) GetMyGroups(userID uuid.UUID) ([]models.Group, error) {
	var members []models.GroupMember
	var groupIDs []uuid.UUID

	// Tìm tất cả các nhóm mà user này là thành viên
	s.db.Where("user_id = ?", userID).Find(&members)

	for _, m := range members {
		groupIDs = append(groupIDs, m.GroupID)
	}

	// Lấy thông tin chi tiết các nhóm đó
	var groups []models.Group
	if len(groupIDs) > 0 {
		// Thêm .Preload("Members") và .Preload("Members.User")
		// Để lấy luôn danh sách thành viên và thông tin (tên, avatar) của thành viên đó
		err := s.db.
			Preload("Members").
			Preload("Members.User"). // Lấy thêm info User trong Member
			Preload("Expenses").     // Lấy thêm chi tiêu (nếu muốn xem sơ qua)
			Where("id IN ?", groupIDs).
			Find(&groups).Error

		return groups, err
	}
	return []models.Group{}, nil
}

// JoinGroup: Người dùng nhập mã code để vào nhóm
func (s *GroupService) JoinGroup(userID uuid.UUID, groupCode string) error {
	// 1. Tìm nhóm dựa trên InviteCode
	var group models.Group
	if err := s.db.Where("invite_code = ?", groupCode).First(&group).Error; err != nil {
		return errors.New("mã nhóm không tồn tại") // Báo lỗi nếu mã sai
	}

	// 2. Kiểm tra xem user này đã ở trong nhóm chưa?
	var existingMember models.GroupMember
	err := s.db.Where("group_id = ? AND user_id = ?", group.ID, userID).First(&existingMember).Error
	if err == nil {
		return errors.New("bạn đã tham gia nhóm này rồi") // Nếu tìm thấy thì báo lỗi
	}

	// 3. Thêm vào nhóm (Role mặc định là member)
	newMember := models.GroupMember{
		GroupID: group.ID,
		UserID:  userID,
		Role:    "member",
	}

	return s.db.Create(&newMember).Error
}

type SplitItem struct {
	UserID uuid.UUID `json:"user_id"`
	Amount float64   `json:"amount"`
}

// CreateExpenseRequest: Request từ App gửi lên
type CreateExpenseRequest struct {
	Amount      float64   `json:"amount"`
	Description string    `json:"description"`
	ImageURL    string    `json:"image_url"`
	PayerID     uuid.UUID `json:"payer_id"`

	SplitDetails []SplitItem `json:"split_details"`
}

// CreateExpense: Thêm hóa đơn và tạo nợ
func (s *GroupService) CreateExpense(groupID uuid.UUID, req CreateExpenseRequest) error {
	tx := s.db.Begin()

	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	// 1. Lưu hóa đơn gốc (Expense)
	expense := models.Expense{
		GroupID:     groupID,
		PayerID:     req.PayerID,
		Amount:      req.Amount,
		Description: req.Description,
		ImageURL:    req.ImageURL,
	}
	if err := tx.Create(&expense).Error; err != nil {
		tx.Rollback()
		return err
	}

	// 2. LẤY DANH SÁCH THÀNH VIÊN (Đưa lên trước để dùng cho cả tính toán và thông báo)
	var members []models.GroupMember
	if err := tx.Where("group_id = ?", groupID).Find(&members).Error; err != nil {
		tx.Rollback()
		return err
	}

	// 3. XỬ LÝ CHIA TIỀN (LOGIC IF - ELSE)

	// TRƯỜNG HỢP A: Có danh sách chia cụ thể (Chia không đều)
	if len(req.SplitDetails) > 0 {
		for _, item := range req.SplitDetails {
			// Không tạo nợ cho chính người trả tiền
			if item.UserID == req.PayerID {
				continue
			}

			debt := models.Debt{
				ExpenseID:  expense.ID,
				FromUserID: item.UserID,
				ToUserID:   req.PayerID,
				Amount:     item.Amount, // 🔥 Dùng số tiền cụ thể
				IsPaid:     false,
			}

			if err := tx.Create(&debt).Error; err != nil {
				tx.Rollback()
				return err
			}
		}

	} else {
		// TRƯỜNG HỢP B: Không có danh sách -> CHIA ĐỀU (Code cũ của bạn)
		totalMembers := len(members)
		if totalMembers <= 1 {
			tx.Rollback()
			return errors.New("nhóm cần ít nhất 2 người để chia tiền")
		}

		// Tính tiền chia đều
		splitAmount := req.Amount / float64(totalMembers)

		// Tạo nợ tự động
		for _, member := range members {
			if member.UserID == req.PayerID {
				continue
			}

			debt := models.Debt{
				ExpenseID:  expense.ID,
				FromUserID: member.UserID,
				ToUserID:   req.PayerID,
				Amount:     splitAmount, // 🔥 Dùng số tiền chia đều
				IsPaid:     false,
			}

			if err := tx.Create(&debt).Error; err != nil {
				tx.Rollback()
				return err
			}
		}
	}

	// Commit Transaction
	if err := tx.Commit().Error; err != nil {
		return err
	}

	// 🔥 4. LOGIC GỬI THÔNG BÁO FCM (Giữ nguyên logic cũ của bạn)
	go func() {
		// A. Lấy tên người trả tiền
		var payer models.User
		s.db.Select("full_name").First(&payer, "id = ?", req.PayerID)

		// B. Lọc lấy Token của các thành viên khác
		var tokens []string
		for _, m := range members {
			if m.UserID != req.PayerID {
				var user models.User
				// Chỉ lấy trường fcm_token
				if err := s.db.Select("fcm_token").First(&user, "id = ?", m.UserID).Error; err == nil {
					if user.FCMToken != "" {
						tokens = append(tokens, user.FCMToken)
					}
				}
			}
		}

		// C. Gửi thông báo
		if len(tokens) > 0 {
			title := "💸 Hóa đơn mới!"
			body := fmt.Sprintf("%s vừa thêm: %s - %.0f đ", payer.FullName, req.Description, req.Amount)
			s.notifService.SendMulticastNotification(tokens, title, body)
		}
	}()

	return nil
}

// MarkDebtAsPaid: Đánh dấu đã trả nợ
func (s *GroupService) MarkDebtAsPaid(debtID uuid.UUID, userID uuid.UUID) error {
	var debt models.Debt

	// Tìm khoản nợ
	if err := s.db.First(&debt, "id = ?", debtID).Error; err != nil {
		return errors.New("khoản nợ không tồn tại")
	}

	// Kiểm tra quyền: Chỉ chủ nợ (ToUserID) mới được đánh dấu đã trả
	if debt.ToUserID != userID {
		return errors.New("bạn không phải chủ nợ, không có quyền xác nhận")
	}

	// Kiểm tra đã trả chưa
	if debt.IsPaid {
		return errors.New("khoản nợ này đã được thanh toán rồi")
	}

	// Đánh dấu đã trả
	debt.IsPaid = true
	return s.db.Save(&debt).Error
}

// GetMyDebts: Xem danh sách nợ của tôi trong nhóm
func (s *GroupService) GetMyDebts(groupID uuid.UUID, userID uuid.UUID) ([]models.Debt, error) {
	var debts []models.Debt

	// Lấy tất cả nợ của user trong nhóm này
	err := s.db.Preload("Expense").
		Joins("JOIN expenses ON debts.expense_id = expenses.id").
		Where("expenses.group_id = ? AND debts.from_user_id = ?", groupID, userID).
		Find(&debts).Error

	return debts, err
}

// GetDebtsToMe: Xem ai nợ tôi trong nhóm
func (s *GroupService) GetDebtsToMe(groupID uuid.UUID, userID uuid.UUID) ([]models.Debt, error) {
	var debts []models.Debt

	// Lấy tất cả nợ người khác nợ user trong nhóm này
	err := s.db.Preload("Expense").
		Joins("JOIN expenses ON debts.expense_id = expenses.id").
		Where("expenses.group_id = ? AND debts.to_user_id = ?", groupID, userID).
		Find(&debts).Error

	return debts, err
}

// GetGroupExpenses: Xem lịch sử chi tiêu của nhóm (bao gồm hình ảnh bill)
func (s *GroupService) GetGroupExpenses(groupID uuid.UUID) ([]models.Expense, error) {
	var expenses []models.Expense

	// Lấy tất cả chi tiêu trong nhóm, bao gồm thông tin nợ
	err := s.db.Preload("Debts").
		Where("group_id = ?", groupID).
		Order("created_at desc").
		Find(&expenses).Error

	return expenses, err
}

// Lấy chi tiết một nhóm (kèm thành viên)
func (s *GroupService) GetGroupDetail(groupID uuid.UUID) (*models.Group, error) {
	var group models.Group

	// Preload Members và User bên trong Member
	err := s.db.Preload("Members").Preload("Members.User").First(&group, "id = ?", groupID).Error

	if err != nil {
		return nil, errors.New("nhóm không tồn tại")
	}
	return &group, nil
}

// AddMemberByPhone: Thêm thành viên vào nhóm bằng SĐT
func (s *GroupService) AddMemberViaPhone(requesterID uuid.UUID, groupID uuid.UUID, phone string) error {
	// 1. Kiểm tra quyền: Người yêu cầu (requester) phải đang ở trong nhóm đó
	var requesterMember models.GroupMember
	if err := s.db.Where("group_id = ? AND user_id = ?", groupID, requesterID).First(&requesterMember).Error; err != nil {
		return errors.New("bạn không phải thành viên nhóm này hoặc nhóm không tồn tại")
	}

	// 2. Tìm người dùng mới qua SĐT
	newUser, err := s.userRepo.FindByPhone(phone)
	if err != nil {
		return errors.New("không tìm thấy người dùng với số điện thoại này")
	}

	// 3. Kiểm tra xem người mới đã ở trong nhóm chưa
	var existingMember models.GroupMember
	err = s.db.Where("group_id = ? AND user_id = ?", groupID, newUser.ID).First(&existingMember).Error
	if err == nil {
		return errors.New("người dùng này đã là thành viên của nhóm rồi")
	}

	// 4. Thêm vào nhóm
	newMember := models.GroupMember{
		GroupID: groupID,
		UserID:  newUser.ID,
		Role:    "member",
	}

	if err := s.db.Create(&newMember).Error; err != nil {
		return err
	}

	// (Optional) Gửi thông báo cho người mới biết mình vừa được thêm vào nhóm...
	// Bạn có thể dùng s.notifService để gửi FCM ở đây nếu muốn.

	return nil
}

// DeleteGroup: Xóa nhóm (Chỉ Leader mới được xóa)
func (s *GroupService) DeleteGroup(requesterID uuid.UUID, groupID uuid.UUID) error {
	// 1. Kiểm tra nhóm tồn tại không
	var group models.Group
	if err := s.db.First(&group, "id = ?", groupID).Error; err != nil {
		return errors.New("nhóm không tồn tại")
	}

	// 2. Kiểm tra quyền: Requester phải là LEADER
	var member models.GroupMember
	err := s.db.Where("group_id = ? AND user_id = ?", groupID, requesterID).First(&member).Error
	if err != nil {
		return errors.New("bạn không phải thành viên nhóm này")
	}
	if member.Role != "leader" {
		return errors.New("chỉ Trưởng nhóm (Leader) mới có quyền xóa nhóm")
	}

	// 3. Bắt đầu Transaction để xóa sạch sẽ (Soft Delete)
	tx := s.db.Begin()
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	// A. Xóa các khoản nợ (Debts) liên quan đến nhóm (thông qua Expenses)
	// Tìm các expense của nhóm trước
	var expenseIDs []uuid.UUID
	tx.Model(&models.Expense{}).Where("group_id = ?", groupID).Pluck("id", &expenseIDs)

	if len(expenseIDs) > 0 {
		if err := tx.Where("expense_id IN ?", expenseIDs).Delete(&models.Debt{}).Error; err != nil {
			tx.Rollback()
			return err
		}
	}

	// B. Xóa các chi tiêu (Expenses)
	if err := tx.Where("group_id = ?", groupID).Delete(&models.Expense{}).Error; err != nil {
		tx.Rollback()
		return err
	}

	// C. Xóa các thành viên (Members)
	if err := tx.Where("group_id = ?", groupID).Delete(&models.GroupMember{}).Error; err != nil {
		tx.Rollback()
		return err
	}

	// D. Cuối cùng: Xóa Nhóm (Group)
	if err := tx.Delete(&group).Error; err != nil {
		tx.Rollback()
		return err
	}

	return tx.Commit().Error
}

// UpdateGroup: Cập nhật tên nhóm, mô tả (Chỉ Leader)
func (s *GroupService) UpdateGroup(requesterID uuid.UUID, groupID uuid.UUID, name, description string) error {
	// 1. Kiểm tra nhóm tồn tại
	var group models.Group
	if err := s.db.First(&group, "id = ?", groupID).Error; err != nil {
		return errors.New("nhóm không tồn tại")
	}

	// 2. Kiểm tra quyền: Requester phải là LEADER
	var member models.GroupMember
	err := s.db.Where("group_id = ? AND user_id = ?", groupID, requesterID).First(&member).Error
	if err != nil {
		return errors.New("bạn không phải thành viên nhóm này")
	}
	if member.Role != "leader" {
		return errors.New("chỉ Trưởng nhóm (Leader) mới có quyền chỉnh sửa thông tin nhóm")
	}

	// 3. Cập nhật thông tin
	if name != "" {
		group.Name = name
	}
	if description != "" {
		group.Description = description
	}

	return s.db.Save(&group).Error
}

// KickMember: Leader xóa thành viên ra khỏi nhóm (chỉ khi không có nợ)
func (s *GroupService) KickMember(requesterID uuid.UUID, groupID uuid.UUID, memberUserID uuid.UUID) error {
	// 1. Kiểm tra quyền: Requester phải là LEADER
	var requesterMember models.GroupMember
	err := s.db.Where("group_id = ? AND user_id = ?", groupID, requesterID).First(&requesterMember).Error
	if err != nil {
		return errors.New("bạn không phải thành viên nhóm này")
	}
	if requesterMember.Role != "leader" {
		return errors.New("chỉ Trưởng nhóm (Leader) mới có quyền xóa thành viên")
	}

	// 2. Không cho phép leader tự kick mình
	if requesterID == memberUserID {
		return errors.New("bạn không thể xóa chính mình khỏi nhóm. Hãy dùng chức năng rời nhóm")
	}

	// 3. Kiểm tra member có tồn tại trong nhóm không
	var memberToKick models.GroupMember
	err = s.db.Where("group_id = ? AND user_id = ?", groupID, memberUserID).First(&memberToKick).Error
	if err != nil {
		return errors.New("thành viên này không thuộc nhóm")
	}

	// 4. Kiểm tra xem member có nợ ai không (FromUserID)
	var debtCount int64
	s.db.Model(&models.Debt{}).
		Joins("JOIN expenses ON debts.expense_id = expenses.id").
		Where("expenses.group_id = ? AND debts.from_user_id = ? AND debts.is_paid = ?", groupID, memberUserID, false).
		Count(&debtCount)
	if debtCount > 0 {
		return errors.New("không thể xóa thành viên này vì họ còn nợ chưa thanh toán")
	}

	// 5. Kiểm tra xem có ai nợ member này không (ToUserID)
	s.db.Model(&models.Debt{}).
		Joins("JOIN expenses ON debts.expense_id = expenses.id").
		Where("expenses.group_id = ? AND debts.to_user_id = ? AND debts.is_paid = ?", groupID, memberUserID, false).
		Count(&debtCount)
	if debtCount > 0 {
		return errors.New("không thể xóa thành viên này vì còn người nợ họ chưa thanh toán")
	}

	// 6. Xóa thành viên
	return s.db.Delete(&memberToKick).Error
}

// LeaveGroup: Thành viên tự rời nhóm (chỉ khi không có nợ)
func (s *GroupService) LeaveGroup(userID uuid.UUID, groupID uuid.UUID) error {
	// 1. Kiểm tra member có tồn tại trong nhóm không
	var member models.GroupMember
	err := s.db.Where("group_id = ? AND user_id = ?", groupID, userID).First(&member).Error
	if err != nil {
		return errors.New("bạn không phải thành viên nhóm này")
	}

	// 2. Không cho phép leader rời nhóm (phải xóa nhóm hoặc chuyển quyền trước)
	if member.Role == "leader" {
		return errors.New("trưởng nhóm không thể rời nhóm. Hãy xóa nhóm hoặc chuyển quyền trước")
	}

	// 3. Kiểm tra xem có nợ ai không (FromUserID)
	var debtCount int64
	s.db.Model(&models.Debt{}).
		Joins("JOIN expenses ON debts.expense_id = expenses.id").
		Where("expenses.group_id = ? AND debts.from_user_id = ? AND debts.is_paid = ?", groupID, userID, false).
		Count(&debtCount)
	if debtCount > 0 {
		return errors.New("bạn không thể rời nhóm vì bạn còn nợ chưa thanh toán")
	}

	// 4. Kiểm tra xem có ai nợ mình không (ToUserID)
	s.db.Model(&models.Debt{}).
		Joins("JOIN expenses ON debts.expense_id = expenses.id").
		Where("expenses.group_id = ? AND debts.to_user_id = ? AND debts.is_paid = ?", groupID, userID, false).
		Count(&debtCount)
	if debtCount > 0 {
		return errors.New("bạn không thể rời nhóm vì còn người nợ bạn chưa thanh toán")
	}

	// 5. Rời nhóm
	return s.db.Delete(&member).Error
}
