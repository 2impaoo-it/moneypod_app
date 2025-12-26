package services

import (
	"errors"
	"time"

	"github.com/2impaoo-it/moneypod_app/backend/internal/models"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type TransactionService struct {
	db *gorm.DB
}

func NewTransactionService(db *gorm.DB) *TransactionService {
	return &TransactionService{db: db}
}

func (s *TransactionService) CreateTransaction(userID uuid.UUID, req models.Transaction) error {
	// 1. Bắt đầu Transaction (Mở lệnh khóa dòng tiền)
	tx := s.db.Begin()

	// Nếu có bất kỳ lỗi nào xảy ra trong quá trình, tự động Rollback (Hoàn tác)
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	// 2. Kiểm tra ví có tồn tại và thuộc về user này không
	var wallet models.Wallet
	if err := tx.Where("id = ? AND user_id = ?", req.WalletID, userID).First(&wallet).Error; err != nil {
		tx.Rollback()
		return errors.New("ví không tồn tại hoặc không chính chủ")
	}

	// 3. Tính toán số dư mới
	if req.Type == "expense" {
		if wallet.Balance < req.Amount {
			tx.Rollback()
			return errors.New("số dư không đủ để chi tiêu")
		}
		wallet.Balance -= req.Amount
	} else if req.Type == "income" {
		wallet.Balance += req.Amount
	} else {
		tx.Rollback()
		return errors.New("loại giao dịch không hợp lệ (chỉ nhập income/expense)")
	}

	// 4. Cập nhật số dư ví
	if err := tx.Save(&wallet).Error; err != nil {
		tx.Rollback()
		return err
	}

	// 5. Lưu lịch sử giao dịch
	req.UserID = userID // Gán ID người dùng vào để bảo mật
	if err := tx.Create(&req).Error; err != nil {
		tx.Rollback()
		return err
	}

	// 6. Mọi thứ ngon lành -> Commit (Lưu chính thức)
	return tx.Commit().Error
}

// TransferMoney: Chuyển tiền từ ví A sang ví B
func (s *TransactionService) TransferMoney(userID uuid.UUID, fromWalletID uuid.UUID, toWalletID uuid.UUID, amount float64, note string) error {
	tx := s.db.Begin()

	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	// 1. Kiểm tra ví nguồn (FromWallet) có phải của user này không?
	var fromWallet models.Wallet
	if err := tx.Where("id = ? AND user_id = ?", fromWalletID, userID).First(&fromWallet).Error; err != nil {
		tx.Rollback()
		return errors.New("ví nguồn không tồn tại hoặc không chính chủ")
	}

	// 2. Kiểm tra ví đích (ToWallet) - Có thể là của mình hoặc người khác
	var toWallet models.Wallet
	if err := tx.Where("id = ?", toWalletID).First(&toWallet).Error; err != nil {
		tx.Rollback()
		return errors.New("ví nhận tiền không tồn tại")
	}

	// 3. Kiểm tra số dư
	if fromWallet.Balance < amount {
		tx.Rollback()
		return errors.New("số dư không đủ để chuyển")
	}

	// 4. TRỪ tiền ví nguồn
	if err := tx.Model(&fromWallet).Update("balance", fromWallet.Balance-amount).Error; err != nil {
		tx.Rollback()
		return err
	}

	// 5. CỘNG tiền ví đích
	if err := tx.Model(&toWallet).Update("balance", toWallet.Balance+amount).Error; err != nil {
		tx.Rollback()
		return err
	}

	// 6. Lưu lịch sử giao dịch (Tạo 2 bản ghi: 1 chi, 1 thu để cả 2 bên đều thấy lịch sử)
	// Bản ghi cho người chuyển (Expense)
	tx.Create(&models.Transaction{
		UserID: userID, WalletID: fromWalletID, Amount: amount, Type: "expense", Note: "Chuyển tiền đến ví " + toWallet.Name + ": " + note, Date: time.Now(),
	})

	// Bản ghi cho người nhận (Income)
	tx.Create(&models.Transaction{
		UserID: toWallet.UserID, WalletID: toWalletID, Amount: amount, Type: "income", Note: "Nhận tiền từ ví " + fromWallet.Name + ": " + note, Date: time.Now(),
	})

	return tx.Commit().Error
}

func (s *TransactionService) GetMyTransactions(userID uuid.UUID) ([]models.Transaction, error) {
	var transactions []models.Transaction

	// Lấy tất cả giao dịch của user này, sắp xếp mới nhất lên đầu
	result := s.db.Where("user_id = ?", userID).Order("date desc").Find(&transactions)

	if result.Error != nil {
		return nil, result.Error
	}
	return transactions, nil
}
