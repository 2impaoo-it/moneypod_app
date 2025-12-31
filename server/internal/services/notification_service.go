package services

import (
	"context"
	"encoding/json"
	"fmt"
	"log"

	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/messaging"
	"github.com/2impaoo-it/moneypod_app/backend/internal/models"
	"github.com/2impaoo-it/moneypod_app/backend/internal/repositories"
	"github.com/google/uuid"
	"google.golang.org/api/option"
)

type NotificationService struct {
	client    *messaging.Client
	notifRepo *repositories.NotificationRepository
}

// Khởi tạo Service: Kết nối tới Firebase
func NewNotificationService(credPath string, notifRepo *repositories.NotificationRepository) (*NotificationService, error) {
	ctx := context.Background()

	// Cấu hình credential từ file json
	opt := option.WithCredentialsFile(credPath)

	// Khởi tạo App
	app, err := firebase.NewApp(ctx, nil, opt)
	if err != nil {
		return nil, fmt.Errorf("lỗi khởi tạo Firebase App: %v", err)
	}

	// Lấy Messaging Client
	client, err := app.Messaging(ctx)
	if err != nil {
		return nil, fmt.Errorf("lỗi lấy Messaging Client: %v", err)
	}

	return &NotificationService{
		client:    client,
		notifRepo: notifRepo,
	}, nil
}

// Hàm gửi thông báo cho nhiều người (Multicast)
func (s *NotificationService) SendMulticastNotification(tokens []string, title, body string) {
	// Nếu không có token nào hoặc service chưa khởi tạo được thì bỏ qua
	if s == nil || s.client == nil || len(tokens) == 0 {
		return
	}

	// Tạo gói tin
	message := &messaging.MulticastMessage{
		Notification: &messaging.Notification{
			Title: title,
			Body:  body,
		},
		Tokens: tokens,
	}

	// Gửi đi
	br, err := s.client.SendMulticast(context.Background(), message)
	if err != nil {
		log.Println("❌ Lỗi gửi thông báo FCM:", err)
		return
	}

	log.Printf("✅ FCM: Gửi thành công %d, Thất bại %d\n", br.SuccessCount, br.FailureCount)
}

// Hàm gửi thông báo cho 1 người
func (s *NotificationService) SendNotification(token, title, body string) {
	// Nếu không có token hoặc service chưa khởi tạo được thì bỏ qua
	if s == nil || s.client == nil || token == "" {
		return
	}

	// Tạo gói tin
	message := &messaging.Message{
		Notification: &messaging.Notification{
			Title: title,
			Body:  body,
		},
		Token: token,
	}

	// Gửi đi
	_, err := s.client.Send(context.Background(), message)
	if err != nil {
		log.Println("❌ Lỗi gửi thông báo FCM:", err)
		return
	}

	log.Println("✅ FCM: Gửi thông báo thành công")
}

// === NEW METHODS: LƯU VÀO DATABASE ===

// CreateAndSendNotification: Tạo thông báo trong DB và gửi FCM nếu user bật setting
func (s *NotificationService) CreateAndSendNotification(userID uuid.UUID, notifType, title, body string, data map[string]interface{}, fcmToken string) error {
	// 1. Kiểm tra settings của user
	settings, err := s.notifRepo.GetSettings(userID)
	if err != nil {
		log.Printf("⚠️ Không lấy được settings của user %s: %v\n", userID, err)
		// Vẫn tạo notification nhưng không gửi FCM
	}

	// 2. Kiểm tra xem user có bật loại thông báo này không
	shouldSend := s.checkNotificationSetting(settings, notifType)

	// 3. Lưu notification vào database
	dataJSON, _ := json.Marshal(data)
	notification := &models.Notification{
		UserID: userID,
		Type:   notifType,
		Title:  title,
		Body:   body,
		Data:   string(dataJSON),
		IsRead: false,
	}

	if err := s.notifRepo.Create(notification); err != nil {
		log.Printf("❌ Lỗi lưu notification vào DB: %v\n", err)
		return err
	}

	// 4. Gửi FCM nếu user bật setting và có token
	if shouldSend && fcmToken != "" {
		s.SendNotification(fcmToken, title, body)
	}

	return nil
}

// CreateAndSendMulticast: Gửi thông báo cho nhiều user
func (s *NotificationService) CreateAndSendMulticast(userIDs []uuid.UUID, notifType, title, body string, data map[string]interface{}, tokens []string) error {
	dataJSON, _ := json.Marshal(data)

	// Lưu notification cho từng user
	for _, userID := range userIDs {
		notification := &models.Notification{
			UserID: userID,
			Type:   notifType,
			Title:  title,
			Body:   body,
			Data:   string(dataJSON),
			IsRead: false,
		}
		s.notifRepo.Create(notification)
	}

	// Gửi FCM multicast
	if len(tokens) > 0 {
		s.SendMulticastNotification(tokens, title, body)
	}

	return nil
}

// checkNotificationSetting: Kiểm tra xem user có bật loại thông báo này không
func (s *NotificationService) checkNotificationSetting(settings *models.NotificationSetting, notifType string) bool {
	if settings == nil {
		return true // Mặc định bật tất cả
	}

	// Mapping notification type với settings
	switch notifType {
	case "group_expense":
		return settings.GroupExpense
	case "group_member_added":
		return settings.GroupMemberAdded
	case "group_member_removed":
		return settings.GroupMemberRemoved
	case "group_deleted":
		return settings.GroupDeleted
	case "expense_updated":
		return settings.ExpenseUpdated
	case "expense_deleted":
		return settings.ExpenseDeleted
	case "transaction_created":
		return settings.TransactionCreated
	case "low_balance":
		return settings.LowBalance
	case "budget_exceeded":
		return settings.BudgetExceeded
	case "daily_summary":
		return settings.DailySummary
	case "savings_goal_reached":
		return settings.SavingsGoalReached
	case "savings_reminder":
		return settings.SavingsReminder
	case "savings_progress":
		return settings.SavingsProgress
	case "system_announcement":
		return settings.SystemAnnouncement
	case "security_alert":
		return settings.SecurityAlert
	case "app_update":
		return settings.AppUpdate
	case "maintenance":
		return settings.Maintenance
	default:
		return true // Mặc định bật
	}
}
