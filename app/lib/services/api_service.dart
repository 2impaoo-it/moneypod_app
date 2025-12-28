import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Service để kiểm tra kết nối server
class ApiService {
  static const String baseUrl =
      'https://pseudoeconomical-loise-interpolable.ngrok-free.dev/api/v1';

  /// Kiểm tra server có hoạt động không
  ///
  /// Returns: Map với keys 'isHealthy' (bool) và 'errorType' (String?)
  /// errorType có thể là: 'maintenance' (503), 'no_internet' (mất mạng), null (nếu OK)
  static Future<Map<String, dynamic>> checkServerHealth() async {
    try {
      print('🔵 [ApiService] Kiểm tra server health...');

      final response = await http
          .get(
            Uri.parse('$baseUrl/ping'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              throw TimeoutException('Server không phản hồi trong 5 giây');
            },
          );

      print('📡 [ApiService] Status code: ${response.statusCode}');
      print('📡 [ApiService] Response body: ${response.body}');

      // Check 503 - Server đang bảo trì
      if (response.statusCode == 503) {
        print('🔧 [ApiService] Server đang bảo trì (503)');
        String maintenanceMessage = 'Server đang bảo trì, vui lòng thử lại sau';
        try {
          final data = json.decode(response.body);
          maintenanceMessage = data['message'] ?? maintenanceMessage;
        } catch (_) {}

        return {
          'isHealthy': false,
          'errorType': 'maintenance',
          'message': maintenanceMessage,
        };
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final message = data['message']?.toString().toLowerCase() ?? '';

        // Kiểm tra message có chứa "moneypod" không
        if (message.contains('moneypod')) {
          print('✅ [ApiService] Server hoạt động tốt!');
          return {'isHealthy': true, 'errorType': null};
        }
      }

      print('❌ [ApiService] Server trả về response không hợp lệ');
      return {
        'isHealthy': false,
        'errorType': 'unknown',
        'message': 'Server trả về phản hồi không hợp lệ',
      };
    } on SocketException catch (e) {
      print('❌ [ApiService] Lỗi kết nối: $e');
      return {
        'isHealthy': false,
        'errorType': 'no_internet',
        'message': 'Không thể kết nối đến server',
      };
    } on TimeoutException catch (e) {
      print('❌ [ApiService] Timeout: $e');
      return {
        'isHealthy': false,
        'errorType': 'no_internet',
        'message': 'Server không phản hồi',
      };
    } catch (e) {
      print('❌ [ApiService] Lỗi không xác định: $e');
      return {
        'isHealthy': false,
        'errorType': 'unknown',
        'message': 'Có lỗi xảy ra: $e',
      };
    }
  }
}
