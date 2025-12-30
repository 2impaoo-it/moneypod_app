package services

import (
	"errors"

	"github.com/2impaoo-it/moneypod_app/backend/internal/models"
	"github.com/2impaoo-it/moneypod_app/backend/internal/repositories"
	"github.com/google/uuid"
)

type WalletService struct {
	walletRepo *repositories.WalletRepository
}

func NewWalletService(walletRepo *repositories.WalletRepository) *WalletService {
	return &WalletService{walletRepo: walletRepo}
}

func (s *WalletService) CreateWallet(userID uuid.UUID, name string, initialBalance float64) error {
	newWallet := &models.Wallet{
		UserID:  userID,
		Name:    name,
		Balance: initialBalance,
	}
	return s.walletRepo.CreateWallet(newWallet)
}

func (s *WalletService) GetMyWallets(userID uuid.UUID) ([]models.Wallet, error) {
	return s.walletRepo.GetWalletsByUserID(userID)
}

// UpdateWallet cập nhật tên ví, loại tiền tệ
func (s *WalletService) UpdateWallet(walletID, userID uuid.UUID, name, currency string) error {
	// Kiểm tra ví có thuộc về user này không
	wallet, err := s.walletRepo.GetByID(walletID)
	if err != nil {
		return err
	}

	if wallet.UserID != userID {
		return errors.New("bạn không có quyền chỉnh sửa ví này")
	}

	// Cập nhật thông tin
	if name != "" {
		wallet.Name = name
	}
	if currency != "" {
		wallet.Currency = currency
	}

	return s.walletRepo.UpdateWallet(wallet)
}

// DeleteWallet xóa ví (chỉ khi số dư = 0)
func (s *WalletService) DeleteWallet(walletID, userID uuid.UUID) error {
	// Kiểm tra ví có thuộc về user này không
	wallet, err := s.walletRepo.GetByID(walletID)
	if err != nil {
		return err
	}

	if wallet.UserID != userID {
		return errors.New("bạn không có quyền xóa ví này")
	}

	// Kiểm tra số dư
	if wallet.Balance != 0 {
		return errors.New("chỉ có thể xóa ví khi số dư bằng 0")
	}

	// Kiểm tra xem có giao dịch nào không
	count, err := s.walletRepo.CountTransactionsByWalletID(walletID)
	if err != nil {
		return err
	}

	if count > 0 {
		return errors.New("không thể xóa ví đã có lịch sử giao dịch")
	}

	return s.walletRepo.DeleteWallet(walletID)
}
