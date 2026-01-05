package services

import (
	"errors"

	"github.com/2impaoo-it/moneypod_app/server/internal/models"
	"github.com/2impaoo-it/moneypod_app/server/internal/repositories"
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

// TransferBetweenWallets chuyển tiền giữa các ví của cùng 1 user
func (s *WalletService) TransferBetweenWallets(userID uuid.UUID, fromWalletID, toWalletID uuid.UUID, amount float64, note string) error {
	// 1. Validate amount
	if amount <= 0 {
		return errors.New("số tiền phải lớn hơn 0")
	}

	// 2. Kiểm tra 2 ví không giống nhau
	if fromWalletID == toWalletID {
		return errors.New("không thể chuyển tiền cho chính ví đó")
	}

	// 3. Lấy thông tin 2 ví
	fromWallet, err := s.walletRepo.GetByID(fromWalletID)
	if err != nil {
		return errors.New("ví nguồn không tồn tại")
	}

	toWallet, err := s.walletRepo.GetByID(toWalletID)
	if err != nil {
		return errors.New("ví đích không tồn tại")
	}

	// 4. Kiểm tra cả 2 ví đều thuộc về user này
	if fromWallet.UserID != userID || toWallet.UserID != userID {
		return errors.New("bạn chỉ có thể chuyển tiền giữa các ví của mình")
	}

	// 5. Kiểm tra số dư ví nguồn
	if fromWallet.Balance < amount {
		return errors.New("số dư ví nguồn không đủ")
	}

	// 6. Thực hiện chuyển tiền
	fromWallet.Balance -= amount
	toWallet.Balance += amount

	// 7. Cập nhật database
	if err := s.walletRepo.UpdateWallet(fromWallet); err != nil {
		return err
	}

	if err := s.walletRepo.UpdateWallet(toWallet); err != nil {
		// Rollback ví nguồn nếu lỗi
		fromWallet.Balance += amount
		s.walletRepo.UpdateWallet(fromWallet)
		return err
	}

	return nil
}
