package repositories

import (
	"github.com/2impaoo-it/moneypod_app/server/internal/models"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type SavingsRepository struct {
	db *gorm.DB
}

func NewSavingsRepository(db *gorm.DB) *SavingsRepository {
	return &SavingsRepository{db: db}
}

// 1. Tạo mục tiêu mới
func (r *SavingsRepository) CreateGoal(goal *models.SavingsGoal) error {
	return r.db.Create(goal).Error
}

// 2. Lấy danh sách mục tiêu của User
func (r *SavingsRepository) GetGoalsByUserID(userID uuid.UUID) ([]models.SavingsGoal, error) {
	var goals []models.SavingsGoal
	err := r.db.Where("user_id = ?", userID).Find(&goals).Error
	return goals, err
}

// 3. Lấy chi tiết mục tiêu (Hỗ trợ Transaction)
func (r *SavingsRepository) GetGoalByID(tx *gorm.DB, id uuid.UUID) (*models.SavingsGoal, error) {
	var goal models.SavingsGoal
	// Nếu không có tx truyền vào thì dùng db thường
	db := r.db
	if tx != nil {
		db = tx
	}
	err := db.First(&goal, "id = ?", id).Error
	return &goal, err
}

// 4. Update số tiền trong mục tiêu (Hỗ trợ Transaction)
func (r *SavingsRepository) UpdateGoal(tx *gorm.DB, goal *models.SavingsGoal) error {
	return tx.Save(goal).Error
}

// 5. Lưu lịch sử nạp/rút (Hỗ trợ Transaction)
func (r *SavingsRepository) CreateSavingsTrans(tx *gorm.DB, trans *models.SavingsTransaction) error {
	return tx.Create(trans).Error
}

// DeleteGoal: Xóa mục tiêu
func (r *SavingsRepository) DeleteGoal(tx *gorm.DB, goalID uuid.UUID) error {
	return tx.Delete(&models.SavingsGoal{}, goalID).Error
}

// DeleteTransactionsByGoalID: Xóa tất cả lịch sử giao dịch của mục tiêu
func (r *SavingsRepository) DeleteTransactionsByGoalID(tx *gorm.DB, goalID uuid.UUID) error {
	return tx.Where("goal_id = ?", goalID).Delete(&models.SavingsTransaction{}).Error
}

// GetTransactionsByGoalID: Lấy lịch sử giao dịch của mục tiêu
func (r *SavingsRepository) GetTransactionsByGoalID(goalID uuid.UUID) ([]models.SavingsTransaction, error) {
	var transactions []models.SavingsTransaction
	err := r.db.Where("goal_id = ?", goalID).Order("created_at desc").Find(&transactions).Error
	return transactions, err
}
