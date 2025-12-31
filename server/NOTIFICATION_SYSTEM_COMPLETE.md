# HỆ THỐNG THÔNG BÁO MONEYPOD - HOÀN THÀNH ✅

**Ngày hoàn thành:** 31/12/2025  
**Commits:** 3 phases đã được commit riêng biệt

---

## 📊 TỔNG QUAN HỆ THỐNG

Hệ thống thông báo đã được triển khai đầy đủ với **3 Phases**, bao gồm:

- ✅ **Models & Database:** 2 bảng mới (`notifications`, `notification_settings`)
- ✅ **APIs:** 8 endpoints cho quản lý thông báo
- ✅ **Thông báo nhóm:** 6 loại (thêm/xóa member, sửa/xóa expense, giải tán nhóm)
- ✅ **Thông báo tiết kiệm:** Đạt mục tiêu, tiến độ 50%/75%/90%
- ✅ **Thông báo ví:** Cảnh báo số dư thấp (<100k)
- ✅ **Thông báo hệ thống:** Đăng nhập thiết bị mới, bảo trì
- ✅ **Scheduler tự động:** Nhắc nhở nợ (24h), tiết kiệm (7 ngày)

---

## 🗂️ CẤU TRÚC DATABASE

### Bảng `notifications`

```sql
- id (uuid, PK)
- user_id (uuid, FK -> users)
- type (string) - Loại thông báo
- title (string)
- body (string)
- data (jsonb) - Metadata
- is_read (boolean, default: false)
- read_at (timestamp, nullable)
- created_at, updated_at, deleted_at
```

### Bảng `notification_settings`

```sql
- id (uuid, PK)
- user_id (uuid, unique, FK -> users)
- group_expense (bool, default: true)
- group_member_added (bool, default: true)
- group_member_removed (bool, default: true)
- group_deleted (bool, default: true)
- expense_updated (bool, default: true)
- expense_deleted (bool, default: true)
- transaction_created (bool, default: true)
- low_balance (bool, default: true)
- budget_exceeded (bool, default: true)
- daily_summary (bool, default: false)
- savings_goal_reached (bool, default: true)
- savings_reminder (bool, default: true)
- savings_progress (bool, default: true)
- system_announcement (bool, default: true)
- security_alert (bool, default: true)
- app_update (bool, default: true)
- maintenance (bool, default: true)
- created_at, updated_at, deleted_at
```

---

## 🔌 API ENDPOINTS

### 1. Quản lý Thông báo

#### `GET /api/v1/notifications`

Lấy danh sách thông báo (có phân trang)

```json
Query params:
- limit (int, default: 20)
- offset (int, default: 0)

Response:
{
  "data": [...],
  "limit": 20,
  "offset": 0
}
```

#### `GET /api/v1/notifications/unread-count`

Đếm số thông báo chưa đọc

```json
Response:
{
  "unread_count": 5
}
```

#### `PUT /api/v1/notifications/:id/read`

Đánh dấu một thông báo đã đọc

```json
Response:
{
  "message": "Đã đánh dấu đã đọc"
}
```

#### `PUT /api/v1/notifications/read-all`

Đánh dấu TẤT CẢ thông báo đã đọc

```json
Response:
{
  "message": "Đã đánh dấu tất cả đã đọc"
}
```

#### `DELETE /api/v1/notifications/:id`

Xóa một thông báo

```json
Response:
{
  "message": "Đã xóa thông báo"
}
```

#### `DELETE /api/v1/notifications/all`

Xóa TẤT CẢ thông báo

```json
Response:
{
  "message": "Đã xóa tất cả thông báo"
}
```

---

### 2. Cài đặt Thông báo

#### `GET /api/v1/notifications/settings`

Lấy cài đặt thông báo của user

```json
Response:
{
  "data": {
    "id": "uuid",
    "user_id": "uuid",
    "group_expense": true,
    "group_member_added": true,
    ...
  }
}
```

#### `PUT /api/v1/notifications/settings`

Cập nhật cài đặt thông báo

```json
Request body:
{
  "group_expense": false,
  "low_balance": true,
  ...
}

Response:
{
  "message": "Cập nhật cài đặt thành công",
  "data": {...}
}
```

---

## 📢 DANH SÁCH THÔNG BÁO

### **Phase 1: Thông báo Nhóm**

#### 1. ✅ Thêm thành viên vào nhóm

- **Trigger:** `AddMemberViaPhone()`
- **Người nhận:**
  - Người mới được thêm
  - Tất cả members khác (trừ người thêm)
- **Nội dung:**
  - Cho người mới: "🎉 Chào mừng đến nhóm! Bạn đã được {tên} thêm vào nhóm '{tên nhóm}'"
  - Cho members: "👥 Thành viên mới - {tên} đã thêm {tên mới} vào nhóm '{tên nhóm}'"

#### 2. ✅ Xóa thành viên khỏi nhóm

- **Trigger:** `KickMember()`
- **Người nhận:** Người bị xóa
- **Nội dung:** "⚠️ Bạn đã bị xóa khỏi nhóm '{tên nhóm}'"

#### 3. ✅ Thành viên rời nhóm

- **Trigger:** `LeaveGroup()`
- **Người nhận:** Tất cả members còn lại
- **Nội dung:** "👋 Thành viên rời nhóm - {tên} đã rời khỏi nhóm '{tên nhóm}'"

#### 4. ✅ Xóa hóa đơn

- **Trigger:** `DeleteExpense()`
- **Người nhận:** Tất cả members (trừ người xóa)
- **Nội dung:** "🗑️ Chi tiêu đã bị xóa - Chi tiêu '{mô tả}' ({số tiền} đ) trong nhóm '{tên nhóm}' đã bị xóa"

#### 5. ✅ Sửa hóa đơn

- **Trigger:** `UpdateExpense()`
- **Người nhận:** Tất cả members (trừ người sửa)
- **Nội dung:** "✏️ Chi tiêu đã được cập nhật - Chi tiêu '{mô tả}' trong nhóm '{tên nhóm}' đã được chỉnh sửa"

#### 6. ✅ Giải tán nhóm

- **Trigger:** `DeleteGroup()`
- **Người nhận:** Tất cả members
- **Nội dung:** "⚠️ Nhóm đã bị giải tán - Nhóm '{tên nhóm}' đã bị trưởng nhóm giải tán"

---

### **Phase 2: Thông báo Tiết kiệm & Ví**

#### 7. ✅ Đạt mục tiêu tiết kiệm

- **Trigger:** `SavingsService.Deposit()` khi đạt 100%
- **Người nhận:** Chủ mục tiêu
- **Nội dung:** "🎉 Chúc mừng! Mục tiêu đã hoàn thành - Bạn đã đạt mục tiêu '{tên}' với {số tiền} đ!"

#### 8. ✅ Tiến độ tiết kiệm (50%, 75%, 90%)

- **Trigger:** `SavingsService.Deposit()` khi đạt milestone
- **Người nhận:** Chủ mục tiêu
- **Nội dung:** "💪 Đã đạt {%}% mục tiêu! - '{tên}': {hiện tại}/{mục tiêu} đ. Cố lên!"

#### 9. ✅ Số dư ví thấp

- **Trigger:** `TransactionService.CreateTransaction()` khi chi tiêu
- **Ngưỡng:** < 100,000 đ
- **Người nhận:** Chủ ví
- **Nội dung:** "⚠️ Cảnh báo: Số dư ví thấp - Ví '{tên ví}' chỉ còn {số dư} đ. Hãy nạp thêm tiền!"

---

### **Phase 3: Thông báo Hệ thống & Scheduler**

#### 10. ✅ Đăng nhập thiết bị mới

- **Trigger:** `AuthService.UpdateFCMToken()` khi token thay đổi
- **Người nhận:** Chủ tài khoản
- **Nội dung:** "🔐 Đăng nhập từ thiết bị mới - Tài khoản của bạn vừa được đăng nhập từ một thiết bị mới. Nếu không phải bạn, hãy đổi mật khẩu ngay!"

#### 11. ✅ Nhắc nhở nợ (Auto - 24h)

- **Trigger:** Scheduler chạy mỗi ngày
- **Người nhận:** Những người còn nợ chưa trả
- **Nội dung:** "💰 Nhắc nhở: Bạn còn nợ chưa thanh toán - Bạn còn nợ {số tiền} đ trong nhóm '{tên nhóm}' ('{mô tả}'). Hãy thanh toán sớm nhé!"

#### 12. ✅ Nhắc nhở tiết kiệm (Auto - 7 ngày)

- **Trigger:** Scheduler chạy mỗi tuần
- **Người nhận:** Những người có mục tiêu đang chạy
- **Nội dung:** "🐷 Nhắc nhở tiết kiệm - Mục tiêu '{tên}' đã đạt {%}%. Hãy tiếp tục nạp tiền nhé!"

#### 13. ✅ Bảo trì hệ thống

- **Trigger:** Gọi thủ công `SendMaintenanceNotification()`
- **Người nhận:** TẤT CẢ users
- **Nội dụng:** Tùy chỉnh

---

## ⚙️ CÁC SERVICE ĐÃ CẬP NHẬT

### 1. NotificationService

**File:** `server/internal/services/notification_service.go`

- ✅ `CreateAndSendNotification()` - Lưu DB + gửi FCM
- ✅ `CreateAndSendMulticast()` - Gửi nhiều người
- ✅ `checkNotificationSetting()` - Kiểm tra settings
- ✅ `SendSystemNotification()` - Thông báo hệ thống
- ✅ `SendMaintenanceNotification()` - Bảo trì
- ✅ `SendSecurityAlert()` - Cảnh báo bảo mật

### 2. NotificationRepository

**File:** `server/internal/repositories/notification_repository.go`

- ✅ CRUD đầy đủ cho notifications
- ✅ Quản lý notification settings
- ✅ `CreateDefaultSettings()` - Tạo settings khi đăng ký

### 3. NotificationHandler

**File:** `server/internal/handlers/notification_handler.go`

- ✅ 8 endpoints API hoàn chỉnh

### 4. NotificationScheduler (NEW)

**File:** `server/internal/services/notification_scheduler.go`

- ✅ `StartDebtReminderScheduler()` - Chạy mỗi 24h
- ✅ `StartSavingsReminderScheduler()` - Chạy mỗi 7 ngày
- ✅ Auto-start khi server khởi động

### 5. GroupService

**File:** `server/internal/services/group_service.go`

- ✅ `AddMemberViaPhone()` - Thông báo thêm member
- ✅ `KickMember()` - Thông báo xóa member
- ✅ `LeaveGroup()` - Thông báo rời nhóm
- ✅ `DeleteGroup()` - Thông báo giải tán
- ✅ `DeleteExpense()` - Thông báo xóa expense
- ✅ `UpdateExpense()` - Thông báo sửa expense

### 6. SavingsService

**File:** `server/internal/services/savings_service.go`

- ✅ `Deposit()` - Thông báo đạt mục tiêu & tiến độ

### 7. TransactionService

**File:** `server/internal/services/transaction_service.go`

- ✅ `CreateTransaction()` - Thông báo số dư thấp

### 8. AuthService

**File:** `server/internal/services/auth_service.go`

- ✅ `Register()` - Tạo notification settings mặc định
- ✅ `UpdateFCMToken()` - Thông báo đăng nhập thiết bị mới

---

## 🎯 TÍNH NĂNG NỔI BẬT

### 1. Smart Notification

- ✅ Kiểm tra user settings trước khi gửi
- ✅ Không gửi nếu user tắt loại thông báo đó
- ✅ Lưu vào database để xem lại sau

### 2. Async Processing

- ✅ Gửi thông báo trong goroutine (không block main flow)
- ✅ Server vẫn chạy nếu Firebase lỗi

### 3. Rich Metadata

- ✅ Mỗi thông báo có field `data` (JSON)
- ✅ Chứa thông tin chi tiết: group_id, expense_id, goal_id...
- ✅ App có thể navigate đến màn hình tương ứng

### 4. Auto Scheduler

- ✅ Không cần cron job bên ngoài
- ✅ Tự động chạy khi server start
- ✅ Production-ready với error handling

---

## 🚀 HƯỚNG DẪN SỬ DỤNG

### 1. Setup Firebase (Đã có)

```bash
# File serviceAccountKey.json phải ở root server/
./serviceAccountKey.json
```

### 2. Chạy Migration

```bash
# Database tự động migration khi server start
go run cmd/server/main.go
```

### 3. Test APIs

```bash
# Lấy danh sách thông báo
GET /api/v1/notifications?limit=20&offset=0
Authorization: Bearer <token>

# Đếm chưa đọc
GET /api/v1/notifications/unread-count
Authorization: Bearer <token>

# Đánh dấu đã đọc
PUT /api/v1/notifications/:id/read
Authorization: Bearer <token>

# Cài đặt
GET /api/v1/notifications/settings
PUT /api/v1/notifications/settings
Authorization: Bearer <token>
```

---

## 📝 LỊCH SỬ COMMITS

### Phase 1 - Core notification system

**Commit:** `ab3a6ef`

- Models & Database
- Repository & APIs
- Group notifications

### Phase 2 - Savings & wallet notifications

**Commit:** `5f5fe62`

- Thông báo tiết kiệm
- Thông báo số dư thấp
- API settings

### Phase 3 - System notifications & schedulers

**Commit:** `074ab1c`

- Thông báo hệ thống
- Scheduler tự động
- Security alerts

---

## ✅ CHECKLIST HOÀN THÀNH

- [x] Models: Notification, NotificationSetting
- [x] Repository: CRUD đầy đủ
- [x] Service: NotificationService với FCM + DB
- [x] Handler: 8 APIs hoàn chỉnh
- [x] Scheduler: Debt + Savings reminders
- [x] Tích hợp: 6 services (Group, Savings, Transaction, Auth)
- [x] Migration: Auto-migrate khi start
- [x] Settings: User có thể bật/tắt từng loại
- [x] Async: Không block main flow
- [x] Error handling: Production-ready
- [x] Logging: Chi tiết và dễ debug
- [x] Commits: 3 phases riêng biệt
- [x] Documentation: File này

---

## 🎉 KẾT LUẬN

Hệ thống thông báo đã được triển khai **HOÀN CHỈNH** với:

- ✅ **13 loại thông báo** khác nhau
- ✅ **8 APIs** quản lý thông báo
- ✅ **2 schedulers** tự động
- ✅ **Smart settings** cho user
- ✅ **Production-ready** code
- ✅ **Clean commits** theo từng phase

**Tổng số files thêm/sửa:** 16 files  
**Tổng số dòng code:** ~1,500+ lines  
**Thời gian hoàn thành:** 31/12/2025

---

**Developed by:** MoneyPod Team  
**Last updated:** 31/12/2025
