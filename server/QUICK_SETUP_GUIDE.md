# Quick Setup Guide - Cập Nhật Code Hiện Tại

## 1. Cập nhật khởi tạo AuthService

### Tìm file khởi tạo services (thường là `cmd/server/main.go` hoặc `internal/routes/routes.go`):

**Trước đây:**

```go
authService := services.NewAuthService(userRepo)
```

**Cập nhật thành:**

```go
// Khởi tạo Email Service (tạm thời dùng Simple, sau này thay bằng SendGrid)
emailService := &services.SimpleEmailService{}

// Khởi tạo AuthService với email service
authService := services.NewAuthService(userRepo, emailService)
```

---

## 2. Test các thay đổi

### Test ForgotPassword:

```bash
# Terminal
curl -X POST http://localhost:8080/api/auth/forgot-password \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com"}'
```

**Kết quả mong đợi:**

```
📧 [EMAIL] Gửi email đến: test@example.com
📧 [EMAIL] Mật khẩu tạm thời: TempXXXXXXXXXXXX!@
✅ Đã reset mật khẩu cho email: test@example.com
```

### Test UpdateExpense (với debt đã thanh toán):

```bash
curl -X PUT http://localhost:8080/api/groups/expenses/{expense_id} \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 200000,
    "description": "Cập nhật test",
    "split_details": [...]
  }'
```

**Kết quả mong đợi (nếu có người đã trả):**

```json
{
  "error": "không thể sửa hóa đơn này vì đã có người trả nợ"
}
```

### Test Pagination:

```bash
curl -X GET http://localhost:8080/api/transactions \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**Kết quả:** Chỉ trả về tối đa 100 giao dịch gần nhất (thay vì tất cả)

---

## 3. Production Deployment Checklist

### A. Email Service (BẮT BUỘC trước khi production)

```go
// 1. Install SendGrid package
go get github.com/sendgrid/sendgrid-go

// 2. Tạo SendGridEmailService
type SendGridEmailService struct {
    apiKey string
}

func (s *SendGridEmailService) SendPasswordResetEmail(to, temporaryPassword string) error {
    from := mail.NewEmail("MoneyPod App", "noreply@moneypod.app")
    subject := "Reset Password Request"
    toEmail := mail.NewEmail("User", to)
    plainTextContent := fmt.Sprintf("Your temporary password is: %s", temporaryPassword)
    htmlContent := fmt.Sprintf("<strong>Your temporary password is:</strong> %s", temporaryPassword)
    message := mail.NewSingleEmail(from, subject, toEmail, plainTextContent, htmlContent)

    client := sendgrid.NewSendClient(s.apiKey)
    _, err := client.Send(message)
    return err
}

// 3. Cập nhật main.go
emailService := &SendGridEmailService{
    apiKey: os.Getenv("SENDGRID_API_KEY"),
}
authService := services.NewAuthService(userRepo, emailService)
```

### B. Environment Variables

```bash
# .env hoặc system environment
SENDGRID_API_KEY=your_sendgrid_api_key_here
```

### C. Database Index (khuyến nghị)

```sql
-- Tăng tốc độ query trong UpdateExpense check
CREATE INDEX idx_debt_payment_requests_status ON debt_payment_requests(status);
CREATE INDEX idx_debts_expense_id ON debts(expense_id);
CREATE INDEX idx_debts_is_paid ON debts(is_paid);

-- Tăng tốc độ query transactions
CREATE INDEX idx_transactions_user_id_created_at ON transactions(user_id, created_at DESC);
```

---

## 4. Rollback Plan (nếu có vấn đề)

### Nếu Email Service gặp lỗi:

```go
// Temporary fallback - log mật khẩu ra console
type ConsoleEmailService struct{}

func (s *ConsoleEmailService) SendPasswordResetEmail(to, temporaryPassword string) error {
    fmt.Printf("🔑 Password reset for %s: %s\n", to, temporaryPassword)
    return nil
}
```

### Nếu UpdateExpense check quá chậm:

Có thể tạm thời comment 2 checks validation (nhưng KHÔNG KHUYẾN NGHỊ):

```go
// ⚠️ TEMPORARY ONLY - Bỏ validation để test performance
// if len(paidDebts) > 0 {
//     return errors.New("...")
// }
```

---

## 5. Monitoring & Logging

### Thêm logging cho các operations quan trọng:

```go
// Example trong ForgotPassword
log.Printf("[AUTH] Password reset requested for email: %s", email)
log.Printf("[EMAIL] Sending email to: %s", email)

// Example trong UpdateExpense
log.Printf("[GROUP] UpdateExpense - expense_id: %s, paid_debts: %d, pending_payments: %d",
    expenseID, len(paidDebts), pendingPayments)
```

---

## 📞 Support

Nếu gặp vấn đề khi deploy, kiểm tra:

1. Go version: `go version` (khuyến nghị >= 1.21)
2. Database connection: Test với `SELECT 1`
3. Email service: Test riêng trước khi tích hợp
4. Logs: Check console output cho error messages

---

**Last updated:** 30/12/2025
