import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/dio_client.dart';

class AuthService {
  static const String baseUrl =
      'https://pseudoeconomical-loise-interpolable.ngrok-free.dev/api/v1';

  final storage = const FlutterSecureStorage();
  late final Dio _dio;

  AuthService() {
    _dio = DioClient.getDio(null);
    _dio.options.baseUrl = baseUrl;
  }

  // Đăng ký tài khoản mới
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final response = await _dio.post(
        '/register',
        data: {'email': email, 'password': password, 'full_name': fullName},
      );

      if (response.statusCode == 201) {
        return {'success': true, 'message': response.data['message']};
      } else {
        return {
          'success': false,
          'message': response.data['error'] ?? 'Đăng ký thất bại',
        };
      }
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['error'] ?? 'Lỗi kết nối: ${e.message}',
      };
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

      final response = await _dio.post('/login', data: body);

      if (response.statusCode == 200) {
        // Lưu token vào secure storage
        final token = response.data['token'];
        await storage.write(key: 'auth_token', value: token);

        return {
          'success': true,
          'message': response.data['message'],
          'token': token,
        };
      } else {
        return {
          'success': false,
          'message': response.data['error'] ?? 'Đăng nhập thất bại',
        };
      }
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['error'] ?? 'Lỗi kết nối: ${e.message}',
      };
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

      final response = await _dio.put(
        '/change-password',
        data: {'old_password': currentPassword, 'new_password': newPassword},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'Đổi mật khẩu thành công',
        };
      } else {
        return {
          'success': false,
          'message': response.data['error'] ?? 'Đổi mật khẩu thất bại',
        };
      }
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['error'] ?? 'Lỗi kết nối: ${e.message}',
      };
    }
  }

  // Quên mật khẩu (gửi email reset)
  Future<Map<String, dynamic>> forgotPassword({required String email}) async {
    try {
      final response = await _dio.post(
        '/forgot-password',
        data: {'email': email},
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message':
              response.data['message'] ?? 'Đã gửi email khôi phục mật khẩu',
        };
      } else {
        return {
          'success': false,
          'message': response.data['error'] ?? 'Không thể gửi email khôi phục',
        };
      }
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['error'] ?? 'Lỗi kết nối: ${e.message}',
      };
    }
  }

  // Cập nhật FCM Token
  Future<Map<String, dynamic>> updateFCMToken(String fcmToken) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'Bạn cần đăng nhập lại'};
      }

      final response = await _dio.put(
        '/profile/fcm-token',
        data: {'fcm_token': fcmToken},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message':
              response.data['message'] ?? 'Cập nhật FCM token thành công',
        };
      } else {
        return {
          'success': false,
          'message': response.data['error'] ?? 'Cập nhật FCM token thất bại',
        };
      }
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['error'] ?? 'Lỗi kết nối: ${e.message}',
      };
    }
  }
}
