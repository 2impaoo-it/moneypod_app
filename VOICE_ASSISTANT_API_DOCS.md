# 🎤 Voice Assistant - API Documentation cho Flutter

## 📋 Tổng quan

Backend **ĐÃ CÓ ĐẦY ĐỦ** API cần thiết để implement Voice Assistant feature. Không cần thêm API mới.

Voice Assistant sẽ parse giọng nói thành command, sau đó gọi các API transaction hiện có.

---

## 🔗 Base URL

```
http://your-server:8080/api/v1
```

---

## 🔐 Authentication

**Tất cả API đều yêu cầu Bearer Token trong header:**

```
Authorization: Bearer <your_jwt_token>
```

---

## 📡 API Endpoints cho Voice Assistant

### 1️⃣ Thêm Giao dịch (Chi tiêu / Thu nhập)

**Use case:**

- ✅ "Chi 50 nghìn ăn sáng"
- ✅ "Thu nhập 5 triệu lương tháng 1"

#### Endpoint

```http
POST /transactions
```

#### Request Headers

```
Content-Type: application/json
Authorization: Bearer <token>
```

#### Request Body

```json
{
  "wallet_id": "uuid-của-ví",
  "amount": 50000,
  "category": "Ăn uống",
  "type": "expense", // hoặc "income"
  "note": "ăn sáng"
}
```

#### Request Body Schema

| Field       | Type        | Required | Validation                  | Description                         |
| ----------- | ----------- | -------- | --------------------------- | ----------------------------------- |
| `wallet_id` | UUID string | ✅       | Phải hợp lệ                 | ID của ví thực hiện giao dịch       |
| `amount`    | float64     | ✅       | > 0                         | Số tiền                             |
| `category`  | string      | ❌       | -                           | Danh mục (Ăn uống, Di chuyển, etc.) |
| `type`      | string      | ✅       | `"income"` hoặc `"expense"` | Loại giao dịch                      |
| `note`      | string      | ❌       | -                           | Ghi chú                             |

#### Success Response (201 Created)

```json
{
  "message": "Giao dịch thành công!"
}
```

#### Error Responses

**400 Bad Request:**

```json
{
  "error": "Amount must be greater than 0"
}
```

**401 Unauthorized:**

```json
{
  "error": "Token ID invalid"
}
```

**404 Not Found:**

```json
{
  "error": "Ví không tồn tại hoặc không thuộc về bạn"
}
```

---

### 2️⃣ Chuyển tiền giữa các ví

**Use case:**

- ✅ "Chuyển 500 nghìn từ ví tiền mặt sang ngân hàng"

#### Endpoint

```http
POST /wallets/transfer
```

#### Request Body

```json
{
  "from_wallet_id": "uuid-ví-nguồn",
  "to_wallet_id": "uuid-ví-đích",
  "amount": 500000,
  "note": "Chuyển tiền"
}
```

#### Request Body Schema

| Field            | Type        | Required | Validation             | Description    |
| ---------------- | ----------- | -------- | ---------------------- | -------------- |
| `from_wallet_id` | UUID string | ✅       | Phải thuộc user        | ID ví nguồn    |
| `to_wallet_id`   | UUID string | ✅       | Phải thuộc user        | ID ví đích     |
| `amount`         | float64     | ✅       | > 0, <= số dư ví nguồn | Số tiền chuyển |
| `note`           | string      | ❌       | -                      | Ghi chú        |

#### Success Response (200 OK)

```json
{
  "message": "Chuyển tiền thành công"
}
```

#### Error Responses

**400 Bad Request:**

```json
{
  "error": "Số dư ví không đủ để chuyển"
}
```

```json
{
  "error": "Không thể chuyển tiền cho chính mình"
}
```

---

### 3️⃣ Lấy danh sách ví (để user chọn ví)

**Dùng để:**

- Hiển thị danh sách ví cho user chọn trước khi tạo transaction
- Lấy default wallet
- Validate wallet_id trước khi gửi request

#### Endpoint

```http
GET /wallets
```

#### Success Response (200 OK)

```json
{
  "wallets": [
    {
      "id": "uuid-1",
      "name": "Tiền mặt",
      "balance": 1500000,
      "icon": "💵",
      "color": "#4CAF50",
      "is_default": true,
      "created_at": "2024-01-01T00:00:00Z",
      "updated_at": "2024-01-03T12:00:00Z"
    },
    {
      "id": "uuid-2",
      "name": "Ngân hàng",
      "balance": 5000000,
      "icon": "🏦",
      "color": "#2196F3",
      "is_default": false,
      "created_at": "2024-01-01T00:00:00Z",
      "updated_at": "2024-01-03T12:00:00Z"
    }
  ]
}
```

---

### 4️⃣ Lấy danh sách giao dịch (cho AI context)

**Dùng để:**

- Cung cấp context cho Gemini AI khi user hỏi về chi tiêu
- Hiển thị lịch sử giao dịch

#### Endpoint

```http
GET /transactions
```

#### Query Parameters

| Parameter   | Type   | Required | Description                  |
| ----------- | ------ | -------- | ---------------------------- |
| `wallet_id` | UUID   | ❌       | Filter theo ví               |
| `category`  | string | ❌       | Filter theo danh mục         |
| `type`      | string | ❌       | `"income"` hoặc `"expense"`  |
| `month`     | int    | ❌       | Tháng (1-12)                 |
| `year`      | int    | ❌       | Năm (2024, 2025, ...)        |
| `page`      | int    | ❌       | Số trang (default: 1)        |
| `page_size` | int    | ❌       | Số items/trang (default: 20) |

#### Example Request

```http
GET /transactions?type=expense&month=1&year=2024&page=1&page_size=10
```

#### Success Response (200 OK)

```json
{
  "transactions": [
    {
      "id": "uuid-trans-1",
      "wallet_id": "uuid-wallet-1",
      "amount": 50000,
      "category": "Ăn uống",
      "type": "expense",
      "note": "ăn sáng",
      "date": "2024-01-03T08:30:00Z",
      "proof_image": "",
      "wallet": {
        "id": "uuid-wallet-1",
        "name": "Tiền mặt",
        "icon": "💵"
      }
    }
  ],
  "total": 45,
  "page": 1,
  "page_size": 10
}
```

---

### 5️⃣ Lấy Insight tháng (cho AI context)

**Dùng để:**

- Cung cấp thống kê cho Gemini AI
- Trả lời câu hỏi: "Đánh giá chi tiêu tháng này"

#### Endpoint

```http
GET /insights/monthly
```

#### Query Parameters

| Parameter | Type | Required | Description                     |
| --------- | ---- | -------- | ------------------------------- |
| `month`   | int  | ❌       | Tháng (default: tháng hiện tại) |
| `year`    | int  | ❌       | Năm (default: năm hiện tại)     |

#### Success Response (200 OK)

```json
{
  "total_income": 10000000,
  "total_expense": 7500000,
  "balance": 2500000,
  "savings_rate": 25.0,
  "top_category": {
    "name": "Ăn uống",
    "amount": 3000000,
    "percentage": 40.0
  },
  "categories": [
    {
      "name": "Ăn uống",
      "amount": 3000000,
      "percentage": 40.0
    },
    {
      "name": "Di chuyển",
      "amount": 1500000,
      "percentage": 20.0
    }
  ],
  "comparison_with_last_month": {
    "income_change": 15.5,
    "expense_change": -10.2
  }
}
```

---

## 🎯 Flow Implementation cho Flutter

### Flow 1: Thêm giao dịch bằng giọng nói

```dart
// 1. User nói: "Chi 50 nghìn ăn sáng"
final voiceText = await voiceService.listen();

// 2. Parse command
final command = VoiceCommandParser.parse(voiceText);
// → command = VoiceCommand(type: 'expense', amount: 50000, category: 'Ăn uống', note: 'ăn sáng')

// 3. Lấy default wallet
final wallets = await walletRepository.getWallets();
final defaultWallet = wallets.firstWhere((w) => w.isDefault);

// 4. Show confirmation dialog
final confirmed = await showConfirmationDialog(command);

// 5. Nếu confirmed, gọi API
if (confirmed) {
  await transactionRepository.createTransaction(
    walletId: defaultWallet.id,
    amount: command.amount,
    category: command.category,
    type: command.type, // 'expense'
    note: command.note,
  );

  showSuccessNotification('Đã thêm chi tiêu 50,000đ');
}
```

### Flow 2: Chuyển tiền giữa ví

```dart
// 1. User nói: "Chuyển 500 nghìn từ tiền mặt sang ngân hàng"
final voiceText = await voiceService.listen();

// 2. Parse command
final command = VoiceCommandParser.parse(voiceText);
// → amount: 500000, fromWallet: 'tiền mặt', toWallet: 'ngân hàng'

// 3. Match wallet names với wallet IDs
final wallets = await walletRepository.getWallets();
final fromWallet = wallets.firstWhere((w) =>
  w.name.toLowerCase().contains('tiền mặt'));
final toWallet = wallets.firstWhere((w) =>
  w.name.toLowerCase().contains('ngân hàng'));

// 4. Confirm & execute
if (await showConfirmation(command)) {
  await walletRepository.transfer(
    fromWalletId: fromWallet.id,
    toWalletId: toWallet.id,
    amount: command.amount,
    note: 'Chuyển tiền',
  );
}
```

### Flow 3: AI trả lời câu hỏi (dùng Gemini)

```dart
// 1. User hỏi: "Tư vấn giúp tôi tiết kiệm"
final question = await voiceService.listen();

// 2. Lấy context data
final insight = await insightRepository.getMonthlyInsight();
final transactions = await transactionRepository.getTransactions(
  month: DateTime.now().month,
  year: DateTime.now().year,
);

// 3. Gửi lên Gemini
final aiResponse = await geminiService.ask(
  question: question,
  context: {
    'total_income': insight.totalIncome,
    'total_expense': insight.totalExpense,
    'top_category': insight.topCategory.name,
    'savings_rate': insight.savingsRate,
  },
);

// 4. Text-to-speech đọc response
await ttsService.speak(aiResponse);

// 5. Hiển thị text trong UI
showAIResponse(aiResponse);
```

---

## 🗂️ Category Mapping (cho NLP Parser)

### Expense Categories

```dart
final categoryKeywords = {
  'Ăn uống': ['ăn', 'uống', 'cơm', 'cafe', 'nhậu', 'bia', 'trà', 'nước'],
  'Di chuyển': ['xe', 'xăng', 'taxi', 'grab', 'bus', 'tàu', 'máy bay'],
  'Mua sắm': ['mua', 'quần', 'áo', 'giày', 'túi', 'đồ'],
  'Hóa đơn': ['điện', 'nước', 'internet', 'wifi', 'gas', 'rác'],
  'Sức khỏe': ['thuốc', 'bệnh viện', 'khám', 'bác sĩ'],
  'Giáo dục': ['học', 'sách', 'khóa học', 'trường'],
  'Giải trí': ['phim', 'game', 'du lịch', 'xem'],
};
```

### Income Categories

```dart
final incomeCategoryKeywords = {
  'Lương': ['lương', 'công'],
  'Thưởng': ['thưởng', 'bonus'],
  'Đầu tư': ['đầu tư', 'cổ tức', 'lãi'],
  'Bán hàng': ['bán', 'kinh doanh'],
  'Khác': ['khác', 'khác'],
};
```

---

## 🔢 Amount Parsing Examples

### Input → Parsed Amount

| Voice Input | Parsed Amount |
| ----------- | ------------- |
| "50 nghìn"  | 50,000        |
| "5 triệu"   | 5,000,000     |
| "2 triệu 5" | 2,500,000     |
| "1.5 triệu" | 1,500,000     |
| "500k"      | 500,000       |
| "100 ngàn"  | 100,000       |

### Regex Patterns

```dart
// Pattern 1: X triệu Y (e.g., "2 triệu 5" → 2,500,000)
final millionPattern = RegExp(r'(\d+(?:[,.]\d+)?)\s*triệu\s*(\d+)?');

// Pattern 2: X nghìn/k (e.g., "50 nghìn" → 50,000)
final thousandPattern = RegExp(r'(\d+(?:[,.]\d+)?)\s*(?:nghìn|ngàn|k)');

// Pattern 3: Plain number
final numberPattern = RegExp(r'(\d+(?:[,.]\d+)?)');
```

---

## 🧪 Test Cases

### Test Case 1: Chi tiêu đơn giản

**Input:** "Chi 50 nghìn ăn sáng"

**Expected Parse:**

```dart
VoiceCommand(
  type: 'expense',
  amount: 50000,
  category: 'Ăn uống',
  note: 'ăn sáng',
)
```

**API Call:**

```json
POST /transactions
{
  "wallet_id": "default-wallet-id",
  "amount": 50000,
  "category": "Ăn uống",
  "type": "expense",
  "note": "ăn sáng"
}
```

### Test Case 2: Thu nhập

**Input:** "Thu nhập 5 triệu lương tháng 1"

**Expected Parse:**

```dart
VoiceCommand(
  type: 'income',
  amount: 5000000,
  category: 'Lương',
  note: 'lương tháng 1',
)
```

**API Call:**

```json
POST /transactions
{
  "wallet_id": "default-wallet-id",
  "amount": 5000000,
  "category": "Lương",
  "type": "income",
  "note": "lương tháng 1"
}
```

### Test Case 3: Chuyển tiền

**Input:** "Chuyển 500 nghìn từ tiền mặt sang ngân hàng"

**Expected Parse:**

```dart
VoiceCommand(
  type: 'transfer',
  amount: 500000,
  fromWallet: 'tiền mặt',
  toWallet: 'ngân hàng',
)
```

**API Call:**

```json
POST /wallets/transfer
{
  "from_wallet_id": "wallet-tien-mat-id",
  "to_wallet_id": "wallet-ngan-hang-id",
  "amount": 500000,
  "note": "Chuyển tiền"
}
```

---

## ⚠️ Error Handling

### Common Errors & Solutions

#### 1. Ví không tồn tại

**Error Response:**

```json
{
  "error": "Ví không tồn tại hoặc không thuộc về bạn"
}
```

**Solution:**

- Kiểm tra lại `wallet_id` có đúng không
- Gọi `GET /wallets` để lấy danh sách ví hợp lệ

#### 2. Số dư không đủ

**Error Response:**

```json
{
  "error": "Số dư ví không đủ"
}
```

**Solution:**

- Hiển thị warning cho user
- Suggest chọn ví khác có đủ số dư

#### 3. Parse lỗi

**Trường hợp:**

- User nói không rõ
- Số tiền parse sai
- Không detect được type

**Solution:**

- Show dialog yêu cầu user nhập lại
- Hoặc show form để user điền thủ công

#### 4. Token hết hạn

**Error Response:**

```json
{
  "error": "Token expired"
}
```

**Solution:**

- Redirect về login screen
- Hoặc refresh token tự động

---

## 📊 API Response Codes Summary

| Status Code | Meaning      | Example                      |
| ----------- | ------------ | ---------------------------- |
| 200         | Success      | GET requests                 |
| 201         | Created      | POST transaction success     |
| 400         | Bad Request  | Invalid input data           |
| 401         | Unauthorized | Token missing/invalid        |
| 404         | Not Found    | Wallet/transaction not found |
| 500         | Server Error | Database error               |

---

## 🚀 Quick Start Checklist

- [ ] Đã có Bearer Token (JWT)
- [ ] Đã test API với Postman/cURL
- [ ] Đã lấy được danh sách wallets
- [ ] Đã hiểu flow parse voice → API call
- [ ] Đã implement error handling
- [ ] Đã có Gemini API key (cho AI feature)

---

## 📞 Support

Nếu có vấn đề về API:

1. Check logs server
2. Verify JWT token còn hạn
3. Kiểm tra request body format
4. Test với Postman trước khi code Flutter

---

**Backend sẵn sàng! Giờ Flutter team có thể bắt đầu implement Voice Assistant 🎉**
