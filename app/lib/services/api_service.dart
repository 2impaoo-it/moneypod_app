import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../utils/dio_client.dart';
import '../utils/error_handler.dart';

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
      if (kDebugMode) {
        print('🔵 [ApiService] Kiểm tra server health...');
      }

      final response = await _dio.get(
        '$baseUrl/ping',
        options: Options(
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
        ),
      );

      if (kDebugMode) {
        print('📡 [ApiService] Status code: ${response.statusCode}');
      }

      // Check 503 - Server đang bảo trì
      if (response.statusCode == 503) {
        return {
          'isHealthy': false,
          'errorType': 'maintenance',
          'message': 'Máy chủ đang bảo trì. Vui lòng quay lại sau.',
        };
      }

      if (response.statusCode == 200) {
        final message =
            response.data['message']?.toString().toLowerCase() ?? '';

        // Kiểm tra message có chứa "moneypod" không
        if (message.contains('moneypod')) {
          return {'isHealthy': true, 'errorType': null};
        }
      }

      return {
        'isHealthy': false,
        'errorType': 'unknown',
        'message': 'Dịch vụ tạm thời không khả dụng.',
      };
    } on DioException catch (e) {
      ErrorHandler.logError(e);

      if (e.error is SocketException ||
          e.type == DioExceptionType.connectionTimeout) {
        return {
          'isHealthy': false,
          'errorType': 'no_internet',
          'message': 'Không có kết nối mạng. Vui lòng kiểm tra Wi-Fi hoặc 4G.',
        };
      }

      // Check for Ngrok tunnel errors
      final responseBody = e.response?.data?.toString() ?? '';
      if (responseBody.contains('ngrok') ||
          responseBody.contains('ERR_NGROK')) {
        return {
          'isHealthy': false,
          'errorType': 'maintenance',
          'message': 'Máy chủ đang bảo trì. Vui lòng quay lại sau.',
        };
      }

      return {
        'isHealthy': false,
        'errorType': 'unknown',
        'message': ErrorHandler.getFriendlyMessage(e),
      };
    } catch (e) {
      ErrorHandler.logError(e);
      return {
        'isHealthy': false,
        'errorType': 'unknown',
        'message': ErrorHandler.getFriendlyMessage(e),
      };
    }
  }
}
