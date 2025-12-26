# Hướng dẫn tính năng Quét Bill - MoneyPod

## 📋 Tổng quan

Tính năng quét bill cho phép người dùng:
1. **Flutter App**: Chụp/chọn ảnh hóa đơn và gửi lên server
2. **Server**: Nhận ảnh từ app (TODO: Tích hợp AI để phân tích)

## 🏗️ Kiến trúc

### Flutter App (Client)
```
User bấm "Quét Bill"
    ↓
Chụp ảnh hoặc chọn từ thư viện
    ↓
Gửi ảnh lên server (POST /api/v1/bills/scan)
    ↓
Nhận kết quả JSON từ server
    ↓
Hiển thị thông tin bill
```

### Go Server (Backend)
```
Nhận request với ảnh
    ↓
Validate file (size, format)
    ↓
TODO: Gọi AI (Gemini) để phân tích
    ↓
Trả về JSON response
```

## 📱 Flutter App Setup

### 1. Dependencies đã cài
```yaml
dependencies:
  camera: ^0.10.5+9              # Camera access
  image_picker: ^1.0.7           # Pick images
  permission_handler: ^11.2.0    # Permissions
  http: ^1.6.0                   # HTTP requests
```

### 2. Permissions đã cấu hình

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
```

**iOS** (`ios/Runner/Info.plist`):
```xml
<key>NSCameraUsageDescription</key>
<string>Ứng dụng cần quyền truy cập camera để quét hóa đơn</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Ứng dụng cần quyền truy cập thư viện ảnh để chọn hóa đơn</string>
```

### 3. Cấu hình Server URL

File: `lib/repositories/bill_scan_repository.dart`
```dart
static const String _baseUrl = 'http://localhost:8080/api/v1';
```

**Đổi URL theo môi trường:**
- Local: `http://localhost:8080/api/v1`
- Android Emulator: `http://10.0.2.2:8080/api/v1`
- iOS Simulator: `http://localhost:8080/api/v1`
- Device thật: `http://<IP_máy_tính>:8080/api/v1`

## 🖥️ Server Setup

### 1. Cấu trúc Server
```
server/
├── internal/
│   ├── handlers/
│   │   └── bill_scan_handler.go  ✅ Nhận ảnh, trả mock data
│   └── routes/
│       └── router.go              ✅ Đăng ký endpoint
```

### 2. API Endpoint

**POST** `/api/v1/bills/scan`

**Request:**
- Content-Type: `multipart/form-data`
- Body: 
  - `image`: File (JPG/JPEG/PNG, max 10MB)

**Response (Success):**
```json
{
  "success": true,
  "data": {
    "merchant": "Highlands Coffee",
    "amount": 59000,
    "date": "2023-10-25",
    "category": "Ăn uống",
    "note": "Mock data - chưa tích hợp AI"
  },
  "message": "Nhận ảnh thành công. Tích hợp AI đang trong quá trình phát triển."
}
```

**Response (Error):**
```json
{
  "error": "Không tìm thấy file ảnh trong request"
}
```

### 3. Chạy Server

```bash
cd server
go run cmd/server/main.go
```

Server sẽ chạy tại: `http://localhost:8080`

## 🚀 Testing

### Test với Flutter App

1. Chạy server:
```bash
cd server
go run cmd/server/main.go
```

2. Chạy Flutter app:
```bash
cd app
flutter run
```

3. Trong app:
   - Bấm "Quét Bill" ở Dashboard
   - Chụp ảnh hoặc chọn từ thư viện
   - App sẽ gửi ảnh lên server
   - Server trả về mock data
   - App hiển thị kết quả

### Test với cURL

```bash
curl -X POST http://localhost:8080/api/v1/bills/scan \
  -F "image=@/path/to/bill.jpg"
```

### Test với Postman

1. Method: POST
2. URL: `http://localhost:8080/api/v1/bills/scan`
3. Body → form-data
4. Key: `image` (type: File)
5. Value: Chọn file ảnh

## 📝 TODO - Tích hợp AI

### Các bước để thêm Gemini AI:

1. **Lấy API Key:**
   - Truy cập: https://makersuite.google.com/app/apikey
   - Tạo API key
   - Lưu vào environment variable: `GEMINI_API_KEY`

2. **Cài đặt dependencies** (nếu cần):
```bash
# Go không cần cài package riêng, dùng REST API
```

3. **Update `bill_scan_handler.go`:**
```go
// Thay thế phần mock data bằng:
result, err := callGeminiAPI(imageBytes)
if err != nil {
    // handle error
}
```

4. **Implement `callGeminiAPI()`:**
   - Convert image to base64
   - Tạo prompt cho Gemini
   - Gọi API: `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent`
   - Parse JSON response

5. **Test và debug**

## 🔒 Security Notes

- ✅ Validate file size (max 10MB)
- ✅ Validate file type (JPG/JPEG/PNG)
- ❌ TODO: Rate limiting
- ❌ TODO: Authentication/Authorization
- ❌ TODO: Secure API key storage

## 📊 Response Data Structure

```dart
class BillScanResult {
  final String merchant;   // Required
  final double amount;     // Required
  final DateTime date;     // Required
  final String category;   // Required
  final String? note;      // Optional
}
```

**Categories:**
- Ăn uống
- Di chuyển
- Mua sắm
- Giải trí
- Y tế
- Giáo dục
- Khác

## 🐛 Troubleshooting

### App không kết nối được server

1. Kiểm tra server đang chạy:
```bash
curl http://localhost:8080/api/v1/ping
```

2. Đổi URL phù hợp với môi trường
3. Tắt firewall/antivirus tạm thời

### Lỗi "File ảnh quá lớn"

- Giảm chất lượng ảnh trong code:
```dart
imageQuality: 85,  // Giảm xuống 70-80
```

### Server báo lỗi "Invalid file format"

- Chỉ chấp nhận: JPG, JPEG, PNG
- Kiểm tra extension của file

## 📖 Documentation

- [Flutter camera package](https://pub.dev/packages/camera)
- [Flutter image_picker package](https://pub.dev/packages/image_picker)
- [Gin Web Framework](https://gin-gonic.com/)
- [Google Gemini API](https://ai.google.dev/)

## 🎯 Next Steps

1. ✅ Flutter app gửi ảnh lên server
2. ✅ Server nhận và validate ảnh
3. ⏳ Tích hợp Gemini AI để phân tích ảnh
4. ⏳ Lưu ảnh vào storage (optional)
5. ⏳ Thêm authentication
6. ⏳ Deploy lên production
