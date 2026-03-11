# 🔒 HƯỚNG DẪN BẢO MẬT CHO PRODUCTION

## ⚠️ QUAN TRỌNG: Cần thực hiện trước khi deploy lên production

### 1. Thay đổi Secret Keys

```bash
# Tạo JWT Secret Key mạnh hơn (ít nhất 32 ký tự ngẫu nhiên)
openssl rand -base64 32

# Cập nhật vào .env:
JWT_SECRET_KEY=<chuỗi_32_ký_tự_ngẫu_nhiên>
ADMIN_SECRET_KEY=<chuỗi_khác_32_ký_tự>
```

### 2. Cấu hình CORS cho Production

Sửa file: `server/internal/middleware/cors.go`

```go
// Thay "*" bằng domain của ứng dụng Flutter
c.Writer.Header().Set("Access-Control-Allow-Origin", "https://yourdomain.com")
```

### 3. Bật HTTPS

- Sử dụng reverse proxy (Nginx/Caddy) với SSL certificate
- Hoặc deploy lên cloud provider có HTTPS built-in (Heroku, Railway, etc.)

### 4. Cấu hình Database Production

```env
DB_HOST=<production_db_host>
DB_USER=<production_db_user>
DB_PASSWORD=<strong_password_here>
DB_NAME=<production_db_name>
```

### 5. Thay đổi GIN_MODE

```env
GIN_MODE=release
```

### 6. Rotate API Keys

- Gemini API Key
- Cloudinary credentials
- Firebase credentials
- SMTP password

### 7. Environment Variables

**KHÔNG BAO GIỜ** commit file `.env` lên Git!
Sử dụng environment variables của hosting platform.

### 8. Rate Limiting Tuning

Điều chỉnh trong `server/internal/middleware/rate_limiter.go`:

```go
// Có thể tăng hoặc giảm tùy theo traffic thực tế
burst: 10,  // requests per second
```

### 9. Monitoring & Logging

- Thiết lập logging system (ELK Stack, Datadog, etc.)
- Monitor failed login attempts
- Alert khi có quá nhiều 429 (rate limit) errors

### 10. Database Security

- Kích hoạt SSL/TLS cho database connection
- Backup database định kỳ
- Giới hạn quyền database user (không dùng superuser)

---

## ✅ Checklist Deploy Production

- [ ] Secret keys đã được thay đổi
- [ ] CORS được cấu hình đúng domain
- [ ] HTTPS được kích hoạt
- [ ] Database production đã setup
- [ ] GIN_MODE=release
- [ ] API keys đã rotate
- [ ] .env không có trong Git
- [ ] Rate limiting đã test
- [ ] Logging system đã setup
- [ ] Database backup đã setup
- [ ] Firewall rules đã cấu hình
- [ ] Health check endpoint đã test

---

## 🔐 Các biện pháp bảo mật đã được implement:

1. ✅ **CORS Middleware** - Ngăn chặn CSRF attacks
2. ✅ **Rate Limiting** - Ngăn chặn brute force & DDoS
3. ✅ **Strict Rate Limit** - Bảo vệ auth endpoints (5 requests/15 phút)
4. ✅ **Input Validation** - Validate email, password, phone
5. ✅ **Password Strength** - Yêu cầu: 8+ ký tự, chữ hoa, chữ thường, số, ký tự đặc biệt
6. ✅ **JWT Token** - Giảm expire time xuống 7 ngày (từ 3 ngày)
7. ✅ **Bcrypt Hashing** - Mã hóa password với cost factor 10
8. ✅ **SQL Injection Protection** - GORM ORM + Input sanitization
9. ✅ **Admin Middleware** - Bảo vệ admin endpoints với secret key
10. ✅ **Auth Middleware** - Xác thực JWT token cho protected routes

---

**Lưu ý:** File này chỉ dùng để hướng dẫn, không được commit lên production repository.
