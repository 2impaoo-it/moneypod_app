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
		fmt.Printf("\n========================================\n")
		fmt.Printf("📧 [EMAIL - DEV MODE] \n")
		fmt.Printf("========================================\n")
		fmt.Printf("Gửi đến: %s\n", to)
		fmt.Printf("Tiêu đề: Đặt Lại Mật Khẩu - MoneyPod App\n")
		fmt.Printf("\n🔐 MẬT KHẨU TẠM THỜI CỦA BẠN:\n")
		fmt.Printf("┌────────────────────────────────────┐\n")
		fmt.Printf("│  %s  │\n", temporaryPassword)
		fmt.Printf("└────────────────────────────────────┘\n")
		fmt.Printf("\n⚠️  VUI LÒNG ĐỔI MẬT KHẨU NGAY SAU KHI ĐĂNG NHẬP!\n")
		fmt.Printf("\nCách sử dụng:\n")
		fmt.Printf("1. Đăng nhập bằng mật khẩu tạm thời này\n")
		fmt.Printf("2. Vào Cài đặt > Bảo mật\n")
		fmt.Printf("3. Đổi sang mật khẩu mới của bạn\n")
		fmt.Printf("========================================\n\n")
		return nil
	}

	// Production mode: Gửi email thực qua SMTP
	subject := "Đặt Lại Mật Khẩu - MoneyPod App"

	// Tạo email body HTML đẹp (table-based layout cho email compatibility)
	body := fmt.Sprintf(`<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="margin: 0; padding: 0; font-family: Arial, 'Helvetica Neue', Helvetica, sans-serif; background-color: #f4f7fa;">
    <table width="100%%" cellpadding="0" cellspacing="0" border="0" style="background-color: #f4f7fa; padding: 40px 20px;">
        <tr>
            <td align="center">
                <!-- Main Container -->
                <table width="600" cellpadding="0" cellspacing="0" border="0" style="max-width: 600px; background-color: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 20px rgba(0,0,0,0.1);">
                    
                    <!-- Header with Gradient -->
                    <tr>
                        <td style="background: linear-gradient(135deg, #667eea 0%%, #764ba2 100%%); padding: 50px 30px; text-align: center;">
                            <h1 style="margin: 0; font-size: 32px; font-weight: bold; color: #ffffff; letter-spacing: -0.5px;">
                                🔐 Đặt Lại Mật Khẩu
                            </h1>
                            <p style="margin: 10px 0 0 0; font-size: 16px; color: rgba(255,255,255,0.95);">
                                MoneyPod - Quản Lý Tài Chính Thông Minh
                            </p>
                        </td>
                    </tr>
                    
                    <!-- Content -->
                    <tr>
                        <td style="padding: 50px 40px;">
                            
                            <!-- Greeting -->
                            <p style="margin: 0 0 20px 0; font-size: 20px; font-weight: 600; color: #2c3e50;">
                                Xin chào!
                            </p>
                            
                            <!-- Message -->
                            <p style="margin: 0 0 25px 0; font-size: 15px; color: #555555; line-height: 1.7;">
                                Chúng tôi nhận được yêu cầu đặt lại mật khẩu cho tài khoản <strong style="color: #667eea;">%s</strong> của bạn.
                                Dưới đây là mật khẩu tạm thời để bạn có thể đăng nhập lại vào ứng dụng.
                            </p>
                            
                            <!-- Password Label -->
                            <p style="margin: 30px 0 15px 0; font-size: 14px; font-weight: bold; color: #667eea; text-transform: uppercase; letter-spacing: 1.5px; text-align: center;">
                                🔐 MẬT KHẨU TẠM THỜI CỦA BẠN
                            </p>
                            
                            <!-- Password Box - Enhanced -->
                            <table width="100%%" cellpadding="0" cellspacing="0" border="0">
                                <tr>
                                    <td style="background: linear-gradient(135deg, #667eea 0%%, #764ba2 100%%); border-radius: 16px; padding: 3px; box-shadow: 0 8px 24px rgba(102, 126, 234, 0.4);">
                                        <table width="100%%" cellpadding="0" cellspacing="0" border="0">
                                            <tr>
                                                <td style="background: #ffffff; border-radius: 14px; padding: 30px 20px; text-align: center;">
                                                    <div style="font-family: 'Courier New', Courier, monospace; font-size: 28px; font-weight: bold; color: #764ba2; letter-spacing: 4px; word-break: break-all; user-select: all; line-height: 1.6;">
                                                        %s
                                                    </div>
                                                </td>
                                            </tr>
                                        </table>
                                    </td>
                                </tr>
                            </table>
                            
                            <!-- Copy Hint - Enhanced -->
                            <table width="100%%" cellpadding="0" cellspacing="0" border="0" style="margin-top: 15px;">
                                <tr>
                                    <td style="background-color: #f0f4ff; border-radius: 10px; padding: 15px; text-align: center;">
                                        <p style="margin: 0; font-size: 14px; color: #667eea; font-weight: 600;">
                                            💡 Mẹo: Nhấn và giữ vào mật khẩu để chọn toàn bộ, sau đó copy (Ctrl+C hoặc Cmd+C)
                                        </p>
                                    </td>
                                </tr>
                            </table>
                            
                            <!-- Warning Box -->
                            <table width="100%%" cellpadding="0" cellspacing="0" border="0" style="margin-top: 30px;">
                                <tr>
                                    <td style="background: linear-gradient(135deg, #fff3cd 0%%, #ffe69c 100%%); border-left: 6px solid #ffc107; padding: 25px; border-radius: 12px; box-shadow: 0 4px 12px rgba(255, 193, 7, 0.2);">
                                        <p style="margin: 0 0 12px 0; font-size: 16px; font-weight: 700; color: #856404;">
                                            ⚠️ VUI LÒNG ĐỔI MẬT KHẨU NGAY SAU KHI ĐĂNG NHẬP!
                                        </p>
                                        <p style="margin: 0; font-size: 14px; color: #856404; line-height: 1.6;">
                                            Để bảo mật tài khoản, bạn cần thay đổi mật khẩu này ngay sau lần đăng nhập đầu tiên.
                                        </p>
                                    </td>
                                </tr>
                            </table>
                            
                            <!-- Steps to change password -->
                            <table width="100%%" cellpadding="0" cellspacing="0" border="0" style="margin-top: 25px;">
                                <tr>
                                    <td style="background-color: #f8f9fc; border-radius: 12px; padding: 25px;">
                                        <p style="margin: 0 0 15px 0; font-size: 15px; font-weight: 600; color: #2c3e50;">
                                            📝 Hướng dẫn đổi mật khẩu:
                                        </p>
                                        <ol style="margin: 0; padding-left: 20px; font-size: 14px; color: #555555; line-height: 2;">
                                            <li style="margin-bottom: 8px;">Đăng nhập bằng mật khẩu tạm thời phía trên</li>
                                            <li style="margin-bottom: 8px;">Vào phần <strong>Cài đặt → Bảo mật</strong></li>
                                            <li style="margin-bottom: 8px;">Chọn <strong>"Đổi mật khẩu"</strong></li>
                                            <li style="margin-bottom: 0;">Nhập mật khẩu mới và xác nhận</li>
                                        </ol>
                                    </td>
                                </tr>
                            </table>
                            
                            <!-- Security Info -->
                            <p style="margin: 25px 0 0 0; font-size: 14px; color: #666666; line-height: 1.8;">
                                <strong>Lý do bảo mật:</strong> Hãy thay đổi mật khẩu này bằng một mật khẩu mạnh và duy nhất của riêng bạn. 
                                Mật khẩu tạm thời này chỉ có hiệu lực trong <strong style="color: #e74c3c;">24 giờ</strong>.
                            </p>
                            
                            <p style="margin: 20px 0 0 0; font-size: 14px; color: #666666; line-height: 1.8;">
                                Nếu bạn không yêu cầu đặt lại mật khẩu, vui lòng bỏ qua email này hoặc 
                                liên hệ với chúng tôi ngay lập tức.
                            </p>
                            
                            <!-- Divider -->
                            <div style="margin: 35px 0; height: 1px; background-color: #e5e7eb;"></div>
                            
                            <!-- Auto Reply Notice -->
                            <p style="margin: 0; font-size: 12px; color: #999999; font-style: italic; line-height: 1.6;">
                                Đây là email tự động, vui lòng không trả lời email này. 
                                Nếu bạn cần hỗ trợ, vui lòng liên hệ với chúng tôi qua ứng dụng.
                            </p>
                            
                        </td>
                    </tr>
                    
                    <!-- Footer -->
                    <tr>
                        <td style="background-color: #f8f9fc; padding: 35px 40px; text-align: center; border-top: 1px solid #e5e7eb;">
                            <p style="margin: 0 0 10px 0; font-size: 14px; color: #555555;">
                                Trân trọng,<br>
                                <strong style="color: #667eea; font-size: 16px;">MoneyPod Team</strong>
                            </p>
                            <p style="margin: 15px 0 0 0; font-size: 12px; color: #999999; line-height: 1.6;">
                                © 2025 MoneyPod App<br>
                                Bảo mật & An toàn là ưu tiên hàng đầu của chúng tôi 🔒
                            </p>
                        </td>
                    </tr>
                    
                </table>
            </td>
        </tr>
    </table>
</body>
</html>`, to, temporaryPassword)

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
