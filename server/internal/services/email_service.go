package services

import (
	"crypto/rand"
	"crypto/tls"
	"encoding/hex"
	"fmt"
	"net"
	"net/smtp"
	"time"

	"github.com/google/uuid"
)

// EmailService interface for sending emails
// Implement this interface with services like SendGrid, AWS SES, or Gmail SMTP
type EmailService interface {
	SendPasswordResetEmail(to, temporaryPassword string) error
}

// SMTPConfig holds SMTP server configuration
type SMTPConfig struct {
	Host     string // SMTP server host (e.g., "smtp.gmail.com")
	Port     string // SMTP server port (e.g., "587")
	Username string // SMTP username/email
	Password string // SMTP password/app password
	From     string // Sender email address
}

// SimpleEmailService - SMTP email service implementation
// Supports Gmail SMTP and other SMTP servers
type SimpleEmailService struct {
	config SMTPConfig
}

// NewSimpleEmailService creates a new email service with SMTP configuration
func NewSimpleEmailService(config SMTPConfig) *SimpleEmailService {
	return &SimpleEmailService{config: config}
}

// SendPasswordResetEmail sends password reset email via SMTP
func (s *SimpleEmailService) SendPasswordResetEmail(to, temporaryPassword string) error {
	// Nếu không có config SMTP, chỉ log ra console (development mode)
	if s.config.Host == "" {
		fmt.Printf("📧 [EMAIL - DEV MODE] Gửi email đến: %s\n", to)
		fmt.Printf("📧 [EMAIL - DEV MODE] Mật khẩu tạm thời: %s\n", temporaryPassword)
		fmt.Println("📧 [EMAIL - DEV MODE] Vui lòng đổi mật khẩu sau khi đăng nhập")
		return nil
	}

	// Production mode: Gửi email thực qua SMTP
	subject := "Reset Password - MoneyPod App"

	// Tạo email body HTML đẹp
	body := fmt.Sprintf(`<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: linear-gradient(135deg, #667eea 0%s, #764ba2 100%s); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
        .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
        .password { background: #fff; padding: 15px; margin: 20px 0; border-left: 4px solid #667eea; font-family: 'Courier New', monospace; font-size: 18px; font-weight: bold; color: #764ba2; }
        .footer { text-align: center; margin-top: 20px; color: #999; font-size: 12px; }
        .warning { color: #e74c3c; font-weight: bold; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Reset Password Request</h1>
        </div>
        <div class="content">
            <h2>Xin chao!</h2>
            <p>Ban da yeu cau reset mat khau cho tai khoan <strong>%s</strong>.</p>
            
            <p>Mat khau tam thoi cua ban la:</p>
            <div class="password">%s</div>
            
            <p class="warning">Vui long doi mat khau ngay sau khi dang nhap!</p>
            
            <p>Neu ban khong yeu cau reset mat khau, vui long bo qua email nay hoac lien he voi chung toi ngay lap tuc.</p>
            
            <p>Tran trong,<br><strong>MoneyPod Team</strong></p>
        </div>
        <div class="footer">
            <p>Email nay duoc gui tu dong, vui long khong reply.</p>
            <p>2025 MoneyPod App. All rights reserved.</p>
        </div>
    </div>
</body>
</html>`, "%", "%", to, temporaryPassword)

	// Tạo email message theo format SMTP chuẩn
	// Format: "Display Name <email@example.com>"
	fromName := "MoneyPod App Support"
	// Dùng email noreply để ẩn email thật
	displayEmail := "support@moneypod.app"
	fromHeader := fmt.Sprintf("%s <%s>", fromName, displayEmail)

	message := []byte("From: " + fromHeader + "\r\n" +
		"Reply-To: " + displayEmail + "\r\n" +
		"To: " + to + "\r\n" +
		"Subject: " + subject + "\r\n" +
		"MIME-Version: 1.0\r\n" +
		"Content-Type: text/html; charset=UTF-8\r\n" +
		"\r\n" +
		body)

	// SMTP Authentication
	auth := smtp.PlainAuth("", s.config.Username, s.config.Password, s.config.Host)

	// Gửi email với TLS (MAIL FROM vẫn phải là email thuần)
	addr := s.config.Host + ":" + s.config.Port
	err := sendMailWithTLS(addr, auth, s.config.Username, []string{to}, message)

	if err != nil {
		fmt.Printf("❌ Lỗi gửi email đến %s: %v\n", to, err)
		return fmt.Errorf("không thể gửi email: %v", err)
	}

	fmt.Printf("✅ Đã gửi email reset password đến: %s\n", to)
	return nil
}

// sendMailWithTLS gửi email với TLS/STARTTLS support
func sendMailWithTLS(addr string, auth smtp.Auth, from string, to []string, msg []byte) error {
	// Parse host from addr
	host, _, err := net.SplitHostPort(addr)
	if err != nil {
		return err
	}

	// Connect to server
	conn, err := net.Dial("tcp", addr)
	if err != nil {
		return err
	}

	// Create SMTP client
	c, err := smtp.NewClient(conn, host)
	if err != nil {
		return err
	}
	defer c.Close()

	// Start TLS
	tlsConfig := &tls.Config{
		ServerName: host,
		MinVersion: tls.VersionTLS12,
	}

	if err = c.StartTLS(tlsConfig); err != nil {
		return err
	}

	// Auth
	if err = c.Auth(auth); err != nil {
		return err
	}

	// Set sender
	if err = c.Mail(from); err != nil {
		return err
	}

	// Set recipients
	for _, recipient := range to {
		if err = c.Rcpt(recipient); err != nil {
			return err
		}
	}

	// Send data
	w, err := c.Data()
	if err != nil {
		return err
	}

	_, err = w.Write(msg)
	if err != nil {
		return err
	}

	err = w.Close()
	if err != nil {
		return err
	}

	return c.Quit()
}

// generateRandomPassword generates a secure random password
func generateRandomPassword(length int) (string, error) {
	bytes := make([]byte, length)
	if _, err := rand.Read(bytes); err != nil {
		return "", err
	}
	return hex.EncodeToString(bytes)[:length], nil
}

// PasswordResetToken stores reset token information
type PasswordResetToken struct {
	UserID    uuid.UUID
	Token     string
	ExpiresAt time.Time
}

// In-memory storage for reset tokens (In production, use Redis or database)
var resetTokens = make(map[string]PasswordResetToken)
