# 💰 MoneyPod Backend

API Backend cho ứng dụng quản lý tài chính cá nhân và nhóm MoneyPod, được xây dựng với Go, Gin Framework và PostgreSQL.

## 📋 Mô tả

MoneyPod là một ứng dụng quản lý tài chính cho phép người dùng:

- Quản lý tài khoản cá nhân
- Tạo và quản lý ví tiền
- Ghi chép các giao dịch thu/chi
- Tạo nhóm để quản lý chi tiêu chung
- Chia sẻ chi phí trong nhóm

## 🚀 Công nghệ sử dụng

- **Ngôn ngữ**: Go 1.25.5
- **Web Framework**: Gin (v1.11.0)
- **Database**: PostgreSQL 16
- **ORM**: GORM (v1.31.1)
- **Authentication**: JWT (golang-jwt/jwt v5.3.0)
- **Containerization**: Docker & Docker Compose

## 📁 Cấu trúc thư mục

```
MoneyPod_Backend/
├── cmd/
│   └── server/
│       └── main.go              # Entry point của ứng dụng
├── config/                      # Cấu hình ứng dụng
├── internal/
│   ├── handlers/               # HTTP request handlers
│   │   ├── auth_handle.go
│   │   ├── group_handle.go
│   │   ├── transaction_handler.go
│   │   └── wallet_handler.go
│   ├── middleware/             # Middleware (Auth, Logging, etc.)
│   │   └── auth_middleware.go
│   ├── models/                 # Database models
│   │   ├── expense.go
│   │   ├── groups.go
│   │   ├── transaction.go
│   │   ├── user.go
│   │   └── wallet.go
│   ├── repositories/           # Data access layer
│   │   ├── user_repo.go
│   │   └── wallet_repo.go
│   ├── routes/                 # Route definitions
│   │   └── router.go
│   └── services/               # Business logic
│       ├── auth_service.go
│       ├── group_service.go
│       ├── transaction_service.go
│       └── wallet_service.go
├── pkg/
│   └── db/
│       └── database.go         # Database connection
├── docker-compose.yml          # Docker Compose configuration
├── go.mod                      # Go module dependencies
└── README.md                   # Tài liệu này
```

## 🛠️ Cài đặt và Chạy

### Yêu cầu

- Go 1.25.5 trở lên
- Docker và Docker Compose
- PostgreSQL 16 (hoặc sử dụng Docker)

### Bước 1: Clone repository

```bash
git clone https://github.com/2impaoo-it/MoneyPod_Backend.git
cd MoneyPod_Backend
```

### Bước 2: Cài đặt dependencies

```bash
go mod download
```

### Bước 3: Khởi động Database với Docker

```bash
docker-compose up -d
```

Database sẽ chạy với các thông tin:

- **Host**: localhost
- **Port**: 5432
- **Database**: moneypod
- **User**: postgres
- **Password**: moneypod_secret

### Bước 4: Chạy ứng dụng

```bash
go run cmd/server/main.go
```

Server sẽ chạy tại: `http://localhost:8080`

## 📡 API Endpoints

### Public Endpoints (Không cần authentication)

#### Health Check

```http
GET /api/v1/ping
```

#### Đăng ký tài khoản

```http
POST /api/v1/register
Content-Type: application/json

{
  "username": "string",
  "email": "string",
  "password": "string"
}
```

#### Đăng nhập

```http
POST /api/v1/login
Content-Type: application/json

{
  "email": "string",
  "password": "string"
}
```

### Protected Endpoints (Yêu cầu JWT Token)

Thêm header: `Authorization: Bearer <token>`

#### Profile

```http
GET /api/v1/profile
```

#### Quản lý Ví

##### Tạo ví mới

```http
POST /api/v1/wallets
Content-Type: application/json

{
  "name": "string",
  "balance": number,
  "currency": "string"
}
```

##### Xem danh sách ví

```http
GET /api/v1/wallets
```

#### Quản lý Giao dịch

##### Tạo giao dịch

```http
POST /api/v1/transactions
Content-Type: application/json

{
  "wallet_id": number,
  "amount": number,
  "type": "income|expense",
  "category": "string",
  "description": "string"
}
```

##### Chuyển tiền giữa các ví

```http
POST /api/v1/transfer
Content-Type: application/json

{
  "from_wallet_id": number,
  "to_wallet_id": number,
  "amount": number,
  "description": "string"
}
```

#### Quản lý Nhóm

##### Tạo nhóm mới

```http
POST /api/v1/groups
Content-Type: application/json

{
  "name": "string",
  "description": "string"
}
```

##### Xem danh sách nhóm

```http
GET /api/v1/groups
```

##### Tham gia nhóm

```http
POST /api/v1/groups/join
Content-Type: application/json

{
  "group_id": number,
  "invite_code": "string"
}
```

##### Thêm chi phí cho nhóm

```http
POST /api/v1/groups/expenses
Content-Type: application/json

{
  "group_id": number,
  "amount": number,
  "description": "string",
  "paid_by": number
}
```

## 🏗️ Kiến trúc

Dự án sử dụng kiến trúc **Clean Architecture** với các layer:

1. **Handlers**: Xử lý HTTP requests và responses
2. **Services**: Chứa business logic
3. **Repositories**: Truy xuất dữ liệu từ database
4. **Models**: Định nghĩa cấu trúc dữ liệu

**Dependency Injection** được áp dụng để dễ dàng test và maintain.

## 🔐 Authentication

API sử dụng JWT (JSON Web Tokens) để xác thực:

1. Đăng nhập qua `/api/v1/login` để nhận token
2. Thêm token vào header: `Authorization: Bearer <your-token>`
3. Token sẽ được validate bởi `AuthMiddleware`

## 🗄️ Database Schema

Các bảng chính:

- **users**: Thông tin người dùng
- **wallets**: Ví tiền của người dùng
- **transactions**: Các giao dịch thu/chi
- **groups**: Nhóm quản lý chi phí chung
- **expenses**: Chi phí trong nhóm

## 🧪 Testing

```bash
go test ./...
```

## 📦 Build Production

```bash
go build -o moneypod cmd/server/main.go
./moneypod
```

## 🐳 Docker Deployment

Build và chạy toàn bộ stack với Docker:

```bash
docker-compose up --build
```

## 📝 TODO

- [ ] Thêm unit tests
- [ ] Implement rate limiting
- [ ] Thêm logging system
- [ ] Export báo cáo chi tiêu
- [ ] Notifications
- [ ] Multi-currency support

## 🤝 Contributing

1. Fork repository
2. Tạo branch mới (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Mở Pull Request

## 📄 License

Distributed under the MIT License.

## 👥 Author

**2impaoo-it**

## 📞 Contact

Project Link: [https://github.com/2impaoo-it/MoneyPod_Backend](https://github.com/2impaoo-it/MoneyPod_Backend)

---

⭐ Nếu project này hữu ích, hãy cho một star nhé!
