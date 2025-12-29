# 📋 API Documentation - Groups Module

## 🔐 Authentication

Tất cả API đều yêu cầu **Bearer Token** trong header:

```
Authorization: Bearer <your_token>
```

---

## 1️⃣ Tạo Nhóm Mới

**Endpoint:** `POST /groups`

**Công dụng:** Tạo nhóm mới với danh sách thành viên

**Request Body:**

```json
{
  "name": "Nhóm đi chơi Đà Lạt",
  "description": "Chi tiêu chung 3 ngày 2 đêm",
  "members": [
    {
      "user_id": "current_user"
    },
    {
      "user_id": "uuid-thanh-vien-2"
    }
  ]
}
```

**Response Success (201):**

```json
{
  "message": "Tạo nhóm thành công",
  "data": {
    "id": "uuid-nhom",
    "name": "Nhóm đi chơi Đà Lạt",
    "description": "Chi tiêu chung 3 ngày 2 đêm",
    "invite_code": "ABC123",
    "members": [
      {
        "id": "uuid-member",
        "group_id": "uuid-nhom",
        "user_id": "uuid-user",
        "role": "leader"
      }
    ],
    "created_at": "2025-12-28T10:00:00Z"
  }
}
```

---

## 2️⃣ Lấy Danh Sách Nhóm Của Tôi

**Endpoint:** `GET /groups`

**Công dụng:** Lấy tất cả nhóm mà user đã tham gia

**Response Success (200):**

```json
{
  "data": [
    {
      "id": "uuid-nhom",
      "name": "Nhóm đi chơi Đà Lạt",
      "description": "Chi tiêu chung",
      "invite_code": "ABC123",
      "members": [...],
      "created_at": "2025-12-28T10:00:00Z"
    }
  ]
}
```

---

## 3️⃣ Tham Gia Nhóm Bằng Mã Mời

**Endpoint:** `POST /groups/join`

**Công dụng:** Tham gia nhóm bằng invite code (6 ký tự)

**Request Body:**

```json
{
  "code": "ABC123"
}
```

**Response Success (200):**

```json
{
  "message": "Tham gia nhóm thành công!"
}
```

**Response Error (400):**

```json
{
  "error": "mã nhóm không tồn tại"
}
```

---

## 4️⃣ Tạo Chi Tiêu Trong Nhóm

**Endpoint:** `POST /groups/expenses`

**Công dụng:** Tạo chi tiêu mới, tự động chia tiền cho TẤT CẢ thành viên trong nhóm

**Request Body:**

```json
{
  "group_id": "uuid-nhom",
  "amount": 1000000,
  "description": "Ăn hải sản",
  "image_url": "https://link-to-bill.jpg",
  "payer_id": "uuid-nguoi-tra-tien"
}
```

**Logic:**

- Server tự động lấy tất cả members trong group
- Chia đều tiền cho tất cả (1000000 / số người)
- Tạo nợ cho từng người (trừ người trả tiền)

**Response Success (201):**

```json
{
  "message": "Đã thêm hóa đơn và tạo nợ thành công!"
}
```

**Response Error (500):**

```json
{
  "error": "nhóm cần ít nhất 2 người để chia tiền"
}
```

---

## 5️⃣ Xem Lịch Sử Chi Tiêu Của Nhóm

**Endpoint:** `GET /groups/:group_id/expenses`

**Công dụng:** Xem tất cả chi tiêu trong nhóm (có ảnh bill, danh sách nợ)

**Response Success (200):**

```json
{
  "data": [
    {
      "id": "uuid-expense",
      "group_id": "uuid-nhom",
      "payer_id": "uuid-nguoi-tra",
      "amount": 1000000,
      "description": "Ăn hải sản",
      "image_url": "https://link-to-bill.jpg",
      "debts": [
        {
          "id": "uuid-debt-1",
          "expense_id": "uuid-expense",
          "from_user_id": "uuid-nguoi-no",
          "to_user_id": "uuid-chu-no",
          "amount": 333333,
          "is_paid": false
        }
      ],
      "created_at": "2025-12-28T10:00:00Z"
    }
  ]
}
```

---

## 6️⃣ Xem Nợ Của Tôi

**Endpoint:** `GET /groups/:group_id/my-debts`

**Công dụng:** Xem tất cả khoản nợ tôi phải trả trong nhóm này

**Response Success (200):**

```json
{
  "data": [
    {
      "id": "uuid-debt",
      "expense_id": "uuid-expense",
      "from_user_id": "uuid-toi",
      "to_user_id": "uuid-chu-no",
      "amount": 333333,
      "is_paid": false,
      "expense": {
        "description": "Ăn hải sản",
        "image_url": "https://...",
        "created_at": "2025-12-28T10:00:00Z"
      }
    }
  ]
}
```

---

## 7️⃣ Xem Ai Nợ Tôi

**Endpoint:** `GET /groups/:group_id/debts-to-me`

**Công dụng:** Xem tất cả khoản nợ người khác nợ tôi trong nhóm

**Response Success (200):**

```json
{
  "data": [
    {
      "id": "uuid-debt",
      "expense_id": "uuid-expense",
      "from_user_id": "uuid-con-no",
      "to_user_id": "uuid-toi",
      "amount": 333333,
      "is_paid": false,
      "expense": {
        "description": "Ăn hải sản",
        "created_at": "2025-12-28T10:00:00Z"
      }
    }
  ]
}
```

---

## 8️⃣ Đánh Dấu Đã Trả Nợ

**Endpoint:** `PUT /groups/debts/:debt_id/paid`

**Công dụng:** Chủ nợ xác nhận con nợ đã trả tiền (đánh dấu `is_paid = true`)

**Request:** Không cần body

**Response Success (200):**

```json
{
  "message": "Đã xác nhận thanh toán!"
}
```

**Response Error (400):**

```json
{
  "error": "bạn không phải chủ nợ, không có quyền xác nhận"
}
```

---

## 📊 Data Models

### Group

```typescript
{
  id: string (uuid)
  name: string
  description: string
  invite_code: string (6 ký tự)
  members: GroupMember[]
  expenses: Expense[]
  created_at: datetime
  updated_at: datetime
}
```

### GroupMember

```typescript
{
  id: string(uuid);
  group_id: string(uuid);
  user_id: string(uuid);
  role: "leader" | "member";
  created_at: datetime;
}
```

### Expense

```typescript
{
  id: string (uuid)
  group_id: string (uuid)
  payer_id: string (uuid)
  amount: number (float)
  description: string
  image_url: string (optional)
  debts: Debt[]
  created_at: datetime
}
```

### Debt

```typescript
{
  id: string(uuid);
  expense_id: string(uuid);
  from_user_id: string(uuid); // Người nợ
  to_user_id: string(uuid); // Chủ nợ
  amount: number(float);
  is_paid: boolean;
  created_at: datetime;
}
```

---

## 🔄 Workflow Tiêu Biểu

### 1. Tạo nhóm và mời bạn:

```
1. User A tạo nhóm → Nhận invite_code
2. User A share code cho User B
3. User B gọi /groups/join với code
```

### 2. Chia tiền trong nhóm:

```
1. User A đi ăn, trả 1,000,000đ
2. User A gọi POST /groups/expenses (payer_id = A)
3. Server tự động:
   - Tính: 1,000,000 / 3 người = 333,333đ/người
   - Tạo nợ: User B nợ A 333,333đ
   - Tạo nợ: User C nợ A 333,333đ
```

### 3. Xác nhận thanh toán:

```
1. User B chuyển tiền cho User A ngoài app
2. User A gọi PUT /groups/debts/{debt_id}/paid
3. Khoản nợ của B được đánh dấu is_paid = true
```

---

## 📝 Notes

- **Invite Code:** Mã 6 ký tự tự động sinh khi tạo nhóm
- **Auto Split:** Server tự động chia đều cho tất cả members
- **Permission:** Chỉ chủ nợ mới được xác nhận thanh toán
- **Image Optional:** Có thể upload ảnh bill hoặc để trống
- **Debt Tracking:** Mỗi expense tạo ra nhiều debt records
