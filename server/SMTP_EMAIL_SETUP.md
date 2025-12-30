# Hướng Dẫn Cấu Hình SMTP Email Service 📧

## Tổng Quan

`SimpleEmailService` sử dụng **SMTP (Simple Mail Transfer Protocol)** để gửi email reset password cho users.

## SMTP Là Gì?

**SMTP** là giao thức chuẩn để gửi email qua Internet. Thay vì gọi API của bên thứ 3 (như SendGrid), bạn kết nối trực tiếp đến SMTP server để gửi email.

### Ưu điểm:

- ✅ **Miễn phí**: Gmail cho phép 500 email/ngày miễn phí
- ✅ **Đơn giản**: Không cần đăng ký service khác
- ✅ **Linh hoạt**: Dễ dàng đổi provider (Gmail → Outlook → custom SMTP)

### Nhược điểm:

- ⚠️ Giới hạn số email/ngày (Gmail: 500)
- ⚠️ Cần bật "App Password" cho Gmail
- ⚠️ Có thể bị spam filter nếu không config DNS đúng

---

## Cách Hoạt Động

```
User quên mật khẩu
    ↓
API /forgot-password
    ↓
AuthService.ForgotPassword()
    ↓
SimpleEmailService.SendPasswordResetEmail()
    ↓
Kết nối SMTP Server (Gmail/Outlook/etc)
    ↓
Gửi email HTML đẹp với mật khẩu tạm thời
    ↓
User nhận email và đăng nhập
```

---

## Cấu Hình

### 1. Thêm vào file `.env`:

```bash
# SMTP Email Configuration
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-password
SMTP_FROM=MoneyPod App <noreply@moneypod.app>
```

### 2. Tạo App Password cho Gmail

#### Bước 1: Bật 2-Factor Authentication

1. Vào [Google Account Security](https://myaccount.google.com/security)
2. Bật **2-Step Verification**

#### Bước 2: Tạo App Password

1. Vào [App Passwords](https://myaccount.google.com/apppasswords)
2. Chọn **Mail** và **Other (Custom name)**
3. Đặt tên: **MoneyPod Backend**
4. Copy password (16 ký tự không có dấu cách)
5. Paste vào `SMTP_PASSWORD` trong `.env`

**Ví dụ:**

```bash
SMTP_PASSWORD=abcd efgh ijkl mnop  # ← Paste password này (bỏ dấu cách)
```

---

## Các Provider SMTP Phổ Biến

### Gmail (Khuyến nghị cho Development)

```bash
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-16-digit-app-password
SMTP_FROM=MoneyPod App <your-email@gmail.com>
```

- **Giới hạn:** 500 email/ngày
- **Chi phí:** Miễn phí

### Outlook / Hotmail

```bash
SMTP_HOST=smtp-mail.outlook.com
SMTP_PORT=587
SMTP_USERNAME=your-email@outlook.com
SMTP_PASSWORD=your-password
SMTP_FROM=MoneyPod App <your-email@outlook.com>
```

- **Giới hạn:** 300 email/ngày
- **Chi phí:** Miễn phí

### SendGrid (Khuyến nghị cho Production)

```bash
SMTP_HOST=smtp.sendgrid.net
SMTP_PORT=587
SMTP_USERNAME=apikey
SMTP_PASSWORD=your-sendgrid-api-key
SMTP_FROM=noreply@yourdomain.com
```

- **Giới hạn:** 100 email/ngày (free), unlimited (paid)
- **Chi phí:** Free tier available, $15/month cho 40k emails

### Mailgun

```bash
SMTP_HOST=smtp.mailgun.org
SMTP_PORT=587
SMTP_USERNAME=postmaster@your-domain.mailgun.org
SMTP_PASSWORD=your-mailgun-password
SMTP_FROM=noreply@yourdomain.com
```

- **Giới hạn:** 5,000 email/tháng (free)
- **Chi phí:** $35/month cho 50k emails

---

## Development Mode (Không có SMTP)

Nếu bạn **không cấu hình SMTP** (để trống trong `.env`), email service sẽ tự động chạy ở **Development Mode**:

```go
// Khi SMTP_HOST = ""
📧 [EMAIL - DEV MODE] Gửi email đến: user@example.com
📧 [EMAIL - DEV MODE] Mật khẩu tạm thời: Temp8a7f2c1e3d4!@
📧 [EMAIL - DEV MODE] Vui lòng đổi mật khẩu sau khi đăng nhập
```

→ Mật khẩu sẽ in ra console, bạn copy để test.

---

## Test Email Service

### 1. Start Server

```bash
cd server
go run cmd/server/main.go
```

Kết quả mong đợi:

```
✅ Đã load cấu hình từ .env
✅ Đã cấu hình SMTP Email Service: smtp.gmail.com:587
✅ Server đang chạy trên port: 8080
```

### 2. Test API ForgotPassword

```bash
curl -X POST http://localhost:8080/api/v1/auth/forgot-password \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com"}'
```

### 3. Kiểm tra email

- Vào inbox của email test
- Tìm email từ MoneyPod App
- Subject: **Reset Password - MoneyPod App**
- Body: HTML đẹp với mật khẩu tạm thời

---

## Troubleshooting

### ❌ Lỗi: "Invalid Username or Password"

**Nguyên nhân:** Sai App Password hoặc chưa bật 2FA

**Giải pháp:**

1. Kiểm tra lại App Password (16 ký tự, không dấu cách)
2. Đảm bảo đã bật 2-Step Verification
3. Tạo App Password mới

### ❌ Lỗi: "Connection timeout"

**Nguyên nhân:** Firewall block port 587

**Giải pháp:**

1. Kiểm tra firewall/antivirus
2. Thử port khác: 465 (SSL) hoặc 25
3. Test với telnet: `telnet smtp.gmail.com 587`

### ❌ Email vào Spam

**Nguyên nhân:** SMTP FROM không match với SMTP_USERNAME

**Giải pháp:**

```bash
# ✅ ĐÚNG
SMTP_USERNAME=your-email@gmail.com
SMTP_FROM=MoneyPod App <your-email@gmail.com>

# ❌ SAI
SMTP_USERNAME=your-email@gmail.com
SMTP_FROM=noreply@moneypod.com  # Email khác
```

### ❌ Lỗi: "Daily sending quota exceeded"

**Nguyên nhân:** Vượt quá 500 email/ngày (Gmail)

**Giải pháp:**

1. Đợi 24h để reset quota
2. Upgrade lên G Suite Business ($6/user/month)
3. Chuyển sang SendGrid/Mailgun

---

## Production Checklist

Trước khi deploy Production, đảm bảo:

- [ ] Đã đăng ký SMTP service (SendGrid/Mailgun khuyến nghị)
- [ ] Cấu hình DNS records (SPF, DKIM, DMARC)
- [ ] Test gửi email đến nhiều providers (Gmail, Yahoo, Outlook)
- [ ] Monitor email delivery rate
- [ ] Setup email templates đẹp hơn (có logo, branding)
- [ ] Implement rate limiting (tránh spam)
- [ ] Log email activities
- [ ] Handle bounce emails

---

## So Sánh: SMTP vs SendGrid API

| Feature        | SMTP                 | SendGrid API                  |
| -------------- | -------------------- | ----------------------------- |
| Setup          | Dễ, chỉ cần env vars | Cần install package, register |
| Chi phí        | Miễn phí (Gmail)     | $15/month (40k emails)        |
| Reliability    | 95-98%               | 99.9%                         |
| Analytics      | Không có             | Dashboard đầy đủ              |
| Templates      | Tự code HTML         | Built-in template engine      |
| Scalability    | Limited (500/day)    | Unlimited                     |
| Deliverability | Tốt                  | Excellent                     |

**Khuyến nghị:**

- **Development/Small projects:** SMTP (Gmail)
- **Production/Large projects:** SendGrid API

---

## Tài Liệu Tham Khảo

- [Gmail SMTP Settings](https://support.google.com/mail/answer/7126229)
- [SendGrid SMTP](https://docs.sendgrid.com/for-developers/sending-email/getting-started-smtp)
- [Mailgun Documentation](https://documentation.mailgun.com/en/latest/user_manual.html)
- [Go net/smtp Package](https://pkg.go.dev/net/smtp)

---

**Last updated:** 30/12/2025
