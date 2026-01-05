package services

import (
	"errors"
	"fmt"
	"time"

	"github.com/2impaoo-it/moneypod_app/server/internal/models"
	"github.com/2impaoo-it/moneypod_app/server/internal/repositories"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type SavingsService struct {
	db           *gorm.DB
	savingsRepo  *repositories.SavingsRepository
	walletRepo   *repositories.WalletRepository
	notifService *NotificationService
}

func NewSavingsService(db *gorm.DB, sRepo *repositories.SavingsRepository, wRepo *repositories.WalletRepository, notifService *NotificationService) *SavingsService {
	return &SavingsService{
		db:           db,
		savingsRepo:  sRepo,
		walletRepo:   wRepo,
		notifService: notifService,
	}
}

// 1. Tạo mục tiêu mới
func (s *SavingsService) CreateGoal(userID uuid.UUID, req models.SavingsGoal) error {
	req.UserID = userID
	req.CurrentAmount = 0
	req.Status = "IN_PROGRESS"
	return s.savingsRepo.CreateGoal(&req)
}

// 2. Lấy danh sách (KÈM LOGIC TÍNH OVERDUE)
func (s *SavingsService) GetMyGoals(userID uuid.UUID) ([]models.SavingsGoal, error) {
	goals, err := s.savingsRepo.GetGoalsByUserID(userID)
	if err != nil {
		return nil, err
	}

	// 🔥 Logic tính toán: Đã quá hạn chưa?
	now := time.Now()
	for i := range goals {
		// Nếu đang chạy + Có deadline + Deadline nhỏ hơn hiện tại => Quá hạn
		if goals[i].Status == "IN_PROGRESS" &&
			goals[i].Deadline != nil &&
			goals[i].Deadline.Before(now) {
			goals[i].IsOverdue = true
		} else {
			goals[i].IsOverdue = false
		}
	}

	return goals, nil
}

// 3. NẠP TIỀN (DEPOSIT) - KÈM LOGIC HOÀN THÀNH
func (s *SavingsService) Deposit(userID uuid.UUID, goalID uuid.UUID, walletID uuid.UUID, amount float64) error {
	tx := s.db.Begin()
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	// A. Kiểm tra Ví thật
	wallet, err := s.walletRepo.GetByIDAndUserID(tx, walletID, userID)
	if err != nil {
		tx.Rollback()
		return errors.New("ví không tồn tại")
	}
	if wallet.Balance < amount {
		tx.Rollback()
		return errors.New("số dư ví không đủ để tiết kiệm")
	}

	// B. Lấy thông tin Quỹ
	goal, err := s.savingsRepo.GetGoalByID(tx, goalID)
	if err != nil {
		tx.Rollback()
		return errors.New("quỹ tiết kiệm không tồn tại")
	}

	// C. THỰC HIỆN CHUYỂN TIỀN
	// 1. Trừ tiền ví thật
	wallet.Balance -= amount
	if err := s.walletRepo.Update(tx, wallet); err != nil {
		tx.Rollback()
		return err
	}

	// 2. Cộng tiền vào quỹ
	goal.CurrentAmount += amount

	// 🔥 Logic Kiểm tra Hoàn thành (Về đích sớm)
	isCompleted := false
	// Nếu có đặt mục tiêu (Target > 0) và Hiện tại >= Mục tiêu
	if goal.TargetAmount > 0 && goal.CurrentAmount >= goal.TargetAmount {
		goal.Status = "COMPLETED"
		isCompleted = true
	}

	if err := s.savingsRepo.UpdateGoal(tx, goal); err != nil {
		tx.Rollback()
		return err
	}

	// 3. Lưu lịch sử Savings Transaction
	savTrans := models.SavingsTransaction{
		GoalID:   goalID,
		WalletID: walletID,
		Amount:   amount,
		Type:     "DEPOSIT",
		Note:     "Nạp tiền tiết kiệm",
	}
	if err := s.savingsRepo.CreateSavingsTrans(tx, &savTrans); err != nil {
		tx.Rollback()
		return err
	}

	// Commit Transaction
	if err := tx.Commit().Error; err != nil {
		return err
	}

	// 🔥 Gửi thông báo khi đạt mục tiêu
	if isCompleted {
		go func() {
			var user models.User
			s.db.First(&user, "id = ?", userID)

			if user.FCMToken != "" && s.notifService != nil {
				title := "🎉 Chúc mừng! Mục tiêu đã hoàn thành"
				body := fmt.Sprintf("Bạn đã đạt mục tiêu '%s' với %.0f đ!", goal.Name, goal.CurrentAmount)
				data := map[string]interface{}{
					"type":    "savings_goal_reached",
					"goal_id": goalID.String(),
				}
				s.notifService.CreateAndSendNotification(userID, "savings_goal_reached", title, body, data, user.FCMToken)
			}
		}()
		return errors.New("GOAL_COMPLETED")
	}

	// 🔥 Gửi thông báo về tiến độ (50%, 75%, 90%)
	if goal.TargetAmount > 0 {
		percentage := (goal.CurrentAmount / goal.TargetAmount) * 100

		// Check milestones
		if (percentage >= 50 && percentage < 55) ||
			(percentage >= 75 && percentage < 80) ||
			(percentage >= 90 && percentage < 95) {
			go func() {
				var user models.User
				s.db.First(&user, "id = ?", userID)

				if user.FCMToken != "" && s.notifService != nil {
					title := fmt.Sprintf("💪 Đã đạt %.0f%% mục tiêu!", percentage)
					body := fmt.Sprintf("'%s': %.0f/%.0f đ. Cố lên!", goal.Name, goal.CurrentAmount, goal.TargetAmount)
					data := map[string]interface{}{
						"type":       "savings_progress",
						"goal_id":    goalID.String(),
						"percentage": percentage,
					}
					s.notifService.CreateAndSendNotification(userID, "savings_progress", title, body, data, user.FCMToken)
				}
			}()
		}
	}

	return nil
}

// 4. RÚT TIỀN (WITHDRAW) - Giữ nguyên logic cũ
func (s *SavingsService) Withdraw(userID uuid.UUID, goalID uuid.UUID, walletID uuid.UUID, amount float64) error {
	tx := s.db.Begin()
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	goal, err := s.savingsRepo.GetGoalByID(tx, goalID)
	if err != nil {
		tx.Rollback()
		return errors.New("quỹ không tồn tại")
	}
	if goal.CurrentAmount < amount {
		tx.Rollback()
		return errors.New("số dư trong quỹ không đủ để rút")
	}

	wallet, err := s.walletRepo.GetByIDAndUserID(tx, walletID, userID)
	if err != nil {
		tx.Rollback()
		return errors.New("ví nhận tiền không tồn tại")
	}

	goal.CurrentAmount -= amount
	if err := s.savingsRepo.UpdateGoal(tx, goal); err != nil {
		tx.Rollback()
		return err
	}

	wallet.Balance += amount
	if err := s.walletRepo.Update(tx, wallet); err != nil {
		tx.Rollback()
		return err
	}

	savTrans := models.SavingsTransaction{
		GoalID:   goalID,
		WalletID: walletID,
		Amount:   amount,
		Type:     "WITHDRAW",
		Note:     "Rút tiền tiết kiệm",
	}
	if err := s.savingsRepo.CreateSavingsTrans(tx, &savTrans); err != nil {
		tx.Rollback()
		return err
	}

	return tx.Commit().Error
}

// UpdateGoal: Sửa mục tiêu (tên, màu, target, deadline)
func (s *SavingsService) UpdateGoal(userID uuid.UUID, goalID uuid.UUID, name, color, icon string, targetAmount float64, deadline *time.Time) error {
	tx := s.db.Begin()
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	goal, err := s.savingsRepo.GetGoalByID(tx, goalID)
	if err != nil {
		tx.Rollback()
		return errors.New("quỹ không tồn tại")
	}

	// Kiểm tra quyền sở hữu
	if goal.UserID != userID {
		tx.Rollback()
		return errors.New("bạn không có quyền chỉnh sửa mục tiêu này")
	}

	// Cập nhật các trường
	if name != "" {
		goal.Name = name
	}
	if color != "" {
		goal.Color = color
	}
	if icon != "" {
		goal.Icon = icon
	}
	if targetAmount > 0 {
		goal.TargetAmount = targetAmount
	}
	if deadline != nil {
		goal.Deadline = deadline
	}

	if err := s.savingsRepo.UpdateGoal(tx, goal); err != nil {
		tx.Rollback()
		return err
	}

	return tx.Commit().Error
}

// DeleteGoal: Xóa mục tiêu (phải rút hết tiền trước)
func (s *SavingsService) DeleteGoal(userID uuid.UUID, goalID uuid.UUID) error {
	tx := s.db.Begin()
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	goal, err := s.savingsRepo.GetGoalByID(tx, goalID)
	if err != nil {
		tx.Rollback()
		return errors.New("quỹ không tồn tại")
	}

	// Kiểm tra quyền sở hữu
	if goal.UserID != userID {
		tx.Rollback()
		return errors.New("bạn không có quyền xóa mục tiêu này")
	}

	// Kiểm tra còn tiền không
	if goal.CurrentAmount > 0 {
		tx.Rollback()
		return errors.New("vui lòng rút hết tiền trước khi xóa mục tiêu")
	}

	// Xóa lịch sử giao dịch liên quan
	if err := s.savingsRepo.DeleteTransactionsByGoalID(tx, goalID); err != nil {
		tx.Rollback()
		return err
	}

	// Xóa mục tiêu
	if err := s.savingsRepo.DeleteGoal(tx, goalID); err != nil {
		tx.Rollback()
		return err
	}

	return tx.Commit().Error
}

// GetGoalTransactions: Xem lịch sử nạp/rút của một mục tiêu
func (s *SavingsService) GetGoalTransactions(userID uuid.UUID, goalID uuid.UUID) ([]models.SavingsTransaction, error) {
	// Kiểm tra quyền sở hữu
	goal, err := s.savingsRepo.GetGoalByID(s.db, goalID)
	if err != nil {
		return nil, errors.New("quỹ không tồn tại")
	}

	if goal.UserID != userID {
		return nil, errors.New("bạn không có quyền xem lịch sử mục tiêu này")
	}

	return s.savingsRepo.GetTransactionsByGoalID(goalID)
}
