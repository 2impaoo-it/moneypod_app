import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

/// Dio Client với Interceptor tự động xử lý lỗi server
class DioClient {
  static const storage = FlutterSecureStorage();
  static Dio? _dio;
  static GlobalKey<NavigatorState>? _navigatorKey;

  /// Set navigator key để có thể show dialog và navigate
  static void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  /// Khởi tạo Dio với interceptor
  static Dio getDio(BuildContext? context) {
    if (_dio != null) return _dio!;

    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
      ),
    );

    // Thêm interceptor
    _dio!.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Log request
          debugPrint('🌐 REQUEST[${options.method}] => ${options.uri}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          // Log response
          debugPrint(
            '✅ RESPONSE[${response.statusCode}] => ${response.requestOptions.uri}',
          );
          return handler.next(response);
        },
        onError: (DioException error, handler) async {
          debugPrint(
            '❌ ERROR[${error.response?.statusCode}] => ${error.message}',
          );

          final navContext = _navigatorKey?.currentContext;

          // Handle maintenance mode (503)
          if (error.response?.statusCode == 503) {
            final data = error.response?.data;
            if (data is Map && data['error'] == 'MAINTENANCE_MODE') {
              if (navContext != null && navContext.mounted) {
                _showMaintenanceDialog(
                  navContext,
                  data['message'] ?? 'Hệ thống đang bảo trì',
                );
              }
              // Reject với error có message rõ ràng
              return handler.reject(
                DioException(
                  requestOptions: error.requestOptions,
                  response: error.response,
                  type: DioExceptionType.badResponse,
                  error: 'Server đang bảo trì',
                  message: 'Hệ thống đang bảo trì',
                ),
              );
            }
          }

          // Handle server error (500+)
          if (error.response?.statusCode != null &&
              error.response!.statusCode! >= 500) {
            // Không hiển thị dialog lỗi cho insights API
            final uri = error.requestOptions.uri.toString();
            final isInsightApi = uri.contains('/insights/');

            if (!isInsightApi && navContext != null && navContext.mounted) {
              _showServerErrorDialog(navContext);
            }
          }

          return handler.next(error);
        },
      ),
    );

    return _dio!;
  }

  /// Reset Dio instance (useful for testing or logout)
  static void reset() {
    _dio = null;
  }

  static void _showMaintenanceDialog(BuildContext context, String message) {
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.construction, color: Colors.orange, size: 28),
            SizedBox(width: 10),
            Text('Bảo trì hệ thống'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 16),
            const Text(
              'Bạn sẽ được chuyển về màn hình đăng nhập.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _logout(context);
            },
            child: const Text('Đồng ý'),
          ),
        ],
      ),
    );
  }

  static void _showServerErrorDialog(BuildContext context) {
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 28),
            SizedBox(width: 10),
            Text('Lỗi kết nối'),
          ],
        ),
        content: const Text(
          'Không thể kết nối tới server. Vui lòng thử lại sau hoặc đăng xuất.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Đóng'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _logout(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  static Future<void> _logout(BuildContext context) async {
    if (!context.mounted) return;

    // Clear all auth data
    await storage.delete(key: 'auth_token');
    await storage.delete(key: 'user_id');
    await storage.delete(key: 'fcm_token');

    // Navigate to splash screen using GoRouter
    if (context.mounted) {
      context.go('/splash');
    }
  }
}
