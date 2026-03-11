package services

import (
	"errors"

	"github.com/2impaoo-it/moneypod_app/server/internal/models"
	"github.com/2impaoo-it/moneypod_app/server/internal/repositories"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type WalletService struct {
	db         *gorm.DB
	walletRepo *repositories.WalletRepository
}

func NewWalletService(db *gorm.DB, walletRepo *repositories.WalletRepository) *WalletService {
	return &WalletService{db: db, walletRepo: walletRepo}
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
	// Sử dụng transaction để đảm bảo an toàn
	tx := s.db.Begin()
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	// Lấy ví và khóa nó lại để tránh race condition, đồng thời xác thực quyền sở hữu
	wallet, err := s.walletRepo.GetByIDAndUserID(tx, walletID, userID)
	if err != nil {
		tx.Rollback()
		return errors.New("ví không tồn tại hoặc bạn không có quyền truy cập")
	}

	// Cập nhật thông tin
	if name != "" {
		wallet.Name = name
	}
	if currency != "" {
		wallet.Currency = currency
	}

	// Gọi repo update an toàn
	if err := s.walletRepo.Update(tx, wallet); err != nil {
		tx.Rollback()
		return err
	}

	return tx.Commit().Error
}

// DeleteWallet xóa ví (chỉ khi số dư = 0)
func (s *WalletService) DeleteWallet(walletID, userID uuid.UUID) error {
	// Lấy ví để kiểm tra số dư và lịch sử giao dịch
	// Không cần khóa transaction ở đây vì chỉ đọc dữ liệu
	wallet, err := s.walletRepo.GetByID(walletID)
	if err != nil {
		return errors.New("ví không tồn tại")
	}
	// Vẫn phải kiểm tra quyền sở hữu ở lớp service
	if wallet.UserID != userID {
		return errors.New("bạn không có quyền xóa ví này")
	}

	// Kiểm tra các điều kiện nghiệp vụ
	if wallet.Balance != 0 {
		return errors.New("chỉ có thể xóa ví khi số dư bằng 0")
	}
	count, err := s.walletRepo.CountTransactionsByWalletID(walletID)
	if err != nil {
		return err
	}
	if count > 0 {
		return errors.New("không thể xóa ví đã có lịch sử giao dịch")
	}

	// Gọi hàm xóa an toàn của repo, nó sẽ kiểm tra lại quyền sở hữu một cách nguyên tử
	return s.walletRepo.DeleteWallet(walletID, userID)
}

// TransferBetweenWallets chuyển tiền giữa các ví của cùng 1 user
func (s *WalletService) TransferBetweenWallets(userID uuid.UUID, fromWalletID, toWalletID uuid.UUID, amount float64, note string) error {
	if amount <= 0 {
		return errors.New("số tiền phải lớn hơn 0")
	}
	if fromWalletID == toWalletID {
		return errors.New("không thể chuyển tiền cho chính ví đó")
	}

	// Bắt đầu transaction
	tx := s.db.Begin()
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	// Lấy ví nguồn và đích, đồng thời xác thực quyền sở hữu
	fromWallet, err := s.walletRepo.GetByIDAndUserID(tx, fromWalletID, userID)
	if err != nil {
		tx.Rollback()
		return errors.New("ví nguồn không tồn tại hoặc không thuộc quyền sở hữu của bạn")
	}
	toWallet, err := s.walletRepo.GetByIDAndUserID(tx, toWalletID, userID)
	if err != nil {
		tx.Rollback()
		return errors.New("ví đích không tồn tại hoặc không thuộc quyền sở hữu của bạn")
	}

	// Kiểm tra số dư ví nguồn
	if fromWallet.Balance < amount {
		tx.Rollback()
		return errors.New("số dư ví nguồn không đủ")
	}

	// Thực hiện chuyển tiền
	fromWallet.Balance -= amount
	toWallet.Balance += amount

	// Cập nhật database
	if err := s.walletRepo.Update(tx, fromWallet); err != nil {
		tx.Rollback()
		return err
	}
	if err := s.walletRepo.Update(tx, toWallet); err != nil {
		tx.Rollback()
		return err
	}

	// Commit transaction
	return tx.Commit().Error
}
