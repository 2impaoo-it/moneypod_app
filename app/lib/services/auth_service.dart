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
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({'email': email, 'password': password}),
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

  // Cập nhật FCM Token
  Future<void> updateFCMToken(String fcmToken) async {
    try {
      final currentToken = await getToken();
      if (currentToken == null) {
        print('No auth token found. Cannot update FCM token.');
        return;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $currentToken', // Include auth token
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({'fcm_token': fcmToken}),
      );

      if (response.statusCode == 200) {
        print('FCM token updated successfully.');
      } else {
        final data = jsonDecode(response.body);
        print('Failed to update FCM token: ${data['error'] ?? response.body}');
      }
    } catch (e) {
      print('Error updating FCM token: $e');
    }
  }

  // Kiểm tra đã đăng nhập chưa
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
