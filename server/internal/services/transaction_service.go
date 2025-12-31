package services

import (
	"errors"
	"fmt"
	"log"

	"github.com/2impaoo-it/moneypod_app/backend/internal/models"
	"github.com/2impaoo-it/moneypod_app/backend/internal/repositories"
	"github.com/2impaoo-it/moneypod_app/backend/pkg/constants"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type TransactionService struct {
	repo         *repositories.TransactionRepository
	walletRepo   *repositories.WalletRepository
	db           *gorm.DB
	notifService *NotificationService
}

func NewTransactionService(db *gorm.DB, r *repositories.TransactionRepository, w *repositories.WalletRepository, notifService *NotificationService) *TransactionService {
	return &TransactionService{
		db:           db,
		repo:         r,
		walletRepo:   w,
		notifService: notifService,
	}
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
	wallet, err := s.walletRepo.GetByIDAndUserID(tx, req.WalletID, userID)
	if err != nil {
		tx.Rollback()
		return errors.New("ví không tồn tại hoặc không chính chủ")
	}

	// 3. Tính toán số dư mới
	if req.Type == constants.TransactionTypeExpense {
		if wallet.Balance < req.Amount {
			tx.Rollback()
			return errors.New("số dư không đủ để chi tiêu")
		}
		wallet.Balance -= req.Amount
	} else if req.Type == constants.TransactionTypeIncome {
		wallet.Balance += req.Amount
	} else {
		tx.Rollback()
		return errors.New("loại giao dịch không hợp lệ (chỉ nhập income/expense)")
	}

	// 4. Cập nhật số dư ví
	if err := s.walletRepo.Update(tx, wallet); err != nil {
		tx.Rollback()
		return err
	}

	// 5. Lưu lịch sử giao dịch
	req.UserID = userID // Gán ID người dùng vào để bảo mật
	if err := s.repo.CreateWithTx(tx, &req); err != nil {
		tx.Rollback()
		return err
	}

	// 6. Mọi thứ ngon lành -> Commit (Lưu chính thức)
	if err := tx.Commit().Error; err != nil {
		return err
	}

	// 7. 🔥 Kiểm tra số dư thấp và gửi thông báo (ngưỡng: 100,000 đ)
	const lowBalanceThreshold = 100000.0
	log.Printf("🔍 DEBUG Low Balance: Type=%s, Balance=%.0f, Threshold=%.0f", req.Type, wallet.Balance, lowBalanceThreshold)

	if req.Type == constants.TransactionTypeExpense && wallet.Balance < lowBalanceThreshold {
		log.Printf("⚠️ LOW BALANCE DETECTED! Wallet '%s' balance: %.0f đ", wallet.Name, wallet.Balance)

		go func() {
			var user models.User
			if err := s.db.First(&user, "id = ?", userID).Error; err != nil {
				log.Printf("❌ Lỗi load user: %v", err)
				return
			}

			log.Printf("👤 User FCM Token: '%s' (length: %d)", user.FCMToken, len(user.FCMToken))
			log.Printf("🔔 NotifService nil? %v", s.notifService == nil)

			if user.FCMToken != "" && s.notifService != nil {
				title := "⚠️ Cảnh báo: Số dư ví thấp"
				body := fmt.Sprintf("Ví '%s' chỉ còn %.0f đ. Hãy nạp thêm tiền!", wallet.Name, wallet.Balance)
				data := map[string]interface{}{
					"type":      "low_balance",
					"wallet_id": wallet.ID.String(),
					"balance":   wallet.Balance,
				}
				log.Printf("📤 Đang gửi notification low_balance cho user %s", userID)
				if err := s.notifService.CreateAndSendNotification(userID, "low_balance", title, body, data, user.FCMToken); err != nil {
					log.Printf("❌ Lỗi gửi notification: %v", err)
				} else {
					log.Printf("✅ Đã gửi notification low_balance thành công!")
				}
			} else {
				log.Printf("⚠️ Không gửi notification: FCMToken='%s', NotifService=%v", user.FCMToken, s.notifService != nil)
			}
		}()
	} else {
		log.Printf("ℹ️ Không trigger low balance: Type=%s, Balance=%.0f >= %.0f", req.Type, wallet.Balance, lowBalanceThreshold)
	}

	return nil
}

func (s *TransactionService) GetMyTransactions(userID uuid.UUID) ([]models.Transaction, error) {
	// Sử dụng phân trang mặc định để tránh lấy quá nhiều dữ liệu
	// Lấy 100 giao dịch gần nhất, sắp xếp mới nhất lên đầu
	const defaultPageSize = 100
	transactions, _, err := s.repo.GetByUserIDWithFilters(userID, "", "", "", 0, 0, 0, defaultPageSize)
	return transactions, err
}

// UpdateTransaction sửa giao dịch (phải tính toán lại số dư)
func (s *TransactionService) UpdateTransaction(transactionID, userID uuid.UUID, amount float64, category, transactionType, note string) error {
	// Bắt đầu transaction
	tx := s.db.Begin()
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	// Lấy giao dịch cũ
	oldTransaction, err := s.repo.GetByIDAndUserID(transactionID, userID)
	if err != nil {
		tx.Rollback()
		return errors.New("giao dịch không tồn tại hoặc không thuộc về bạn")
	}

	// Lấy ví
	wallet, err := s.walletRepo.GetByIDAndUserID(tx, oldTransaction.WalletID, userID)
	if err != nil {
		tx.Rollback()
		return errors.New("ví không tồn tại")
	}

	// Hoàn lại số dư cũ trước
	if oldTransaction.Type == constants.TransactionTypeExpense {
		wallet.Balance += oldTransaction.Amount
	} else {
		wallet.Balance -= oldTransaction.Amount
	}

	// Áp dụng số dư mới
	if amount > 0 {
		oldTransaction.Amount = amount
	}
	if category != "" {
		oldTransaction.Category = category
	}
	if transactionType != "" {
		oldTransaction.Type = transactionType
	}
	if note != "" {
		oldTransaction.Note = note
	}

	// Tính toán lại số dư
	if oldTransaction.Type == constants.TransactionTypeExpense {
		if wallet.Balance < oldTransaction.Amount {
			tx.Rollback()
			return errors.New("số dư không đủ")
		}
		wallet.Balance -= oldTransaction.Amount
	} else {
		wallet.Balance += oldTransaction.Amount
	}

	// Cập nhật ví
	if err := s.walletRepo.Update(tx, wallet); err != nil {
		tx.Rollback()
		return err
	}

	// Cập nhật giao dịch
	if err := s.repo.Update(tx, oldTransaction); err != nil {
		tx.Rollback()
		return err
	}

	return tx.Commit().Error
}

// DeleteTransaction xóa giao dịch (phải hoàn lại tiền)
func (s *TransactionService) DeleteTransaction(transactionID, userID uuid.UUID) error {
	// Bắt đầu transaction
	tx := s.db.Begin()
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	// Lấy giao dịch
	transaction, err := s.repo.GetByIDAndUserID(transactionID, userID)
	if err != nil {
		tx.Rollback()
		return errors.New("giao dịch không tồn tại hoặc không thuộc về bạn")
	}

	// Lấy ví
	wallet, err := s.walletRepo.GetByIDAndUserID(tx, transaction.WalletID, userID)
	if err != nil {
		tx.Rollback()
		return errors.New("ví không tồn tại")
	}

	// Hoàn lại số dư
	if transaction.Type == constants.TransactionTypeExpense {
		wallet.Balance += transaction.Amount
	} else {
		wallet.Balance -= transaction.Amount
	}

	// Cập nhật ví
	if err := s.walletRepo.Update(tx, wallet); err != nil {
		tx.Rollback()
		return err
	}

	// Xóa giao dịch
	if err := s.repo.Delete(tx, transactionID); err != nil {
		tx.Rollback()
		return err
	}

	return tx.Commit().Error
}

// GetTransactionsWithFilters lấy giao dịch với filter và pagination
func (s *TransactionService) GetTransactionsWithFilters(userID uuid.UUID, walletID, category, transactionType string, month, year, page, pageSize int) ([]models.Transaction, int64, error) {
	offset := (page - 1) * pageSize
	return s.repo.GetByUserIDWithFilters(userID, walletID, category, transactionType, month, year, offset, pageSize)
}
