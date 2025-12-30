package services

import (
	"errors"
	"fmt"

	"github.com/2impaoo-it/moneypod_app/backend/internal/models"
	"github.com/2impaoo-it/moneypod_app/backend/internal/repositories"
	"github.com/2impaoo-it/moneypod_app/backend/pkg/constants"
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
		if memberInput.UserID == constants.CurrentUser {
			memberUserID = creatorID
			role = constants.RoleLeader // Người tạo là leader
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
			role = constants.RoleMember
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
	if member.Role == constants.RoleLeader {
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

// GetExpenseDetail: Xem chi tiết một hóa đơn
func (s *GroupService) GetExpenseDetail(expenseID uuid.UUID) (*models.Expense, error) {
	var expense models.Expense

	// Preload Debts để xem chi tiết ai nợ bao nhiêu
	err := s.db.Preload("Debts").First(&expense, "id = ?", expenseID).Error
	if err != nil {
		return nil, errors.New("hóa đơn không tồn tại")
	}

	return &expense, nil
}

// DeleteExpense: Xóa hóa đơn (phải xóa luôn các khoản nợ)
func (s *GroupService) DeleteExpense(requesterID uuid.UUID, expenseID uuid.UUID) error {
	// 1. Lấy thông tin expense
	var expense models.Expense
	if err := s.db.First(&expense, "id = ?", expenseID).Error; err != nil {
		return errors.New("hóa đơn không tồn tại")
	}

	// 2. Kiểm tra quyền: Chỉ người trả tiền (Payer) hoặc Leader mới được xóa
	var member models.GroupMember
	err := s.db.Where("group_id = ? AND user_id = ?", expense.GroupID, requesterID).First(&member).Error
	if err != nil {
		return errors.New("bạn không phải thành viên nhóm này")
	}

	// Kiểm tra phải là Payer hoặc Leader
	if expense.PayerID != requesterID && member.Role != "leader" {
		return errors.New("chỉ người trả tiền hoặc Trưởng nhóm mới được xóa hóa đơn này")
	}

	// 3. Bắt đầu transaction
	tx := s.db.Begin()
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	// 4. Xóa các khoản nợ liên quan
	if err := tx.Where("expense_id = ?", expenseID).Delete(&models.Debt{}).Error; err != nil {
		tx.Rollback()
		return err
	}

	// 5. Xóa hóa đơn
	if err := tx.Delete(&expense).Error; err != nil {
		tx.Rollback()
		return err
	}

	return tx.Commit().Error
}

// UpdateExpense: Sửa hóa đơn (Phức tạp - thường khuyến nghị xóa và tạo lại)
func (s *GroupService) UpdateExpense(requesterID uuid.UUID, expenseID uuid.UUID, amount float64, description, imageURL string, splitDetails []SplitItem) error {
	// 1. Lấy thông tin expense cũ
	var expense models.Expense
	if err := s.db.Preload("Debts").First(&expense, "id = ?", expenseID).Error; err != nil {
		return errors.New("hóa đơn không tồn tại")
	}

	// 2. Kiểm tra quyền: Chỉ người trả tiền (Payer) hoặc Leader mới được sửa
	var member models.GroupMember
	err := s.db.Where("group_id = ? AND user_id = ?", expense.GroupID, requesterID).First(&member).Error
	if err != nil {
		return errors.New("bạn không phải thành viên nhóm này")
	}

	if expense.PayerID != requesterID && member.Role != "leader" {
		return errors.New("chỉ người trả tiền hoặc Trưởng nhóm mới được sửa hóa đơn này")
	}

	// 3. Bắt đầu transaction
	tx := s.db.Begin()
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	// 4. Cập nhật thông tin expense
	if amount > 0 {
		expense.Amount = amount
	}
	if description != "" {
		expense.Description = description
	}
	if imageURL != "" {
		expense.ImageURL = imageURL
	}

	if err := tx.Save(&expense).Error; err != nil {
		tx.Rollback()
		return err
	}

	// 5. Nếu có split details mới, kiểm tra và xóa debts cũ rồi tạo lại
	if len(splitDetails) > 0 {
		// 🔥 KIỂM TRA: Nếu có bất kỳ debt nào đã có payment request được confirmed, không cho sửa
		var paidDebts []models.Debt
		if err := tx.Where("expense_id = ? AND is_paid = ?", expenseID, true).Find(&paidDebts).Error; err != nil {
			tx.Rollback()
			return err
		}

		if len(paidDebts) > 0 {
			tx.Rollback()
			return errors.New("không thể sửa hóa đơn này vì đã có người trả nợ. Vui lòng tạo hóa đơn mới")
		}

		// Kiểm tra thêm: Có debt nào đang có payment request pending không
		var pendingPayments int64
		if err := tx.Model(&models.DebtPaymentRequest{}).
			Joins("JOIN debts ON debts.id = debt_payment_requests.debt_id").
			Where("debts.expense_id = ? AND debt_payment_requests.status = ?", expenseID, constants.DebtStatusPending).
			Count(&pendingPayments).Error; err != nil {
			tx.Rollback()
			return err
		}

		if pendingPayments > 0 {
			tx.Rollback()
			return errors.New("không thể sửa hóa đơn này vì đang có yêu cầu trả nợ đang chờ xử lý")
		}

		// Xóa debts cũ (chỉ khi chưa có ai trả)
		if err := tx.Where("expense_id = ?", expenseID).Delete(&models.Debt{}).Error; err != nil {
			tx.Rollback()
			return err
		}

		// Tạo debts mới
		for _, item := range splitDetails {
			if item.UserID == expense.PayerID {
				continue
			}

			debt := models.Debt{
				ExpenseID:  expense.ID,
				FromUserID: item.UserID,
				ToUserID:   expense.PayerID,
				Amount:     item.Amount,
				IsPaid:     false,
			}

			if err := tx.Create(&debt).Error; err != nil {
				tx.Rollback()
				return err
			}
		}
	}

	return tx.Commit().Error
}

// RequestDebtPayment: Người nợ gửi request đã trả nợ
func (s *GroupService) RequestDebtPayment(debtID uuid.UUID, fromUserID uuid.UUID, paymentWalletID uuid.UUID, note string) error {
	// 1. Kiểm tra debt có tồn tại không
	var debt models.Debt
	if err := s.db.Preload("Expense").First(&debt, "id = ?", debtID).Error; err != nil {
		return errors.New("khoản nợ không tồn tại")
	}

	// 2. Kiểm tra quyền: Phải là người nợ (FromUserID)
	if debt.FromUserID != fromUserID {
		return errors.New("bạn không phải người nợ của khoản này")
	}

	// 3. Kiểm tra đã trả chưa
	if debt.IsPaid {
		return errors.New("khoản nợ này đã được thanh toán rồi")
	}

	// 4. Kiểm tra đã có request pending chưa
	var existingRequest models.DebtPaymentRequest
	err := s.db.Where("debt_id = ? AND status = ?", debtID, constants.DebtStatusPending).First(&existingRequest).Error
	if err == nil {
		return errors.New("đã có request trả nợ đang chờ xác nhận")
	}

	// 5. Kiểm tra ví có thuộc về người nợ không
	var wallet models.Wallet
	if err := s.db.Where("id = ? AND user_id = ?", paymentWalletID, fromUserID).First(&wallet).Error; err != nil {
		return errors.New("ví thanh toán không hợp lệ hoặc không thuộc về bạn")
	}

	// 6. Kiểm tra số dư
	if wallet.Balance < debt.Amount {
		return errors.New("số dư ví không đủ để thanh toán")
	}

	// 7. Tạo payment request
	paymentRequest := models.DebtPaymentRequest{
		DebtID:          debtID,
		FromUserID:      fromUserID,
		ToUserID:        debt.ToUserID,
		PaymentWalletID: paymentWalletID,
		Amount:          debt.Amount,
		Status:          constants.DebtStatusPending,
		Note:            note,
	}

	if err := s.db.Create(&paymentRequest).Error; err != nil {
		return err
	}

	// 8. Gửi thông báo cho chủ nợ
	go func() {
		var debtor, creditor models.User
		s.db.Select("full_name, fcm_token").First(&debtor, "id = ?", fromUserID)
		s.db.Select("full_name, fcm_token").First(&creditor, "id = ?", debt.ToUserID)

		if creditor.FCMToken != "" && s.notifService != nil {
			title := "💰 Yêu cầu xác nhận thanh toán"
			body := fmt.Sprintf("%s thông báo đã trả nợ %.0f đ. Vui lòng xác nhận!", debtor.FullName, debt.Amount)
			s.notifService.SendNotification(creditor.FCMToken, title, body)
		}
	}()

	return nil
}

// GetPendingPaymentRequests: Lấy danh sách request trả nợ chờ xác nhận (của chủ nợ)
func (s *GroupService) GetPendingPaymentRequests(userID uuid.UUID) ([]models.DebtPaymentRequest, error) {
	var requests []models.DebtPaymentRequest

	err := s.db.Preload("Debt").Preload("Debt.Expense").
		Where("to_user_id = ? AND status = ?", userID, constants.DebtStatusPending).
		Order("created_at desc").
		Find(&requests).Error

	return requests, err
}

// ConfirmDebtPayment: Chủ nợ xác nhận đã nhận tiền
func (s *GroupService) ConfirmDebtPayment(requestID uuid.UUID, creditorID uuid.UUID, receiveWalletID uuid.UUID) error {
	tx := s.db.Begin()
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	// 1. Lấy payment request
	var paymentRequest models.DebtPaymentRequest
	if err := tx.Preload("Debt").First(&paymentRequest, "id = ?", requestID).Error; err != nil {
		tx.Rollback()
		return errors.New("request không tồn tại")
	}

	// 2. Kiểm tra quyền: Phải là chủ nợ
	if paymentRequest.ToUserID != creditorID {
		tx.Rollback()
		return errors.New("bạn không phải chủ nợ của khoản này")
	}

	// 3. Kiểm tra status
	if paymentRequest.Status != constants.DebtStatusPending {
		tx.Rollback()
		return errors.New("request này đã được xử lý rồi")
	}

	// 4. Kiểm tra ví nhận tiền có thuộc về chủ nợ không
	var receiveWallet models.Wallet
	if err := tx.Where("id = ? AND user_id = ?", receiveWalletID, creditorID).First(&receiveWallet).Error; err != nil {
		tx.Rollback()
		return errors.New("ví nhận tiền không hợp lệ hoặc không thuộc về bạn")
	}

	// 5. Lấy ví trả tiền của người nợ
	var paymentWallet models.Wallet
	if err := tx.Where("id = ?", paymentRequest.PaymentWalletID).First(&paymentWallet).Error; err != nil {
		tx.Rollback()
		return errors.New("ví thanh toán không tồn tại")
	}

	// 6. Kiểm tra số dư người nợ
	if paymentWallet.Balance < paymentRequest.Amount {
		tx.Rollback()
		return errors.New("người nợ không đủ số dư trong ví để thanh toán")
	}

	// 7. Thực hiện chuyển tiền
	// Trừ tiền ví người nợ
	paymentWallet.Balance -= paymentRequest.Amount
	if err := tx.Save(&paymentWallet).Error; err != nil {
		tx.Rollback()
		return err
	}

	// Cộng tiền ví chủ nợ
	receiveWallet.Balance += paymentRequest.Amount
	if err := tx.Save(&receiveWallet).Error; err != nil {
		tx.Rollback()
		return err
	}

	// 8. Cập nhật debt status
	var debt models.Debt
	if err := tx.First(&debt, "id = ?", paymentRequest.DebtID).Error; err != nil {
		tx.Rollback()
		return err
	}
	debt.IsPaid = true
	if err := tx.Save(&debt).Error; err != nil {
		tx.Rollback()
		return err
	}

	// 9. Cập nhật payment request status
	paymentRequest.Status = constants.DebtStatusConfirmed
	paymentRequest.ReceiveWalletID = &receiveWalletID
	if err := tx.Save(&paymentRequest).Error; err != nil {
		tx.Rollback()
		return err
	}

	// Commit transaction
	if err := tx.Commit().Error; err != nil {
		return err
	}

	// 10. Gửi thông báo cho người nợ
	go func() {
		if s.notifService == nil {
			return
		}
		var debtor, creditor models.User
		s.db.Select("full_name, fcm_token").First(&debtor, "id = ?", paymentRequest.FromUserID)
		s.db.Select("full_name, fcm_token").First(&creditor, "id = ?", creditorID)

		if debtor.FCMToken != "" {
			title := "✅ Thanh toán đã được xác nhận"
			body := fmt.Sprintf("%s đã xác nhận nhận được %.0f đ. Bạn đã thanh toán thành công!", creditor.FullName, paymentRequest.Amount)
			s.notifService.SendNotification(debtor.FCMToken, title, body)
		}
	}()

	return nil
}

// RejectDebtPayment: Chủ nợ từ chối request trả nợ
func (s *GroupService) RejectDebtPayment(requestID uuid.UUID, creditorID uuid.UUID, reason string) error {
	// 1. Lấy payment request
	var paymentRequest models.DebtPaymentRequest
	if err := s.db.First(&paymentRequest, "id = ?", requestID).Error; err != nil {
		return errors.New("request không tồn tại")
	}

	// 2. Kiểm tra quyền
	if paymentRequest.ToUserID != creditorID {
		return errors.New("bạn không phải chủ nợ của khoản này")
	}

	// 3. Kiểm tra status
	if paymentRequest.Status != constants.DebtStatusPending {
		return errors.New("request này đã được xử lý rồi")
	}

	// 4. Cập nhật status
	paymentRequest.Status = constants.DebtStatusRejected
	if reason != "" {
		paymentRequest.Note = reason
	}

	if err := s.db.Save(&paymentRequest).Error; err != nil {
		return err
	}

	// 5. Gửi thông báo cho người nợ
	go func() {
		if s.notifService == nil {
			return
		}
		var debtor, creditor models.User
		s.db.Select("full_name, fcm_token").First(&debtor, "id = ?", paymentRequest.FromUserID)
		s.db.Select("full_name, fcm_token").First(&creditor, "id = ?", creditorID)

		if debtor.FCMToken != "" {
			title := "❌ Thanh toán bị từ chối"
			body := fmt.Sprintf("%s đã từ chối xác nhận thanh toán %.0f đ", creditor.FullName, paymentRequest.Amount)
			if reason != "" {
				body += fmt.Sprintf(". Lý do: %s", reason)
			}
			s.notifService.SendNotification(debtor.FCMToken, title, body)
		}
	}()

	return nil
}
