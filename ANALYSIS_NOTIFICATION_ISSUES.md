# 🔍 PHÂN TÍCH SÂU: VẤN ĐỀ NOTIFICATION SPAM & FCM ERROR

**Ngày phân tích:** 5/1/2026 16:09  
**Phân tích bởi:** Senior Product Manager & Architect

---

## 📊 HIỆN TRẠNG

### 1. SPAM NOTIFICATION - Vấn đề nghiêm trọng nhất

**Log evidence:**

```
User 29a18a18-b406-4d25-a086-0e3b75f840a7:
- 16:09:02 - Notification 1
- 16:09:02 - Notification 2
- 16:09:03 - Notification 3
- 16:09:03 - Notification 4
... (tiếp tục đến 12 notifications)
```

**Root cause:**

```go
// File: notification_scheduler.go:44-130
func (s *NotificationScheduler) SendDebtReminders() {
    // Query: Lấy TẤT CẢ debts chưa trả
    query := `SELECT ... FROM debts d WHERE d.is_paid = false`

    // Loop: Gửi TỪNG debt riêng biệt
    for _, debt := range debts {
        s.notifService.CreateAndSendNotification(...)  // ❌ 1 debt = 1 notification
    }
}
```

**Vấn đề:**

- **Thiết kế sai:** Gửi 1 notification cho MỖI khoản nợ
- **Kết quả:** User có 12 khoản nợ → nhận 12 notifications trong 6 giây
- **UX disaster:** Spam nghiêm trọng, user sẽ tắt notifications hoặc gỡ app

**Có cơ chế chống duplicate?**  
✅ CÓ, nhưng chỉ check trong 24h cho TỪNG debt riêng lẻ:

```go
// Line 92-103: Check duplicate per debt
s.db.Model(&models.Notification{}).
    Where("user_id = ? AND type = ? AND data::text LIKE ? AND created_at > ?",
        debt.FromUserID,
        "debt_reminder",
        fmt.Sprintf("%%\"debt_id\":\"%s\"%%", debt.DebtID),  // ❌ Check per debt
        time.Now().Add(-24*time.Hour),
    ).Count(&existingCount)
```

→ **Vô dụng** vì không ngăn được việc gửi 12 debts cùng lúc!

---

### 2. FCM TOKEN INVALID - Performance waste

**Log evidence:**

```
User 56f65384-184d-40de-ab09-54f8d27218b1: 3x "Requested entity was not found"
User 29a18a18-b406-4d25-a086-0e3b75f840a7: 12x lỗi
User 0873f14f-fc26-4a28-9ebc-e93aa29144d6: 1x lỗi
```

**Root cause:**

```go
// File: notification_service.go:83-106
func (s *NotificationService) SendNotification(token, title, body string) {
    _, err := s.client.Send(context.Background(), message)
    if err != nil {
        log.Println("❌ Lỗi gửi thông báo FCM:", err)
        return  // ❌ Chỉ log, không xử lý
    }
}
```

**Vấn đề:**

- **Không có error handling:** Khi token invalid → chỉ log và bỏ qua
- **Token không bị vô hiệu hóa:** Lần sau vẫn tiếp tục gửi → waste resources
- **Performance:** Mỗi lỗi FCM = ~200-500ms delay
  - User `29a18a18`: 12 lần gửi thất bại = ~3-6 giây lãng phí

**Cần làm:**

1. Detect invalid token (error: "Requested entity was not found")
2. Set `fcm_token = NULL` hoặc `fcm_token_valid = false` trong DB
3. Không gửi nữa cho đến khi user update token mới

---

### 3. HIỆU NĂNG: No grouping, no batching

**Architecture hiện tại:**

```
1. Query all debts (có thể 100-1000 records)
2. Loop từng debt:
   - Check duplicate (1 DB query)
   - Create notification (1 DB query)
   - Send FCM (1 API call)
3. Repeat x N debts
```

**Vấn đề:**

- **N+1 queries:** 100 debts = 200-300 DB queries
- **No batching:** Gửi từng FCM riêng lẻ thay vì multicast
- **No grouping:** User với nhiều debts bị spam

---

## 🎯 GIẢI PHÁP ĐỀ XUẤT

### Solution A: GROUP BY USER (Recommended)

**Nguyên tắc:** 1 user = 1 notification tổng hợp

**Implementation:**

```go
// Step 1: Query và group by user
query := `
    SELECT
        d.from_user_id,
        COUNT(*) as debt_count,
        SUM(d.amount) as total_amount,
        u.fcm_token,
        ARRAY_AGG(g.name) as group_names
    FROM debts d
    JOIN expenses e ON d.expense_id = e.id
    JOIN groups g ON e.group_id = g.id
    JOIN users u ON d.from_user_id = u.id
    WHERE d.is_paid = false
    AND u.fcm_token != ''
    GROUP BY d.from_user_id, u.fcm_token
`

// Step 2: Send 1 notification per user
for _, user := range results {
    title := "💰 Nhắc nhở thanh toán"

    if user.DebtCount == 1 {
        body = "Bạn có 1 khoản nợ chưa thanh toán"
    } else {
        body = fmt.Sprintf(
            "Bạn có %d khoản nợ chưa thanh toán (tổng %.0f đ) trong %d nhóm",
            user.DebtCount, user.TotalAmount, len(user.GroupNames)
        )
    }

    // Check duplicate: CHỈ 1 notification/user/24h
    var existingCount int64
    s.db.Model(&models.Notification{}).
        Where("user_id = ? AND type = ? AND created_at > ?",
            user.FromUserID,
            "debt_reminder",
            time.Now().Add(-24*time.Hour),
        ).Count(&existingCount)

    if existingCount > 0 {
        continue  // Đã gửi rồi, skip
    }

    s.notifService.CreateAndSendNotification(...)
}
```

**Lợi ích:**

- ✅ User có 12 debts → chỉ nhận 1 notification tổng hợp
- ✅ Giảm 90% DB queries (12 debts → 1 notification)
- ✅ UX tốt hơn: thông tin tổng quan thay vì spam
- ✅ Performance: 100 debts của 10 users → chỉ 10 notifications

---

### Solution B: INTELLIGENT FCM TOKEN MANAGEMENT

**Tự động vô hiệu hóa token lỗi:**

```go
// 1. Add column to users table
type User struct {
    FCMToken      string     `json:"fcm_token"`
    FCMTokenValid bool       `json:"fcm_token_valid" gorm:"default:true"`
    FCMTokenUpdatedAt *time.Time `json:"fcm_token_updated_at"`
}

// 2. Update SendNotification to handle errors
func (s *NotificationService) SendNotification(token, title, body string) error {
    if s == nil || s.client == nil || token == "" {
        return nil
    }

    message := &messaging.Message{
        Notification: &messaging.Notification{
            Title: title,
            Body:  body,
        },
        Token: token,
    }

    _, err := s.client.Send(context.Background(), message)
    if err != nil {
        log.Println("❌ Lỗi gửi thông báo FCM:", err)

        // Check if token is invalid
        if isTokenInvalid(err) {
            return fmt.Errorf("invalid_token: %v", err)
        }
        return err
    }

    log.Println("✅ FCM: Gửi thông báo thành công")
    return nil
}

// 3. Handle invalid token
func isTokenInvalid(err error) bool {
    errMsg := err.Error()
    return strings.Contains(errMsg, "Requested entity was not found") ||
           strings.Contains(errMsg, "registration-token-not-registered") ||
           strings.Contains(errMsg, "invalid-registration-token")
}

// 4. Update CreateAndSendNotification
func (s *NotificationService) CreateAndSendNotification(...) error {
    // ... existing code ...

    if shouldSend && fcmToken != "" {
        err := s.SendNotification(fcmToken, title, body)

        // If token invalid, disable it
        if err != nil && strings.Contains(err.Error(), "invalid_token") {
            log.Printf("🔧 Vô hiệu hóa FCM token cho user %s", userID)
            s.db.Model(&models.User{}).
                Where("id = ?", userID).
                Updates(map[string]interface{}{
                    "fcm_token_valid": false,
                    "fcm_token_updated_at": time.Now(),
                })
        }
    }
}

// 5. Update query để chỉ lấy token valid
query := `
    SELECT ...
    FROM debts d
    JOIN users u ON d.from_user_id = u.id
    WHERE d.is_paid = false
    AND u.fcm_token != ''
    AND u.fcm_token_valid = true  -- ✅ Chỉ lấy token hợp lệ
`
```

**Lợi ích:**

- ✅ Tự động phát hiện và vô hiệu hóa token lỗi
- ✅ Giảm 100% wasted FCM calls cho token invalid
- ✅ Performance: User `29a18a18` từ 12 lỗi → 1 lỗi (lần đầu detect) → 0 lỗi (sau đó skip)

---

### Solution C: BATCH PROCESSING & RATE LIMITING

**Optimization cho scheduler:**

```go
func (s *NotificationScheduler) SendDebtReminders() {
    log.Println("🔔 Đang gửi nhắc nhở nợ...")

    // Step 1: Group by user
    var results []struct {
        FromUserID  uuid.UUID
        DebtCount   int
        TotalAmount float64
        FCMToken    string
        GroupNames  string  // JSON array
    }

    query := `
        SELECT
            d.from_user_id,
            COUNT(*) as debt_count,
            SUM(d.amount) as total_amount,
            u.fcm_token,
            JSON_AGG(DISTINCT g.name) as group_names
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

    // Step 2: Batch check duplicates
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

    alreadySentMap := make(map[uuid.UUID]bool)
    for _, uid := range alreadySentUsers {
        alreadySentMap[uid] = true
    }

    // Step 3: Send with rate limiting
    count := 0
    rateLimiter := time.NewTicker(100 * time.Millisecond)  // Max 10 req/s
    defer rateLimiter.Stop()

    for _, result := range results {
        // Skip if already sent
        if alreadySentMap[result.FromUserID] {
            continue
        }

        <-rateLimiter.C  // Rate limit

        // Build notification
        title := "💰 Nhắc nhở thanh toán"
        body := ""

        if result.DebtCount == 1 {
            body = fmt.Sprintf("Bạn có 1 khoản nợ %.0f đ chưa thanh toán", result.TotalAmount)
        } else {
            body = fmt.Sprintf("Bạn có %d khoản nợ (tổng %.0f đ) chưa thanh toán",
                result.DebtCount, result.TotalAmount)
        }

        data := map[string]interface{}{
            "type":        "debt_reminder",
            "debt_count":  result.DebtCount,
            "total_amount": result.TotalAmount,
        }

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

    log.Printf("✅ Đã gửi %d thông báo nhắc nhở nợ (từ %d users có nợ)\n", count, len(results))
}
```

---

## 📈 KẾT QUẢ DỰ KIẾN

### Before (Hiện tại):

- User có 12 debts: **12 notifications** spam trong 6s
- 100 debts: **~300 DB queries** (N+1)
- Invalid tokens: **Lặp lại mãi**, waste resources
- Performance: **~10-15s** cho 100 debts

### After (Sau optimization):

- User có 12 debts: **1 notification** tổng hợp
- 100 debts (10 users): **~15 DB queries** (group + batch)
- Invalid tokens: **Tự động disable**, không gửi nữa
- Performance: **~2-3s** cho 100 debts

**Improvement:**

- ✅ **91% giảm notifications** (12 → 1 per user)
- ✅ **95% giảm DB queries** (300 → 15)
- ✅ **100% loại bỏ** FCM errors cho invalid tokens
- ✅ **70% faster** (15s → 3s)

---

## ⚡ PRIORITY & IMPLEMENTATION PLAN

### Phase 1: CRITICAL (Làm ngay)

1. **Fix spam notification** (Solution A)

   - Impact: Cao nhất, ảnh hưởng UX nghiêm trọng
   - Effort: 2-3 giờ
   - Files: `notification_scheduler.go`

2. **Handle invalid FCM tokens** (Solution B)
   - Impact: Cao, giảm waste resources
   - Effort: 3-4 giờ
   - Files: `user.go` (migration), `notification_service.go`

### Phase 2: OPTIMIZATION (Tuần sau)

3. **Batch processing** (Solution C)
   - Impact: Trung bình, tăng performance
   - Effort: 2 giờ
   - Files: `notification_scheduler.go`

---

## 🔧 TESTING CHECKLIST

### Trước khi deploy:

- [ ] Test với user có 1 debt → nhận 1 notification
- [ ] Test với user có 12 debts → nhận 1 notification tổng hợp
- [ ] Test với invalid FCM token → token bị disable sau lần đầu
- [ ] Test duplicate: gửi 2 lần trong 24h → chỉ nhận 1 notification
- [ ] Load test: 100 debts → < 5s execution time
- [ ] Monitor logs: không còn spam "Requested entity was not found"

---

**Kết luận:** Đây là critical bug cần fix NGAY. Code hiện tại vi phạm UX principles và gây lãng phí resources nghiêm trọng.
