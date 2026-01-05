# MoneyPod - Ứng dụng Quản lý Chi tiêu Nhóm

<div align="center">
  <img src="app/assets/icons/base_app_icon.png" alt="MoneyPod Logo" width="120" height="120" />
  
  [![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
  [![Go](https://img.shields.io/badge/Go-1.x-00ADD8?logo=go)](https://golang.org)
  [![Firebase](https://img.shields.io/badge/Firebase-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
  [![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?logo=postgresql&logoColor=white)](https://www.postgresql.org)
</div>

## 📖 Giới thiệu

**MoneyPod** là ứng dụng di động toàn diện giúp quản lý chi tiêu cá nhân và nhóm một cách thông minh, tiện lợi. Ứng dụng cho phép người dùng theo dõi thu chi, quản lý ví tiền, chia sẻ chi phí trong nhóm, và thanh toán nợ một cách tự động và minh bạch.

### ✨ Tính năng chính

#### 💰 Quản lý Tài chính Cá nhân

- **Quản lý Ví đa dạng**: Tạo và theo dõi nhiều ví (tiền mặt, ngân hàng, thẻ tín dụng)
- **Ghi chú Thu/Chi**: Ghi nhận giao dịch nhanh chóng với phân loại chi tiết
- **Thống kê Trực quan**: Biểu đồ phân tích chi tiêu theo danh mục, thời gian
- **Tiết kiệm Mục tiêu**: Đặt và theo dõi các mục tiêu tiết kiệm

#### 👥 Chi tiêu Nhóm

- **Tạo Nhóm Chi tiêu**: Quản lý chi phí chung với bạn bè, gia đình
- **Chia tách Chi phí Tự động**: Tính toán phần chia cho từng thành viên
- **Sổ Nợ Thông minh**: Theo dõi ai nợ ai, bao nhiêu
- **Thanh toán Trực tuyến**: Xác nhận thanh toán với hình ảnh minh chứng

#### 🔔 Thông báo & Nhắc nhở

- **Push Notification**: Nhận thông báo khi có chi tiêu mới, nhắc nợ
- **Lịch sử Giao dịch**: Xem lại toàn bộ lịch sử chi tiêu nhóm
- **Tối ưu hoá Hiệu suất**: Giảm thiểu thông báo spam, xử lý hàng loạt

#### 🎤 Trợ lý Giọng nói (Voice Assistant)

- **Ghi chú Chi tiêu Bằng giọng nói**: Nói để ghi nhận giao dịch nhanh
- **Phân tích Ngữ cảnh**: AI hiểu và phân loại chi tiêu tự động
- **Đa ngôn ngữ**: Hỗ trợ tiếng Việt và tiếng Anh

---

## 🏗️ Kiến trúc Hệ thống

```
┌─────────────────────────────────────────────────────────────┐
│                      Flutter Mobile App                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   Screens    │  │     BLoC     │  │  Repositories │      │
│  │   (UI/UX)    │◄─┤ (State Mgmt) │◄─┤   (Data)     │      │
│  └──────────────┘  └──────────────┘  └──────┬───────┘      │
└────────────────────────────────────────────────┼────────────┘
                                                 │ HTTP/REST
┌────────────────────────────────────────────────┼────────────┐
│                    Go Backend Server            │            │
│  ┌──────────────┐  ┌──────────────┐  ┌────────▼───────┐    │
│  │   Handlers   │  │   Services   │  │  Repositories  │    │
│  │  (REST API)  │─►│  (Business)  │─►│   (Data)       │    │
│  └──────────────┘  └──────┬───────┘  └────────┬───────┘    │
│                            │                   │             │
│                    ┌───────▼───────┐  ┌────────▼────────┐   │
│                    │  Firebase FCM │  │   PostgreSQL    │   │
│                    │ (Push Notif)  │  │   (Database)    │   │
│                    └───────────────┘  └─────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

---

## 🛠️ Công nghệ sử dụng

### Frontend (Mobile App)

- **Framework**: Flutter 3.x (Dart)
- **State Management**: BLoC Pattern
- **Routing**: go_router
- **UI Components**: Material Design 3, Custom Widgets
- **Charts**: fl_chart
- **Voice Recognition**: speech_to_text
- **Image Handling**: image_picker, image_cropper
- **Secure Storage**: flutter_secure_storage
- **Firebase**: firebase_auth, firebase_messaging

### Backend (Server)

- **Language**: Go 1.x
- **Framework**: Gin (HTTP Router)
- **Database**: PostgreSQL + GORM (ORM)
- **Authentication**: Firebase Admin SDK
- **Push Notifications**: Firebase Cloud Messaging (FCM)
- **Architecture**: Clean Architecture (Handler → Service → Repository)

### DevOps & Tools

- **Version Control**: Git
- **Container**: Docker (docker-compose)
- **Database Migration**: SQL scripts
- **API Testing**: Postman/curl

---

## 📂 Cấu trúc Thư mục

```
moneypod_app/
├── app/                          # Flutter Mobile Application
│   ├── lib/
│   │   ├── main.dart            # Entry point
│   │   ├── bloc/                # BLoC state management
│   │   ├── config/              # App configuration, routes
│   │   ├── models/              # Data models (User, Group, Expense, etc.)
│   │   ├── repositories/        # Data layer (API calls)
│   │   ├── screens/             # UI screens (Groups, Profile, Wallets, etc.)
│   │   ├── services/            # Business logic services
│   │   ├── theme/               # App theme, colors, styles
│   │   ├── utils/               # Utilities, helpers
│   │   └── widgets/             # Reusable custom widgets
│   ├── android/                 # Android native code
│   ├── ios/                     # iOS native code
│   ├── assets/                  # Images, icons
│   └── pubspec.yaml             # Flutter dependencies
│
├── server/                       # Go Backend Server
│   ├── cmd/
│   │   └── server/
│   │       └── main.go          # Server entry point
│   ├── internal/
│   │   ├── config/              # Server configuration
│   │   ├── handlers/            # HTTP request handlers (REST API)
│   │   ├── middleware/          # Authentication, logging middleware
│   │   ├── models/              # Database models (User, Group, Debt, etc.)
│   │   ├── repositories/        # Database operations
│   │   ├── routes/              # API route definitions
│   │   └── services/            # Business logic (notifications, etc.)
│   ├── pkg/
│   │   ├── constants/           # Constants
│   │   ├── db/                  # Database connection
│   │   └── utils/               # Utility functions
│   ├── migrations/              # SQL migration scripts
│   ├── go.mod                   # Go dependencies
│   └── docker-compose.yml       # Docker configuration
│
├── README.md                     # Project documentation (this file)
├── VOICE_ASSISTANT_*.md         # Voice assistant documentation
└── *.md                         # Other documentation files
```

---

## 🚀 Hướng dẫn Cài đặt

### Yêu cầu Hệ thống

#### Frontend

- Flutter SDK 3.0.0 trở lên
- Dart SDK 3.0.0 trở lên
- Android Studio / Xcode (cho build mobile)
- Thiết bị Android (API 21+) hoặc iOS (12.0+)

#### Backend

- Go 1.19 trở lên
- PostgreSQL 14 trở lên
- Firebase project với Admin SDK credentials

---

### 📱 Cài đặt Frontend (Flutter App)

#### 1. Clone repository

```bash
cd moneypod_app/app
```

#### 2. Cài đặt dependencies

```bash
flutter pub get
```

#### 3. Cấu hình Firebase

- Tải file `google-services.json` từ Firebase Console
- Đặt vào `app/android/app/`
- Tải file `GoogleService-Info.plist` cho iOS
- Đặt vào `app/ios/Runner/`

#### 4. Chạy ứng dụng

```bash
# Chạy trên emulator/device
flutter run

# Build APK (Android)
flutter build apk --release

# Build IPA (iOS)
flutter build ios --release
```

---

### ⚙️ Cài đặt Backend (Go Server)

#### 1. Cấu hình Database

```bash
# Tạo database PostgreSQL
createdb moneypod

# Chạy migrations (nếu có)
psql -U postgres -d moneypod -f server/migrations/init.sql
```

#### 2. Cấu hình Firebase Admin SDK

- Tải file `serviceAccountKey.json` từ Firebase Console
- Đặt vào `server/` directory

#### 3. Cài đặt dependencies

```bash
cd server
go mod download
```

#### 4. Chạy server

```bash
# Development mode
go run cmd/server/main.go

# Build và chạy
go build -o bin/server cmd/server/main.go
./bin/server
```

#### 5. Sử dụng Docker (Optional)

```bash
cd server
docker-compose up -d
```

**Server sẽ chạy tại**: `http://localhost:8080`

---

## 📋 Cấu hình Môi trường

### Backend Environment Variables

Tạo file `.env` trong `server/`:

```env
# Database
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=your_password
DB_NAME=moneypod

# Server
PORT=8080
GIN_MODE=release

# Firebase
FIREBASE_CREDENTIALS_PATH=./serviceAccountKey.json

# JWT
JWT_SECRET=your-secret-key
```

### Frontend Configuration

Cập nhật `app/lib/config/` với:

- API base URL
- Firebase configuration
- Other app settings

---

## 🧪 Testing

### Frontend (Flutter)

```bash
cd app
flutter test
```

### Backend (Go)

```bash
cd server
go test ./...
```

---

## 📱 Hướng dẫn Sử dụng

### 1. Đăng ký / Đăng nhập

- Sử dụng email/password hoặc số điện thoại
- Xác thực qua Firebase Authentication

### 2. Quản lý Ví

- Vào tab "Ví" → Nhấn "+" để tạo ví mới
- Chọn loại ví: Tiền mặt, Ngân hàng, Thẻ tín dụng
- Nhập số dư ban đầu

### 3. Ghi chú Chi tiêu

- Nhấn nút "+" trên màn hình chính
- Chọn loại: Thu nhập / Chi tiêu
- Chọn danh mục, nhập số tiền, ghi chú
- Hoặc dùng Voice Assistant để ghi bằng giọng nói

### 4. Tạo Nhóm Chi tiêu

- Vào tab "Nhóm" → Nhấn "+"
- Nhập tên nhóm, mô tả
- Mời thành viên bằng mã mời hoặc số điện thoại

### 5. Thêm Chi tiêu Nhóm

- Vào nhóm → Nhấn FAB (+) màu tròn
- Nhập chi tiêu, chọn người chia
- Hệ thống tự động tính nợ cho từng người

### 6. Thanh toán Nợ

- Vào "Sổ nợ" trong nhóm
- Chọn khoản nợ cần trả
- Chọn ví thanh toán, thêm ghi chú/hình ảnh
- Chờ người nhận xác nhận

---

## 🔧 API Endpoints (Backend)

### Authentication

- `POST /api/auth/register` - Đăng ký tài khoản
- `POST /api/auth/login` - Đăng nhập
- `POST /api/auth/verify` - Xác thực token

### Users

- `GET /api/users/profile` - Lấy thông tin profile
- `PUT /api/users/profile` - Cập nhật profile
- `POST /api/users/avatar` - Upload avatar

### Groups

- `GET /api/groups` - Danh sách nhóm
- `POST /api/groups` - Tạo nhóm mới
- `GET /api/groups/:id` - Chi tiết nhóm
- `DELETE /api/groups/:id` - Xóa nhóm
- `POST /api/groups/:id/members` - Thêm thành viên
- `DELETE /api/groups/:id/members/:userId` - Xóa thành viên

### Expenses

- `POST /api/groups/:id/expenses` - Thêm chi tiêu
- `GET /api/groups/:id/expenses` - Lịch sử chi tiêu

### Debts

- `GET /api/groups/:id/debts/mine` - Nợ của tôi
- `GET /api/groups/:id/debts/to-me` - Người nợ tôi
- `POST /api/debts/:id/pay` - Thanh toán nợ
- `POST /api/debts/:id/confirm` - Xác nhận đã nhận tiền

### Wallets

- `GET /api/wallets` - Danh sách ví
- `POST /api/wallets` - Tạo ví mới
- `PUT /api/wallets/:id` - Cập nhật ví
- `DELETE /api/wallets/:id` - Xóa ví

### Notifications

- `POST /api/fcm/register` - Đăng ký FCM token
- `GET /api/notifications` - Lấy danh sách thông báo

---

## 🎨 Screenshots

<div align="center">
  <img src="docs/screenshots/home.png" width="200" alt="Home Screen" />
  <img src="docs/screenshots/groups.png" width="200" alt="Groups Screen" />
  <img src="docs/screenshots/expenses.png" width="200" alt="Expenses Screen" />
  <img src="docs/screenshots/profile.png" width="200" alt="Profile Screen" />
</div>

---

## 🐛 Troubleshooting

### Lỗi Build Flutter

```bash
flutter clean
flutter pub get
flutter run
```

### Lỗi Firebase

- Kiểm tra file `google-services.json` đã đúng chưa
- Verify Firebase project configuration
- Đảm bảo SHA-1 fingerprint đã được thêm vào Firebase Console

### Lỗi Backend Database

```bash
# Kiểm tra PostgreSQL đang chạy
psql -U postgres -l

# Test connection
psql -U postgres -d moneypod -c "SELECT 1;"
```

### Lỗi Notification không gửi được

- Kiểm tra FCM token đã đăng ký chưa
- Verify `serviceAccountKey.json` hợp lệ
- Đảm bảo device có kết nối internet

---

## 🤝 Đóng góp

Chúng tôi luôn chào đón mọi đóng góp từ cộng đồng!

### Quy trình đóng góp:

1. Fork repository
2. Tạo branch mới (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Mở Pull Request

### Coding Guidelines:

- **Flutter**: Tuân theo [Effective Dart](https://dart.dev/guides/language/effective-dart)
- **Go**: Tuân theo [Go Code Review Comments](https://github.com/golang/go/wiki/CodeReviewComments)
- Viết comment bằng tiếng Việt hoặc tiếng Anh
- Đảm bảo code pass tất cả tests trước khi commit

---

## 📄 License

Dự án này được phát triển cho mục đích học tập và nghiên cứu tại **HUTECH**.

---

## 👨‍💻 Tác giả

**HUTECH Development Team**

- 📧 Email: support@moneypod.app
- 🌐 Website: [moneypod.app](https://moneypod.app)
- 📱 Facebook: [@moneypodapp](https://facebook.com/moneypodapp)

---

## 🙏 Acknowledgments

- [Flutter Team](https://flutter.dev) - Awesome mobile framework
- [Go Team](https://golang.org) - Powerful backend language
- [Firebase](https://firebase.google.com) - Authentication & Cloud Messaging
- [PostgreSQL](https://www.postgresql.org) - Reliable database
- [HUTECH University](https://hutech.edu.vn) - Educational support

---

<div align="center">
  <b>⭐ Nếu bạn thấy project hữu ích, hãy cho chúng tôi một ngôi sao! ⭐</b>
  
  Made with ❤️ by HUTECH Team
</div>
