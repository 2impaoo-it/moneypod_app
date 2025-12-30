# 📱 Frontend Update - Backend Changes (30/12/2025)

## 🎯 Tổng Quan

Document này mô tả các thay đổi và tính năng mới trong Backend để team Flutter có thể cập nhật app.

---

## ✅ 1. API Forgot Password (MỚI)

### Endpoint

```
POST /api/v1/forgot-password
```

### Request Body

```json
{
  "email": "user@example.com"
}
```

### Response Success (200 OK)

```json
{
  "message": "Vui lòng kiểm tra email để lấy mật khẩu mới"
}
```

### Response Error (400 Bad Request)

```json
{
  "error": "Email không hợp lệ"
}
```

### Flutter Implementation Example

```dart
// forgot_password_service.dart
Future<ApiResponse> forgotPassword(String email) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode == 200) {
      return ApiResponse(
        success: true,
        message: 'Vui lòng kiểm tra email để lấy mật khẩu mới',
      );
    } else {
      final error = jsonDecode(response.body);
      return ApiResponse(
        success: false,
        message: error['error'] ?? 'Có lỗi xảy ra',
      );
    }
  } catch (e) {
    return ApiResponse(
      success: false,
      message: 'Không thể kết nối server',
    );
  }
}
```

### UI Flow Khuyến Nghị

```
1. User nhấn "Quên mật khẩu" ở màn Login
   ↓
2. Hiển thị Dialog/Screen nhập email
   ↓
3. Gọi API forgot-password
   ↓
4. Hiển thị thông báo:
   ✅ "Đã gửi email! Vui lòng kiểm tra hộp thư"
   ❌ "Email không tồn tại trong hệ thống"
   ↓
5. User check email → Nhận mật khẩu tạm thời
   ↓
6. Đăng nhập bằng mật khẩu mới
   ↓
7. Redirect sang màn "Đổi mật khẩu"
```

### Email Format User Nhận Được

- **Subject:** Reset Password - MoneyPod App
- **From:** MoneyPod App <noreply@moneypod.app>
- **Content:** HTML email đẹp với mật khẩu tạm thời
- **Format:** `TempXXXXXXXXXXXX!@` (16 ký tự ngẫu nhiên)

---

## 🔐 2. Security Notes cho Frontend

### A. Email Validation

Frontend nên validate email trước khi gọi API:

```dart
bool isValidEmail(String email) {
  return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
}
```

### B. Rate Limiting

- Backend KHÔNG có rate limiting cho forgot-password
- Frontend nên implement debounce/cooldown (30 giây) để tránh spam

```dart
DateTime? lastRequestTime;

Future<void> requestForgotPassword(String email) async {
  // Check cooldown
  if (lastRequestTime != null) {
    final diff = DateTime.now().difference(lastRequestTime!);
    if (diff.inSeconds < 30) {
      showError('Vui lòng đợi ${30 - diff.inSeconds} giây');
      return;
    }
  }

  // Call API
  await forgotPassword(email);
  lastRequestTime = DateTime.now();
}
```

### C. Error Handling

Backend luôn trả về 200 OK (ngay cả khi email không tồn tại) để bảo mật.
→ Frontend chỉ cần hiển thị message chung:

```dart
"Nếu email tồn tại, bạn sẽ nhận được email reset password"
```

**KHÔNG** nên hiển thị:

- ❌ "Email này không tồn tại" (lộ thông tin user)
- ❌ "Email này chưa đăng ký" (lộ thông tin user)

---

## 🎨 3. UI/UX Recommendations

### A. Forgot Password Screen

```dart
// forgot_password_screen.dart
class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleSubmit() async {
    if (!isValidEmail(_emailController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Email không hợp lệ')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await forgotPassword(_emailController.text);

    setState(() => _isLoading = false);

    if (result.success) {
      // Hiển thị dialog thành công
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Thành công!'),
          content: Text(
            'Chúng tôi đã gửi email reset password.\n'
            'Vui lòng kiểm tra hộp thư (và cả spam folder).',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Đóng dialog
                Navigator.pop(context); // Quay về màn login
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Quên mật khẩu')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_reset, size: 80, color: Colors.purple),
            SizedBox(height: 24),
            Text(
              'Nhập email để reset mật khẩu',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 24),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSubmit,
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Gửi email reset'),
              ),
            ),
            SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Quay lại đăng nhập'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### B. Login Screen Update

Thêm button "Quên mật khẩu":

```dart
// login_screen.dart
TextButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ForgotPasswordScreen()),
    );
  },
  child: Text('Quên mật khẩu?'),
)
```

---

## 🔄 4. Other Backend Improvements

### A. Production-Ready Features

1. ✅ **Email Service**: SMTP với Gmail (có thể scale lên SendGrid)
2. ✅ **Constants**: Hardcoded strings đã được replace bằng constants
3. ✅ **Pagination**: TransactionService đã có pagination (100 items/page)
4. ✅ **Debt Protection**: UpdateExpense có validation (không xóa debt đã trả)

### B. Không Có Breaking Changes

Tất cả API cũ vẫn hoạt động bình thường. Chỉ có API mới được thêm.

---

## 📝 5. Testing Checklist cho Flutter Team

- [ ] Test forgot-password với email hợp lệ
- [ ] Test forgot-password với email không tồn tại
- [ ] Test forgot-password với email format sai
- [ ] Test forgot-password khi server offline
- [ ] Test UI responsiveness (loading state, error state)
- [ ] Test navigation flow (forgot password → login)
- [ ] Test với email dài, email có ký tự đặc biệt
- [ ] Verify email thật (check inbox/spam)
- [ ] Test login với mật khẩu mới từ email
- [ ] Test change password sau khi reset

---

## 🐛 6. Known Issues & Limitations

### A. Email Delivery Time

- Thường: 1-5 giây
- Chậm: 30 giây - 2 phút
- Frontend nên hiển thị: "Email có thể mất vài phút để đến"

### B. Spam Folder

- Email có thể vào spam folder
- Khuyến nghị user check cả spam

### C. Gmail Rate Limit

- Backend dùng Gmail SMTP: 500 emails/ngày
- Production cần upgrade lên SendGrid

### D. Network Requirements

- Cần internet để gửi email
- Port 587 phải mở (có thể bị firewall block ở một số mạng)

---

## 🔗 7. API Documentation Links

- **Swagger/Postman:** (Nếu có)
- **Base URL Dev:** `http://localhost:8080/api/v1`
- **Base URL Staging:** (Nếu có)
- **Base URL Production:** (Nếu có)

---

## 📞 8. Support & Questions

Nếu có vấn đề khi integrate:

1. **Check Backend Logs**: Xem server console có lỗi gì không
2. **Test với Postman**: Verify API hoạt động độc lập
3. **Email không đến**: Check spam folder, verify email config trong `.env`
4. **Network Error**: Kiểm tra firewall/antivirus

**Contact Backend Team:**

- Slack: #backend-support
- Email: backend@moneypod.app

---

## 📅 Version History

| Date       | Version | Changes                               |
| ---------- | ------- | ------------------------------------- |
| 30/12/2025 | 1.0.0   | Initial release - Forgot Password API |

---

## ✅ Summary for Flutter Team

**Cần Làm:**

1. ✅ Tạo màn hình Forgot Password
2. ✅ Thêm nút "Quên mật khẩu" ở màn Login
3. ✅ Implement API call forgot-password
4. ✅ Thêm email validation
5. ✅ Thêm loading & error states
6. ✅ Test flow end-to-end

**Không Cần Làm:**

- ❌ Không cần update API cũ
- ❌ Không cần migrate data
- ❌ Không cần thay đổi auth flow hiện tại

**Estimated Time:**

- UI: 2-3 giờ
- API Integration: 1 giờ
- Testing: 1-2 giờ
- **Total: 4-6 giờ**

---

**Happy Coding! 🚀**

Last Updated: 30/12/2025 by Backend Team
