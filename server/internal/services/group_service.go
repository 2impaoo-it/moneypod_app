package services

import (
	"errors"
	"math/rand"
	"time"

	"github.com/2impaoo-it/moneypod_app/backend/internal/models"
	"gorm.io/gorm"
)

type GroupService struct {
	db *gorm.DB
}

func NewGroupService(db *gorm.DB) *GroupService {
	return &GroupService{db: db}
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

func (s *GroupService) CreateGroup(creatorID uint, name string) (*models.Group, error) {
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
func (s *GroupService) GetMyGroups(userID uint) ([]models.Group, error) {
	var members []models.GroupMember
	var groupIDs []uint

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
func (s *GroupService) JoinGroup(userID uint, groupCode string) error {
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
func (s *GroupService) AddExpense(groupID uint, paidByID uint, amount float64, note string, memberIDs []uint) error {
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

	return tx.Commit().Error
}
