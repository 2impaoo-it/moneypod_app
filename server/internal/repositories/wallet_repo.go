package repositories

import (
	"github.com/2impaoo-it/moneypod_app/backend/internal/models"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type WalletRepository struct {
	db *gorm.DB
}

func NewWalletRepository(db *gorm.DB) *WalletRepository {
	return &WalletRepository{db: db}
}

// Tạo ví mới
func (r *WalletRepository) CreateWallet(wallet *models.Wallet) error {
	return r.db.Create(wallet).Error
}

// Lấy danh sách ví của 1 user cụ thể
func (r *WalletRepository) GetWalletsByUserID(userID uuid.UUID) ([]models.Wallet, error) {
	var wallets []models.Wallet
	// SELECT * FROM wallets WHERE user_id = ?
	err := r.db.Where("user_id = ?", userID).Find(&wallets).Error
	return wallets, err
}

// GetByUserID lấy danh sách ví theo user ID
func (r *WalletRepository) GetByUserID(userID uuid.UUID) ([]models.Wallet, error) {
	var wallets []models.Wallet
	err := r.db.Where("user_id = ?", userID).Find(&wallets).Error
	return wallets, err
}
