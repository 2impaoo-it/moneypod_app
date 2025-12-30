# MoneyPod API - New Features Documentation

## Tổng quan
Document này liệt kê tất cả các API mới đã được thêm vào MoneyPod server để hoàn thiện chức năng quản lý tài chính cá nhân và nhóm.

---

## 1. WALLET & TRANSACTION APIs

### 1.1. Cập nhật Ví
**Endpoint:** `PUT /api/v1/wallets/:id`  
**Authentication:** Required  
**Description:** Cập nhật tên ví và loại tiền tệ

**Request Body:**
```json
{
  "name": "Ví Vietcombank",
  "currency": "VND"
}
```

**Response:**
```json
{
  "message": "Cập nhật ví thành công!"
}
```

**Business Logic:**
- Chỉ chủ sở hữu ví mới có quyền cập nhật
- Có thể cập nhật tên hoặc currency riêng lẻ

---

### 1.2. Xóa Ví
**Endpoint:** `DELETE /api/v1/wallets/:id`  
**Authentication:** Required  
**Description:** Xóa ví (chỉ khi số dư = 0 và không có lịch sử giao dịch)

**Response:**
```json
{
  "message": "Xóa ví thành công!"
}
```

**Business Logic:**
- Chỉ xóa được khi số dư = 0
- Không cho xóa nếu ví đã có lịch sử giao dịch
- Chỉ chủ sở hữu mới xóa được

---

### 1.3. Cập nhật Giao dịch
**Endpoint:** `PUT /api/v1/transactions/:id`  
**Authentication:** Required  
**Description:** Sửa giao dịch với tính toán lại số dư ví

**Request Body:**
```json
{
  "amount": 500000,
  "category": "Ăn uống",
  "type": "expense",
  "note": "Nhập sai thành 50k"
}
```

**Response:**
```json
{
  "message": "Cập nhật giao dịch thành công!"
}
```

**Business Logic:**
- Hoàn lại số dư cũ trước
- Áp dụng số tiền mới
- Tính toán lại số dư ví
- Kiểm tra số dư có đủ không

---

### 1.4. Xóa Giao dịch
**Endpoint:** `DELETE /api/v1/transactions/:id`  
**Authentication:** Required  
**Description:** Xóa giao dịch và hoàn lại tiền vào ví

**Response:**
```json
{
  "message": "Xóa giao dịch thành công!"
}
```

**Business Logic:**
- Hoàn lại tiền vào ví tự động
- Chỉ chủ sở hữu mới xóa được

---

### 1.5. Lấy Giao dịch với Filter & Pagination
**Endpoint:** `GET /api/v1/transactions`  
**Authentication:** Required  
**Description:** Lấy danh sách giao dịch với filter và phân trang

**Query Parameters:**
- `category` (optional): Lọc theo category
- `type` (optional): income hoặc expense
- `month` (optional): Lọc theo tháng (1-12)
- `year` (optional): Lọc theo năm
- `page` (optional): Số trang (default: 1)
- `page_size` (optional): Số item/trang (default: 20)

**Example:** `GET /api/v1/transactions?category=Ăn uống&type=expense&month=12&year=2024&page=1&page_size=20`

**Response:**
```json
{
  "data": [...],
  "total": 150,
  "page": 1,
  "page_size": 20
}
```

---

## 2. GROUP MANAGEMENT APIs

### 2.1. Cập nhật Nhóm
**Endpoint:** `PUT /api/v1/groups/:id`  
**Authentication:** Required  
**Description:** Cập nhật tên nhóm, mô tả (Chỉ Leader)

**Request Body:**
```json
{
  "name": "Du lịch Đà Lạt 2025",
  "description": "Nhóm chi tiêu chuyến đi Đà Lạt"
}
```

**Response:**
```json
{
  "message": "Cập nhật nhóm thành công!"
}
```

**Business Logic:**
- Chỉ Leader mới được cập nhật
- Trả về 403 nếu không phải Leader

---

### 2.2. Kick Thành viên
**Endpoint:** `DELETE /api/v1/groups/:id/members/:user_id`  
**Authentication:** Required  
**Description:** Leader xóa thành viên ra khỏi nhóm

**Response:**
```json
{
  "message": "Đã xóa thành viên khỏi nhóm!"
}
```

**Business Logic:**
- Chỉ Leader mới được kick
- Không thể kick nếu member còn nợ ai
- Không thể kick nếu có ai nợ member đó
- Leader không thể kick chính mình

---

### 2.3. Rời Nhóm
**Endpoint:** `POST /api/v1/groups/:id/leave`  
**Authentication:** Required  
**Description:** Thành viên tự rời nhóm

**Response:**
```json
{
  "message": "Bạn đã rời nhóm thành công!"
}
```

**Business Logic:**
- Leader không thể rời nhóm (phải xóa nhóm hoặc chuyển quyền)
- Không thể rời nếu còn nợ ai
- Không thể rời nếu có ai nợ mình

---

## 3. EXPENSE MANAGEMENT APIs

### 3.1. Xem Chi tiết Hóa đơn
**Endpoint:** `GET /api/v1/groups/expenses/:expense_id`  
**Authentication:** Required  
**Description:** Xem chi tiết một hóa đơn (ai trả, ai nợ bao nhiêu)

**Response:**
```json
{
  "data": {
    "id": "...",
    "amount": 500000,
    "description": "Ăn lẩu",
    "payer_id": "...",
    "debts": [
      {
        "from_user_id": "...",
        "to_user_id": "...",
        "amount": 100000,
        "is_paid": false
      }
    ]
  }
}
```

---

### 3.2. Xóa Hóa đơn
**Endpoint:** `DELETE /api/v1/groups/expenses/:expense_id`  
**Authentication:** Required  
**Description:** Xóa hóa đơn (xóa luôn các khoản nợ liên quan)

**Response:**
```json
{
  "message": "Đã xóa hóa đơn thành công!"
}
```

**Business Logic:**
- Chỉ Payer hoặc Leader mới xóa được
- Xóa tất cả debts liên quan

---

### 3.3. Sửa Hóa đơn
**Endpoint:** `PUT /api/v1/groups/expenses/:expense_id`  
**Authentication:** Required  
**Description:** Cập nhật hóa đơn (amount, description, split details)

**Request Body:**
```json
{
  "amount": 600000,
  "description": "Ăn lẩu (cập nhật)",
  "split_details": [
    {"user_id": "...", "amount": 150000},
    {"user_id": "...", "amount": 150000}
  ]
}
```

**Response:**
```json
{
  "message": "Cập nhật hóa đơn thành công!"
}
```

**Business Logic:**
- Chỉ Payer hoặc Leader mới sửa được
- Nếu có split_details mới, xóa debts cũ và tạo lại

---

## 4. SAVINGS GOAL APIs

### 4.1. Cập nhật Mục tiêu
**Endpoint:** `PUT /api/v1/savings/:id`  
**Authentication:** Required  
**Description:** Sửa mục tiêu (tên, màu, target, deadline)

**Request Body:**
```json
{
  "name": "Mua iPhone 16",
  "color": "#FF5733",
  "icon": "phone",
  "target_amount": 30000000,
  "deadline": "2025-12-31T00:00:00Z"
}
```

**Response:**
```json
{
  "message": "Cập nhật mục tiêu thành công!"
}
```

---

### 4.2. Xóa Mục tiêu
**Endpoint:** `DELETE /api/v1/savings/:id`  
**Authentication:** Required  
**Description:** Xóa mục tiêu (phải rút hết tiền trước)

**Response:**
```json
{
  "message": "Xóa mục tiêu thành công!"
}
```

**Business Logic:**
- Phải rút hết tiền (current_amount = 0)
- Xóa luôn lịch sử giao dịch

---

### 4.3. Lịch sử Nạp/Rút
**Endpoint:** `GET /api/v1/savings/:id/transactions`  
**Authentication:** Required  
**Description:** Xem lịch sử nạp/rút của một mục tiêu

**Response:**
```json
{
  "data": [
    {
      "id": "...",
      "goal_id": "...",
      "wallet_id": "...",
      "amount": 500000,
      "type": "DEPOSIT",
      "note": "Nạp tiền tiết kiệm",
      "created_at": "2024-12-30T..."
    }
  ]
}
```

---

## 5. USER & AUTH APIs

### 5.1. Đổi Mật khẩu
**Endpoint:** `PUT /api/v1/change-password`  
**Authentication:** Required  
**Description:** Đổi mật khẩu (yêu cầu mật khẩu cũ)

**Request Body:**
```json
{
  "old_password": "oldpass123",
  "new_password": "newpass456"
}
```

**Response:**
```json
{
  "message": "Đổi mật khẩu thành công!"
}
```

**Business Logic:**
- Phải nhập đúng mật khẩu cũ
- Mật khẩu mới ≥ 6 ký tự

---

### 5.2. Quên Mật khẩu
**Endpoint:** `POST /api/v1/forgot-password`  
**Authentication:** Not Required (Public)  
**Description:** Reset mật khẩu qua email (simplified version)

**Request Body:**
```json
{
  "email": "user@example.com"
}
```

**Response:**
```json
{
  "message": "Nếu email tồn tại, một email khôi phục mật khẩu đã được gửi đến hộp thư của bạn"
}
```

**Note:**
- Version hiện tại: Reset về password mặc định và log ra console
- Production: Nên gửi email với reset link chứa token

---

## 6. DEBT PAYMENT REQUEST/CONFIRMATION SYSTEM (NEW!)

### 6.1. Gửi Request Trả Nợ
**Endpoint:** `POST /api/v1/groups/debts/:debt_id/payment-request`  
**Authentication:** Required  
**Description:** Người nợ gửi request thông báo đã trả nợ

**Request Body:**
```json
{
  "payment_wallet_id": "uuid-wallet-id",
  "note": "Đã chuyển khoản lúc 15:30"
}
```

**Response:**
```json
{
  "message": "Đã gửi yêu cầu xác nhận thanh toán!"
}
```

**Business Logic:**
- Chỉ người nợ (FromUserID) mới gửi được
- Kiểm tra số dư ví có đủ không
- Một debt chỉ có 1 request PENDING tại một thời điểm
- Gửi notification cho chủ nợ

---

### 6.2. Lấy Danh sách Request Chờ Xác nhận
**Endpoint:** `GET /api/v1/groups/payment-requests`  
**Authentication:** Required  
**Description:** Chủ nợ xem các request trả nợ đang chờ

**Response:**
```json
{
  "data": [
    {
      "id": "request-id",
      "debt_id": "debt-id",
      "from_user_id": "người nợ",
      "to_user_id": "chủ nợ (mình)",
      "payment_wallet_id": "wallet người nợ dùng",
      "amount": 100000,
      "status": "PENDING",
      "note": "Đã chuyển khoản",
      "created_at": "..."
    }
  ]
}
```

---

### 6.3. Xác nhận Đã Nhận Tiền
**Endpoint:** `POST /api/v1/groups/payment-requests/:request_id/confirm`  
**Authentication:** Required  
**Description:** Chủ nợ xác nhận đã nhận tiền

**Request Body:**
```json
{
  "receive_wallet_id": "uuid-wallet-nhận-tiền"
}
```

**Response:**
```json
{
  "message": "Đã xác nhận thanh toán thành công!"
}
```

**Business Logic:**
- Chỉ chủ nợ (ToUserID) mới confirm được
- Kiểm tra lại số dư người nợ
- Thực hiện chuyển tiền:
  - Trừ tiền ví người nợ
  - Cộng tiền ví chủ nợ
- Đánh dấu debt.is_paid = true
- Cập nhật request.status = "CONFIRMED"
- Gửi notification cho người nợ

---

### 6.4. Từ chối Request
**Endpoint:** `POST /api/v1/groups/payment-requests/:request_id/reject`  
**Authentication:** Required  
**Description:** Chủ nợ từ chối xác nhận (chưa nhận được tiền)

**Request Body:**
```json
{
  "reason": "Chưa nhận được tiền"
}
```

**Response:**
```json
{
  "message": "Đã từ chối yêu cầu thanh toán!"
}
```

**Business Logic:**
- Chỉ chủ nợ mới reject được
- Cập nhật request.status = "REJECTED"
- Gửi notification cho người nợ kèm lý do

---

## Workflow Trả Nợ Mới

```
1. Người Nợ:
   - Bấm nút "Đã trả nợ"
   - Chọn ví dùng để trả
   - Hệ thống kiểm tra số dư
   - Tạo payment request (status: PENDING)
   
2. Chủ Nợ nhận notification:
   - Vào xem danh sách request chờ xác nhận
   - Kiểm tra có nhận được tiền chưa
   
3. Chủ Nợ có 2 lựa chọn:
   
   A. CONFIRM (Đã nhận tiền):
      - Chọn ví nhận tiền
      - Hệ thống trừ tiền người nợ
      - Hệ thống cộng tiền chủ nợ
      - Debt marked as paid
      - Cả 2 nhận notification
      
   B. REJECT (Chưa nhận):
      - Nhập lý do từ chối
      - Request marked as rejected
      - Người nợ nhận notification
      - Người nợ có thể gửi request mới
```

---

## Tổng kết Commits

1. **Wallet & Transaction CRUD**: 7 files, +426 insertions
2. **Group Management**: 3 files, +201 insertions
3. **Expense Management**: 3 files, +212 insertions
4. **Savings Goal Management**: 4 files, +214 insertions
5. **User & Auth (Password)**: 4 files, +130 insertions
6. **Debt Payment Request System**: 5 files, +370 insertions

**Tổng cộng:** ~1,553 dòng code mới được thêm vào!

---

## Notes cho Developer

- Tất cả endpoints đều đã được test logic business
- Có validation đầy đủ (balance check, ownership check, permission check)
- Có FCM notifications cho các actions quan trọng
- Database migration đã được cập nhật (debt_payment_requests table)
- Code đã được commit rõ ràng theo từng nhóm chức năng

---

Chúc bạn code vui vẻ! 🎉
