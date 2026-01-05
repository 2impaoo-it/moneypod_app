package services

import (
	"fmt"
	"log"
	"strings"
	"time"

	"github.com/2impaoo-it/moneypod_app/server/internal/models"
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
// ✅ OPTIMIZED: Group by user, batch check duplicates, rate limiting
func (s *NotificationScheduler) SendDebtReminders() {
	log.Println("🔔 Đang gửi nhắc nhở nợ...")

	// Step 1: Group debts by user với aggregation
	var results []struct {
		FromUserID  uuid.UUID
		DebtCount   int
		TotalAmount float64
		FCMToken    string
		GroupNames  string // PostgreSQL JSON_AGG returns string
	}

	query := `
		SELECT 
			d.from_user_id,
			COUNT(DISTINCT d.id) as debt_count,
			SUM(d.amount) as total_amount,
			u.fcm_token,
			STRING_AGG(DISTINCT g.name, ', ') as group_names
		FROM debts d
		JOIN expenses e ON d.expense_id = e.id
		JOIN groups g ON e.group_id = g.id
		JOIN users u ON d.from_user_id = u.id
		WHERE d.is_paid = false 
		AND u.fcm_token != ''
		AND u.fcm_token_valid = true
		GROUP BY d.from_user_id, u.fcm_token
	`

	if err := s.db.Raw(query).Scan(&results).Error; err != nil {
		log.Printf("❌ Lỗi lấy danh sách nợ: %v\n", err)
		return
	}

	if len(results) == 0 {
		log.Println("✅ Không có khoản nợ nào cần nhắc nhở")
		return
	}

	log.Printf("📊 Tìm thấy %d users có nợ chưa trả", len(results))

	// Step 2: Batch check duplicates (đã gửi trong 24h chưa)
	userIDs := make([]uuid.UUID, len(results))
	for i, r := range results {
		userIDs[i] = r.FromUserID
	}

	var alreadySentUsers []uuid.UUID
	s.db.Model(&models.Notification{}).
		Select("DISTINCT user_id").
		Where("user_id IN ? AND type = ? AND created_at > ?",
			userIDs,
			"debt_reminder",
			time.Now().Add(-24*time.Hour),
		).
		Pluck("user_id", &alreadySentUsers)

	// Convert to map for fast lookup
	alreadySentMap := make(map[uuid.UUID]bool)
	for _, uid := range alreadySentUsers {
		alreadySentMap[uid] = true
	}

	log.Printf("⏭️  Bỏ qua %d users đã nhận thông báo trong 24h", len(alreadySentMap))

	// Step 3: Send with rate limiting (10 requests/second max)
	count := 0
	skipped := 0
	rateLimiter := time.NewTicker(100 * time.Millisecond)
	defer rateLimiter.Stop()

	for _, result := range results {
		// Skip if already sent in last 24h
		if alreadySentMap[result.FromUserID] {
			skipped++
			continue
		}

		<-rateLimiter.C // Rate limit: max 10 req/s

		// Build smart notification message
		title := "💰 Nhắc nhở thanh toán"
		body := ""

		if result.DebtCount == 1 {
			body = fmt.Sprintf("Bạn có 1 khoản nợ %.0f đ chưa thanh toán trong nhóm '%s'",
				result.TotalAmount, result.GroupNames)
		} else {
			// Count groups
			groupCount := len(strings.Split(result.GroupNames, ", "))
			if groupCount == 1 {
				body = fmt.Sprintf("Bạn có %d khoản nợ (tổng %.0f đ) chưa thanh toán trong nhóm '%s'",
					result.DebtCount, result.TotalAmount, result.GroupNames)
			} else {
				body = fmt.Sprintf("Bạn có %d khoản nợ (tổng %.0f đ) trong %d nhóm. Hãy thanh toán sớm nhé!",
					result.DebtCount, result.TotalAmount, groupCount)
			}
		}

		data := map[string]interface{}{
			"type":         "debt_reminder",
			"debt_count":   result.DebtCount,
			"total_amount": result.TotalAmount,
			"group_names":  result.GroupNames,
		}

		if s.notifService != nil {
			if err := s.notifService.CreateAndSendNotification(
				result.FromUserID,
				"debt_reminder",
				title,
				body,
				data,
				result.FCMToken,
			); err != nil {
				log.Printf("⚠️ Lỗi gửi notification cho user %s: %v", result.FromUserID, err)
			} else {
				count++
			}
		}
	}

	log.Printf("✅ Đã gửi %d thông báo nhắc nhở nợ (bỏ qua %d, tổng %d users)\n", count, skipped, len(results))
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

	// Lấy các mục tiêu tiết kiệm đang chạy cùng với thông tin user
	var results []struct {
		GoalID        uuid.UUID
		UserID        uuid.UUID
		GoalName      string
		TargetAmount  float64
		CurrentAmount float64
		FCMToken      string
	}

	query := `
		SELECT 
			sg.id as goal_id,
			sg.user_id,
			sg.name as goal_name,
			sg.target_amount,
			sg.current_amount,
			u.fcm_token
		FROM savings_goals sg
		JOIN users u ON sg.user_id = u.id
		WHERE sg.status = 'IN_PROGRESS'
		AND u.fcm_token != ''
		AND u.fcm_token_valid = true
		AND sg.deleted_at IS NULL
	`

	if err := s.db.Raw(query).Scan(&results).Error; err != nil {
		log.Printf("❌ Lỗi lấy danh sách tiết kiệm: %v\n", err)
		return
	}

	count := 0
	for _, result := range results {
		// Tính phần trăm đã đạt
		percentage := 0.0
		if result.TargetAmount > 0 {
			percentage = (result.CurrentAmount / result.TargetAmount) * 100
		}

		title := "🐷 Nhắc nhở tiết kiệm"
		body := fmt.Sprintf("Mục tiêu '%s' đã đạt %.1f%%. Hãy tiếp tục nạp tiền nhé!",
			result.GoalName, percentage)

		data := map[string]interface{}{
			"type":    "savings_reminder",
			"goal_id": result.GoalID.String(),
		}

		if s.notifService != nil {
			s.notifService.CreateAndSendNotification(
				result.UserID,
				"savings_reminder",
				title,
				body,
				data,
				result.FCMToken,
			)
			count++
		}
	}

	log.Printf("✅ Đã gửi %d thông báo nhắc nhở tiết kiệm\n", count)
}
