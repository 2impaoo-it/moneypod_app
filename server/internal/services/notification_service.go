package services

import (
	"context"
	"fmt"
	"log"

	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/messaging"
	"google.golang.org/api/option"
)

type NotificationService struct {
	client *messaging.Client
}

// Khởi tạo Service: Kết nối tới Firebase
func NewNotificationService(credPath string) (*NotificationService, error) {
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

	return &NotificationService{client: client}, nil
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
