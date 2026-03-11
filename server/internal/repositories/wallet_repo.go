package repositories

import (
	"github.com/2impaoo-it/moneypod_app/server/internal/models"
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

// GetByIDAndUserID lấy ví theo ID và UserID với transaction context
func (r *WalletRepository) GetByIDAndUserID(tx *gorm.DB, walletID, userID uuid.UUID) (*models.Wallet, error) {
	var wallet models.Wallet
	err := tx.Where("id = ? AND user_id = ?", walletID, userID).First(&wallet).Error
	return &wallet, err
}

// Update cập nhật thông tin ví với transaction context
func (r *WalletRepository) Update(tx *gorm.DB, wallet *models.Wallet) error {
	return tx.Save(wallet).Error
}

// GetByID lấy ví theo ID (dùng cho update/delete)
func (r *WalletRepository) GetByID(walletID uuid.UUID) (*models.Wallet, error) {
	var wallet models.Wallet
	err := r.db.Where("id = ?", walletID).First(&wallet).Error
	return &wallet, err
}

// UpdateWallet cập nhật thông tin ví (không dùng transaction)
func (r *WalletRepository) UpdateWallet(wallet *models.Wallet, userID uuid.UUID) error {
	result := r.db.Model(&models.Wallet{}).
		Where("id = ? AND user_id = ?", wallet.ID, userID).
		Updates(wallet)

	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return gorm.ErrRecordNotFound // Không tìm thấy hoặc không có quyền
	}
	return nil
}

// DeleteWallet xóa ví
func (r *WalletRepository) DeleteWallet(walletID, userID uuid.UUID) error {
	result := r.db.Where("id = ? AND user_id = ?", walletID, userID).Delete(&models.Wallet{})
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return gorm.ErrRecordNotFound
	}
	return nil
}

// CountTransactionsByWalletID đếm số giao dịch của ví
func (r *WalletRepository) CountTransactionsByWalletID(walletID uuid.UUID) (int64, error) {
	var count int64
	err := r.db.Model(&models.Transaction{}).Where("wallet_id = ?", walletID).Count(&count).Error
	return count, err
}
