import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  // Khi kết nối qua USB: dùng 10.0.2.2 (cho Android emulator) hoặc localhost (cho USB với adb reverse)
  // Khi kết nối qua WiFi: dùng IP máy tính (ví dụ: 192.168.1.100)
  // Khi kết nối qua USB thì phải forward port với lệnh:
  // adb reverse tcp:8080 tcp:8080
  static const String baseUrl =
      'https://pseudoeconomical-loise-interpolable.ngrok-free.dev/api/v1'; // ⬅️ Dùng localhost khi kết nối USB

  final storage = const FlutterSecureStorage();

  // Đăng ký tài khoản mới
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
          'full_name': fullName,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {'success': true, 'message': data['message']};
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Đăng ký thất bại',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: ${e.toString()}'};
    }
  }

  // Đăng nhập
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    String? fcmToken,
  }) async {
    try {
      final body = {'email': email, 'password': password};

      // Thêm FCM token nếu có
      if (fcmToken != null && fcmToken.isNotEmpty) {
        body['fcm_token'] = fcmToken;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Lưu token vào secure storage
        final token = data['token'];
        await storage.write(key: 'auth_token', value: token);

        return {'success': true, 'message': data['message'], 'token': token};
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Đăng nhập thất bại',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: ${e.toString()}'};
    }
  }

  // Lấy token đã lưu
  Future<String?> getToken() async {
    return await storage.read(key: 'auth_token');
  }

  // Đăng xuất
  Future<void> logout() async {
    await storage.delete(key: 'auth_token');
  }

  // Kiểm tra đã đăng nhập chưa
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Đổi mật khẩu (khi đã đăng nhập)
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'Bạn cần đăng nhập lại'};
      }

      final response = await http.put(
        Uri.parse('$baseUrl/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          'old_password': currentPassword,
          'new_password': newPassword,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Đổi mật khẩu thành công',
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Đổi mật khẩu thất bại',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: ${e.toString()}'};
    }
  }

  // Quên mật khẩu (gửi email reset)
  Future<Map<String, dynamic>> forgotPassword({required String email}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/forgot-password'),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({'email': email}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Đã gửi email khôi phục mật khẩu',
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Không thể gửi email khôi phục',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: ${e.toString()}'};
    }
  }

  // Cập nhật FCM Token
  Future<Map<String, dynamic>> updateFCMToken(String fcmToken) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'Bạn cần đăng nhập lại'};
      }

      final response = await http.put(
        Uri.parse('$baseUrl/profile/fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({'fcm_token': fcmToken}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Cập nhật FCM token thành công',
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Cập nhật FCM token thất bại',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: ${e.toString()}'};
    }
  }
}
