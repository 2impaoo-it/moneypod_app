package services

import (
	"fmt"
	"log"
	"time"

	"github.com/2impaoo-it/moneypod_app/backend/internal/models"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type NotificationScheduler struct {
	db           *gorm.DB
	notifService *NotificationService
}

func NewNotificationScheduler(db *gorm.DB, notifService *NotificationService) *NotificationScheduler {
	return &NotificationScheduler{
		db:           db,
		notifService: notifService,
	}
}

// StartDebtReminderScheduler: Chạy mỗi ngày để nhắc nhở nợ chưa trả
func (s *NotificationScheduler) StartDebtReminderScheduler() {
	// Chạy lần đầu sau 1 phút
	time.AfterFunc(1*time.Minute, func() {
		s.SendDebtReminders()
	})

	// Sau đó chạy mỗi 24 giờ
	ticker := time.NewTicker(24 * time.Hour)
	go func() {
		for range ticker.C {
			s.SendDebtReminders()
		}
	}()

	log.Println("✅ Debt Reminder Scheduler đã khởi động (chạy mỗi 24h)")
}

// SendDebtReminders: Gửi thông báo nhắc nhở cho những người còn nợ
func (s *NotificationScheduler) SendDebtReminders() {
	log.Println("🔔 Đang gửi nhắc nhở nợ...")

	// Lấy tất cả các khoản nợ chưa trả
	var debts []struct {
		DebtID     uuid.UUID
		FromUserID uuid.UUID
		ToUserID   uuid.UUID
		Amount     float64
		GroupName  string
		ExpenseDesc string
		FromUserFCM string
	}

	query := `
		SELECT 
			d.id as debt_id,
			d.from_user_id,
			d.to_user_id,
			d.amount,
			g.name as group_name,
			e.description as expense_desc,
			u.fcm_token as from_user_fcm
		FROM debts d
		JOIN expenses e ON d.expense_id = e.id
		JOIN groups g ON e.group_id = g.id
		JOIN users u ON d.from_user_id = u.id
		WHERE d.is_paid = false
		AND u.fcm_token != ''
	`

	if err := s.db.Raw(query).Scan(&debts).Error; err != nil {
		log.Printf("❌ Lỗi lấy danh sách nợ: %v\n", err)
		return
	}

	if len(debts) == 0 {
		log.Println("✅ Không có khoản nợ nào cần nhắc nhở")
		return
	}

	// Gửi thông báo cho từng người nợ
	count := 0
	for _, debt := range debts {
		title := "💰 Nhắc nhở: Bạn còn nợ chưa thanh toán"
		body := fmt.Sprintf("Bạn còn nợ %.0f đ trong nhóm '%s' ('%s'). Hãy thanh toán sớm nhé!", 
			debt.Amount, debt.GroupName, debt.ExpenseDesc)
		
		data := map[string]interface{}{
			"type":     "debt_reminder",
			"debt_id":  debt.DebtID.String(),
			"group_name": debt.GroupName,
		}

		if s.notifService != nil {
			s.notifService.CreateAndSendNotification(
				debt.FromUserID,
				"debt_reminder",
				title,
				body,
				data,
				debt.FromUserFCM,
			)
			count++
		}
	}

	log.Printf("✅ Đã gửi %d thông báo nhắc nhở nợ\n", count)
}

// StartSavingsReminderScheduler: Nhắc nhở tiết kiệm định kỳ
func (s *NotificationScheduler) StartSavingsReminderScheduler() {
	// Chạy lần đầu sau 2 phút
	time.AfterFunc(2*time.Minute, func() {
		s.SendSavingsReminders()
	})

	// Sau đó chạy mỗi tuần
	ticker := time.NewTicker(7 * 24 * time.Hour)
	go func() {
		for range ticker.C {
			s.SendSavingsReminders()
		}
	}()

	log.Println("✅ Savings Reminder Scheduler đã khởi động (chạy mỗi tuần)")
}

// SendSavingsReminders: Nhắc nhở nạp tiền tiết kiệm
func (s *NotificationScheduler) SendSavingsReminders() {
	log.Println("🔔 Đang gửi nhắc nhở tiết kiệm...")

	// Lấy các mục tiêu tiết kiệm đang chạy
	var goals []models.SavingsGoal

	if err := s.db.Preload("User").
		Where("status = ?", "IN_PROGRESS").
		Find(&goals).Error; err != nil {
		log.Printf("❌ Lỗi lấy danh sách tiết kiệm: %v\n", err)
		return
	}

	count := 0
	for _, goal := range goals {
		if goal.User.FCMToken == "" {
			continue
		}

		// Tính phần trăm đã đạt
		percentage := 0.0
		if goal.TargetAmount > 0 {
			percentage = (goal.CurrentAmount / goal.TargetAmount) * 100
		}

		title := "🐷 Nhắc nhở tiết kiệm"
		body := fmt.Sprintf("Mục tiêu '%s' đã đạt %.1f%%. Hãy tiếp tục nạp tiền nhé!", 
			goal.Name, percentage)

		data := map[string]interface{}{
			"type":    "savings_reminder",
			"goal_id": goal.ID.String(),
		}

		if s.notifService != nil {
			s.notifService.CreateAndSendNotification(
				goal.UserID,
				"savings_reminder",
				title,
				body,
				data,
				goal.User.FCMToken,
			)
			count++
		}
	}

	log.Printf("✅ Đã gửi %d thông báo nhắc nhở tiết kiệm\n", count)
}
