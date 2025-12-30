package services

import (
	"errors"
	"fmt"
	"math/rand"
	"time"

	"github.com/2impaoo-it/moneypod_app/backend/internal/models"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type GroupService struct {
	db           *gorm.DB
	notifService *NotificationService
}

func NewGroupService(db *gorm.DB, notifService *NotificationService) *GroupService {
	return &GroupService{db: db, notifService: notifService}
}

// Hàm tạo mã mời ngẫu nhiên 6 ký tự
func generateGroupCode() string {
	const charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	seededRand := rand.New(rand.NewSource(time.Now().UnixNano()))
	b := make([]byte, 6)
	for i := range b {
		b[i] = charset[seededRand.Intn(len(charset))]
	}
	return string(b)
}

func (s *GroupService) CreateGroup(creatorID uuid.UUID, name string) (*models.Group, error) {
	// Bắt đầu Transaction (Đảm bảo cả 2 việc cùng thành công)
	tx := s.db.Begin()

	// 1. Tạo nhóm
	newGroup := &models.Group{
		Name:      name,
		Code:      generateGroupCode(),
		CreatorID: creatorID,
	}

	if err := tx.Create(newGroup).Error; err != nil {
		tx.Rollback()
		return nil, err
	}

	// 2. Add người tạo vào làm Admin ngay lập tức
	member := &models.GroupMember{
		GroupID: newGroup.ID,
		UserID:  creatorID,
		Role:    "admin",
		Balance: 0,
	}

	if err := tx.Create(member).Error; err != nil {
		tx.Rollback()
		return nil, err
	}

	tx.Commit()
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
		err := s.db.Where("id IN ?", groupIDs).Find(&groups).Error
		return groups, err
	}
	return []models.Group{}, nil
}

// JoinGroup: Người dùng nhập mã code để vào nhóm
func (s *GroupService) JoinGroup(userID uuid.UUID, groupCode string) error {
	// 1. Tìm nhóm dựa trên Code
	var group models.Group
	if err := s.db.Where("code = ?", groupCode).First(&group).Error; err != nil {
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
		Balance: 0,
	}

	return s.db.Create(&newMember).Error
}

// AddExpense: Thêm hóa đơn và chia tiền
func (s *GroupService) AddExpense(groupID uuid.UUID, paidByID uuid.UUID, amount float64, note string, memberIDs []uuid.UUID) error {
	tx := s.db.Begin()

	// Nếu lỗi thì rollback toàn bộ
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	// 1. Lưu hóa đơn tổng
	expense := models.GroupExpense{
		GroupID:  groupID,
		PaidByID: paidByID,
		Amount:   amount,
		Note:     note,
	}
	if err := tx.Create(&expense).Error; err != nil {
		tx.Rollback()
		return err
	}

	// 2. Tính tiền mỗi người phải chịu (Chia đều)
	if len(memberIDs) == 0 {
		tx.Rollback()
		return errors.New("phải chọn ít nhất 1 người để chia tiền")
	}
	splitAmount := amount / float64(len(memberIDs))

	// 3. Trừ tiền của từng thành viên (AI CŨNG BỊ TRỪ, kể cả người trả)
	for _, memberID := range memberIDs {
		// a. Lưu vào bảng Split
		split := models.ExpenseSplit{
			GroupExpenseID: expense.ID,
			UserID:         memberID,
			Amount:         splitAmount,
		}
		if err := tx.Create(&split).Error; err != nil {
			tx.Rollback()
			return err
		}

		// b. Cập nhật Balance trong nhóm (Trừ đi khoản phải trả)
		// Tìm member trong nhóm
		var member models.GroupMember
		if err := tx.Where("group_id = ? AND user_id = ?", groupID, memberID).First(&member).Error; err != nil {
			tx.Rollback()
			return err
		}

		// Cập nhật số dư mới
		if err := tx.Model(&member).Update("balance", member.Balance-splitAmount).Error; err != nil {
			tx.Rollback()
			return err
		}
	}

	// 4. Cộng lại tổng tiền cho người ĐÃ TRẢ (Payer)
	var payer models.GroupMember
	if err := tx.Where("group_id = ? AND user_id = ?", groupID, paidByID).First(&payer).Error; err != nil {
		tx.Rollback()
		return err
	}

	// Payer được cộng lại toàn bộ số tiền đã bỏ ra
	if err := tx.Model(&payer).Update("balance", payer.Balance+amount).Error; err != nil {
		tx.Rollback()
		return err
	}

	if err := tx.Commit().Error; err != nil {
        return err
    }

    // --- NOTIFICATION LOGIC ---
    go func() {
        // Fetch tokens of members (excluding sender if desired, but user said "User A creates, send to B, C")
        // We need to fetch Users who are in memberIDs
        var users []models.User
        if len(memberIDs) > 0 {
             // Fetch users to get FCM tokens and Names if needed
             // Actually memberIDs are passed in.
             // We also need to fetch Payer's name if we don't have it fully.
             // But we have `payer` (GroupMember), we need `payer.User.FullName`.
             // Let's refetch payer with User preload or just use what we have? 
             // Payer Preload was not done above.
             var payerUser models.User
             s.db.First(&payerUser, paidByID)

             s.db.Where("id IN ? AND fcm_token <> ''", memberIDs).Find(&users)
             
             var tokens []string
             for _, u := range users {
                 // Don't send to self? User said "User A creates... send to User B, C". 
                 if u.ID != paidByID {
                     tokens = append(tokens, u.FCMToken)
                 }
             }

             if len(tokens) > 0 {
                title := "💸 Hóa đơn mới!"
                body := fmt.Sprintf("%s vừa thêm: %s - %.0f đ", payerUser.FullName, note, amount)
                
                data := map[string]string{
                    "group_id": groupID.String(),
                    "type":     "NEW_EXPENSE",
                }
                
                if s.notifService != nil {
                     s.notifService.SendMulticastNotification(tokens, title, body, data)
                }
             }
        }
    }()

    return nil
}

// 1. GỬI YÊU CẦU TRẢ NỢ (Tạo phiếu Pending)
func (s *GroupService) RequestSettlement(groupID, debtorID, creditorID, walletID uuid.UUID, amount float64) (*models.Settlement, error) {
	// Kiểm tra ví có chính chủ không
	var wallet models.Wallet
	if err := s.db.Where("id = ? AND user_id = ?", walletID, debtorID).First(&wallet).Error; err != nil {
		return nil, errors.New("ví thanh toán không hợp lệ")
	}

	// Kiểm tra xem 2 người này có trong nhóm không (Optional, nên làm cho chặt chẽ)

	settlement := models.Settlement{
		GroupID:    groupID,
		FromUserID: debtorID,
		ToUserID:   creditorID,
		WalletID:   walletID,
		Amount:     amount,
		Status:     "pending",
	}

	if err := s.db.Create(&settlement).Error; err != nil {
		return nil, err
	}
	return &settlement, nil
}

// 2. CHỦ NỢ XÁC NHẬN (Confirm)
func (s *GroupService) ConfirmSettlement(creditorID, settlementID uuid.UUID, isConfirmed bool) error {
	return s.db.Transaction(func(tx *gorm.DB) error {
		var st models.Settlement

		// Tìm phiếu yêu cầu
		if err := tx.First(&st, "id = ?", settlementID).Error; err != nil {
			return errors.New("yêu cầu thanh toán không tồn tại")
		}

		// Bảo mật: Chỉ người nhận tiền (ToUserID) mới được quyền bấm xác nhận
		if st.ToUserID != creditorID {
			return errors.New("bạn không phải chủ nợ, không có quyền xác nhận")
		}

		if st.Status != "pending" {
			return errors.New("yêu cầu này đã được xử lý rồi")
		}

		// TRƯỜNG HỢP 1: TỪ CHỐI
		if !isConfirmed {
			st.Status = "rejected"
			return tx.Save(&st).Error
		}

		// TRƯỜNG HỢP 2: ĐỒNG Ý -> Bắt đầu trừ tiền và update nợ
		st.Status = "confirmed"
		if err := tx.Save(&st).Error; err != nil {
			return err
		}

		// A. Trừ tiền trong Ví của người trả (Debtor)
		var debtorWallet models.Wallet
		if err := tx.First(&debtorWallet, "id = ?", st.WalletID).Error; err != nil {
			return errors.New("ví người trả không tìm thấy")
		}
		// (Optional: Check số dư nếu muốn chặn âm tiền)
		// if debtorWallet.Balance < st.Amount { return errors.New("ví không đủ tiền") }

		debtorWallet.Balance -= st.Amount
		if err := tx.Save(&debtorWallet).Error; err != nil {
			return err
		}

		// B. Tạo một giao dịch (Transaction) để lưu lịch sử cho người trả
		trans := models.Transaction{
			UserID:   st.FromUserID,
			WalletID: st.WalletID,
			Amount:   st.Amount,
			Type:     "expense",
			Category: "debt_payment", // Bạn có thể thêm category này vào DB nếu cần
			Note:     "Trả nợ nhóm",
			Date:     time.Now(),
		}
		if err := tx.Create(&trans).Error; err != nil {
			return err
		}

		// C. Cập nhật số dư thành viên trong nhóm (Quan trọng nhất)
		// Logic:
		// - Người nợ (đang âm) trả tiền -> Số dư tăng lên (về 0)
		// - Chủ nợ (đang dương) nhận tiền -> Số dư giảm xuống (về 0)

		// Update Người Trả (Debtor)
		if err := tx.Model(&models.GroupMember{}).
			Where("group_id = ? AND user_id = ?", st.GroupID, st.FromUserID).
			Update("balance", gorm.Expr("balance + ?", st.Amount)).Error; err != nil {
			return err
		}

		// Update Người Nhận (Creditor)
		if err := tx.Model(&models.GroupMember{}).
			Where("group_id = ? AND user_id = ?", st.GroupID, st.ToUserID).
			Update("balance", gorm.Expr("balance - ?", st.Amount)).Error; err != nil {
			return err
		}

		return nil
	})
}
