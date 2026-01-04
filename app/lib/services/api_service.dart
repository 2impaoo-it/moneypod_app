import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../utils/dio_client.dart';

/// Service để kiểm tra kết nối server
class ApiService {
  static const String baseUrl =
      'https://pseudoeconomical-loise-interpolable.ngrok-free.dev/api/v1';
  static final Dio _dio = DioClient.getDio(null);

  /// Kiểm tra server có hoạt động không
  ///
  /// Returns: Map với keys 'isHealthy' (bool) và 'errorType' (String?)
  /// errorType có thể là: 'maintenance' (503), 'no_internet' (mất mạng), null (nếu OK)
  static Future<Map<String, dynamic>> checkServerHealth() async {
    try {
      debugPrint('🔵 [ApiService] Kiểm tra server health...');

      final response = await _dio.get(
        '$baseUrl/ping',
        options: Options(
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
        ),
      );

      debugPrint('📡 [ApiService] Status code: ${response.statusCode}');
      debugPrint('📡 [ApiService] Response body: ${response.data}');

      // Check 503 - Server đang bảo trì
      if (response.statusCode == 503) {
        debugPrint('🔧 [ApiService] Server đang bảo trì (503)');
        String maintenanceMessage = 'Server đang bảo trì, vui lòng thử lại sau';
        if (response.data is Map) {
          maintenanceMessage = response.data['message'] ?? maintenanceMessage;
        }

        return {
          'isHealthy': false,
          'errorType': 'maintenance',
          'message': maintenanceMessage,
        };
      }

      if (response.statusCode == 200) {
        final message =
            response.data['message']?.toString().toLowerCase() ?? '';

        // Kiểm tra message có chứa "moneypod" không
        if (message.contains('moneypod')) {
          debugPrint('✅ [ApiService] Server hoạt động tốt!');
          return {'isHealthy': true, 'errorType': null};
        }
      }

      debugPrint('❌ [ApiService] Server trả về response không hợp lệ');
      return {
        'isHealthy': false,
        'errorType': 'unknown',
        'message': 'Server trả về phản hồi không hợp lệ',
      };
    } on DioException catch (e) {
      if (e.error is SocketException ||
          e.type == DioExceptionType.connectionTimeout) {
        debugPrint('❌ [ApiService] Lỗi kết nối: $e');
        return {
          'isHealthy': false,
          'errorType': 'no_internet',
          'message': 'Không thể kết nối đến server',
        };
      }
      debugPrint('❌ [ApiService] Dio error: $e');
      return {
        'isHealthy': false,
        'errorType': 'unknown',
        'message': e.response?.data['error'] ?? 'Có lỗi xảy ra',
      };
    } catch (e) {
      debugPrint('❌ [ApiService] Lỗi không xác định: $e');
      return {
        'isHealthy': false,
        'errorType': 'unknown',
        'message': 'Có lỗi xảy ra: $e',
      };
    }
  }
}
