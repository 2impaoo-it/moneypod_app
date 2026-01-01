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

// GetByID lấy giao dịch theo ID
func (r *TransactionRepository) GetByID(transactionID uuid.UUID) (*models.Transaction, error) {
	var transaction models.Transaction
	err := r.db.Preload("Wallet").Where("id = ?", transactionID).First(&transaction).Error
	return &transaction, err
}

// GetByIDAndUserID lấy giao dịch theo ID và UserID (để bảo mật)
func (r *TransactionRepository) GetByIDAndUserID(transactionID, userID uuid.UUID) (*models.Transaction, error) {
	var transaction models.Transaction
	err := r.db.Preload("Wallet").Where("id = ? AND user_id = ?", transactionID, userID).First(&transaction).Error
	return &transaction, err
}

// Update cập nhật giao dịch
func (r *TransactionRepository) Update(tx *gorm.DB, transaction *models.Transaction) error {
	return tx.Save(transaction).Error
}

// Delete xóa giao dịch
func (r *TransactionRepository) Delete(tx *gorm.DB, transactionID uuid.UUID) error {
	return tx.Delete(&models.Transaction{}, transactionID).Error
}

// GetByUserIDWithFilters lấy giao dịch với filter và pagination
func (r *TransactionRepository) GetByUserIDWithFilters(userID uuid.UUID, walletID, category, transactionType string, month int, year int, offset, limit int) ([]models.Transaction, int64, error) {
	var transactions []models.Transaction
	var total int64

	query := r.db.Model(&models.Transaction{}).Where("user_id = ?", userID)

	// Filter by category
	if category != "" {
		query = query.Where("category = ?", category)
	}

	// Filter by type (income/expense)
	if transactionType != "" {
		query = query.Where("type = ?", transactionType)
	}

	// Filter by month and year
	if month > 0 && year > 0 {
		query = query.Where("EXTRACT(MONTH FROM date) = ? AND EXTRACT(YEAR FROM date) = ?", month, year)
	} else if year > 0 {
		query = query.Where("EXTRACT(YEAR FROM date) = ?", year)
	}

	// Count total
	query.Count(&total)

	// Get paginated results
	err := query.Preload("Wallet").
		Order("date desc").
		Offset(offset).
		Limit(limit).
		Find(&transactions).Error

	return transactions, total, err
}
