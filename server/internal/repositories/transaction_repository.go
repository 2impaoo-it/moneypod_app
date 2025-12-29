package repositories

import (
	"github.com/2impaoo-it/moneypod_app/backend/internal/models"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type TransactionRepository struct {
	db *gorm.DB
}

func NewTransactionRepository(db *gorm.DB) *TransactionRepository {
	return &TransactionRepository{db: db}
}

// 1. Tạo giao dịch mới
func (r *TransactionRepository) Create(transaction *models.Transaction) error {
	return r.db.Create(transaction).Error
}

// Tạo giao dịch mới với transaction context
func (r *TransactionRepository) CreateWithTx(tx *gorm.DB, transaction *models.Transaction) error {
	return tx.Create(transaction).Error
}

// 2. Lấy danh sách giao dịch của User (Có thể thêm phân trang sau này)
func (r *TransactionRepository) GetByUserID(userID uuid.UUID) ([]models.Transaction, error) {
	var transactions []models.Transaction
	// Preload Wallet để lấy luôn tên ví nếu cần
	err := r.db.Preload("Wallet").Where("user_id = ?", userID).Order("date desc").Find(&transactions).Error
	return transactions, err
}

// 3. Lấy giao dịch gần đây (Dùng cho Dashboard Home)
// limit: Số lượng muốn lấy (ví dụ 5 cái)
func (r *TransactionRepository) GetRecent(userID uuid.UUID, limit int) ([]models.Transaction, error) {
	var transactions []models.Transaction

	err := r.db.Where("user_id = ?", userID).
		Order("date desc"). // Sắp xếp mới nhất lên đầu
		Limit(limit).       // Chỉ lấy số lượng nhất định
		Find(&transactions).Error

	return transactions, err
}
