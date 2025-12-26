# Hướng dẫn sử dụng tính năng Quét Bill

## 📋 Tổng quan

Tính năng quét bill cho phép người dùng chụp ảnh hóa đơn hoặc chọn từ thư viện, sau đó sử dụng AI (Gemini) để tự động trích xuất thông tin và phân loại giao dịch.

## 🏗️ Kiến trúc (BLoC Pattern)

### A. Data Layer (Repository)
**File:** `lib/repositories/bill_scan_repository.dart`

Chịu trách nhiệm:
- ✅ Xin quyền camera và thư viện ảnh
- ✅ Mở camera và chụp ảnh
- ✅ Chọn ảnh từ thư viện
- ✅ Gọi API Gemini để phân tích hóa đơn
- ✅ Parse kết quả JSON từ Gemini

### B. BLoC Layer
**Files:**
- `lib/bloc/bill_scan/bill_scan_event.dart` - Định nghĩa các events
- `lib/bloc/bill_scan/bill_scan_state.dart` - Định nghĩa các states
- `lib/bloc/bill_scan/bill_scan_bloc.dart` - Logic xử lý

**Events:**
- `ScanBillFromCamera` - Quét bill từ camera
- `ScanBillFromGallery` - Quét bill từ thư viện
- `ResetBillScan` - Reset về trạng thái ban đầu

**States:**
- `BillScanInitial` - Trạng thái ban đầu
- `BillScanLoading` - Đang quét
- `BillScanSuccess` - Quét thành công (kèm dữ liệu)
- `BillScanFailure` - Quét thất bại (kèm lỗi)

### C. UI Layer
**File:** `lib/screens/bill_scan_screen.dart`

Hiển thị:
- 📸 Nút chụp ảnh hóa đơn
- 🖼️ Nút chọn từ thư viện
- ⏳ Loading indicator khi đang quét
- ✅ Kết quả quét (tiêu đề, số tiền, danh mục, ngày, cửa hàng, ghi chú)
- 🔄 Nút quét lại
- ➕ Nút thêm giao dịch

### D. Model
**File:** `lib/models/bill_scan_result.dart`

Cấu trúc dữ liệu:
```dart
{
  "title": "Tên giao dịch",
  "amount": 50000.0,
  "category": "Ăn uống",
  "date": "2024-01-01T10:00:00",
  "merchant": "Cửa hàng ABC",
  "note": "Ghi chú bổ sung"
}
```

## 🔧 Cấu hình

### 1. Dependencies đã thêm vào `pubspec.yaml`:
```yaml
dependencies:
  camera: ^0.10.5+9              # Truy cập camera
  image_picker: ^1.0.7           # Chọn ảnh từ thư viện
  permission_handler: ^11.2.0    # Quản lý quyền
  google_generative_ai: ^0.2.2   # API Gemini
```

### 2. Android Permissions (`android/app/src/main/AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="28" />
```

### 3. iOS Permissions (`ios/Runner/Info.plist`):
```xml
<key>NSCameraUsageDescription</key>
<string>Ứng dụng cần quyền truy cập camera để quét hóa đơn</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Ứng dụng cần quyền truy cập thư viện ảnh để chọn hóa đơn</string>
```

### 4. Cấu hình API Key Gemini

**⚠️ QUAN TRỌNG:** Bạn cần thay thế API key trong file `bill_scan_repository.dart`:

```dart
static const String _geminiApiKey = 'YOUR_GEMINI_API_KEY';
```

**Cách lấy API key:**
1. Truy cập: https://makersuite.google.com/app/apikey
2. Đăng nhập bằng Google Account
3. Tạo API key mới
4. Copy và paste vào code

**Lưu ý bảo mật:**
- ❌ Không commit API key lên GitHub
- ✅ Sử dụng environment variables hoặc file `.env`
- ✅ Thêm `.env` vào `.gitignore`

## 📦 Cài đặt

### 1. Cài đặt dependencies:
```bash
cd app
flutter pub get
```

### 2. Chạy ứng dụng:
```bash
flutter run
```

## 🚀 Cách sử dụng

### Từ Dashboard:
1. Bấm vào nút "Quét Bill" trong phần Quick Actions
2. Màn hình Quét Bill sẽ hiển thị

### Quét bằng Camera:
1. Bấm nút "Chụp ảnh hóa đơn"
2. Ứng dụng sẽ xin quyền camera (lần đầu tiên)
3. Camera sẽ mở (camera sau mặc định)
4. Chụp ảnh hóa đơn
5. Đợi AI phân tích (3-10 giây)
6. Xem kết quả và bấm "Thêm giao dịch"

### Quét từ Thư viện:
1. Bấm nút "Chọn từ thư viện"
2. Ứng dụng sẽ xin quyền thư viện ảnh (lần đầu tiên)
3. Chọn ảnh hóa đơn từ thư viện
4. Đợi AI phân tích (3-10 giây)
5. Xem kết quả và bấm "Thêm giao dịch"

## 🎯 Danh mục được hỗ trợ

Gemini sẽ phân loại hóa đơn vào một trong các danh mục sau:
- 🍔 Ăn uống
- 🚗 Di chuyển
- 🛍️ Mua sắm
- 🎮 Giải trí
- 🏥 Y tế
- 📚 Giáo dục
- 📦 Khác

## 🔍 Luồng xử lý

```
User bấm "Chụp ảnh"
    ↓
UI dispatch ScanBillFromCamera event
    ↓
BLoC emit BillScanLoading state
    ↓
UI hiện loading indicator
    ↓
Repository: requestCameraPermission()
    ↓
Repository: takePictureWithCamera()
    ↓
Repository: scanBill(imageFile)
    ↓
Gemini API: Phân tích ảnh
    ↓
Repository: Parse JSON → BillScanResult
    ↓
BLoC emit BillScanSuccess(result)
    ↓
UI hiện kết quả + nút "Thêm giao dịch"
```

## 🐛 Xử lý lỗi

BLoC tự động xử lý các lỗi phổ biến:
- ❌ Không có quyền camera
- ❌ Người dùng không chụp/chọn ảnh
- ❌ Lỗi kết nối Gemini API
- ❌ Lỗi parse JSON

Thông báo lỗi sẽ hiển thị dưới dạng SnackBar.

## 📝 TODO / Cải tiến

- [ ] Tích hợp với TransactionBloc để tự động thêm giao dịch
- [ ] Lưu cache API key an toàn hơn (environment variables)
- [ ] Thêm preview ảnh trước khi gửi lên Gemini
- [ ] Hỗ trợ crop ảnh
- [ ] Hỗ trợ nhiều hóa đơn cùng lúc
- [ ] Lưu lịch sử quét bill
- [ ] Offline mode với ML Kit (không cần internet)

## 🤝 Đóng góp

Nếu bạn muốn cải thiện tính năng này:
1. Fork repository
2. Tạo branch mới (`git checkout -b feature/improve-bill-scan`)
3. Commit changes (`git commit -am 'Cải thiện tính năng quét bill'`)
4. Push to branch (`git push origin feature/improve-bill-scan`)
5. Tạo Pull Request

## 📄 License

MIT License - Xem file LICENSE để biết thêm chi tiết.
