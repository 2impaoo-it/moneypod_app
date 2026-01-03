import 'package:flutter/foundation.dart';

/// Utility class to convert technical errors into user-friendly messages.
/// Hides sensitive information like endpoints, technical codes in production.
class ErrorHandler {
  /// Convert any error to a user-friendly message
  static String getFriendlyMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // Network / Connection errors
    if (errorString.contains('socketexception') ||
        errorString.contains('connection refused') ||
        errorString.contains('network is unreachable')) {
      return 'Không có kết nối mạng. Vui lòng kiểm tra Wi-Fi hoặc 4G.';
    }

    // Timeout errors
    if (errorString.contains('timeout') || errorString.contains('timed out')) {
      return 'Kết nối chậm. Vui lòng thử lại.';
    }

    // Server offline / Ngrok errors
    if (errorString.contains('ngrok') ||
        errorString.contains('err_ngrok') ||
        errorString.contains('tunnel') ||
        errorString.contains('offline')) {
      return 'Máy chủ đang bảo trì. Vui lòng quay lại sau.';
    }

    // 404 - Not found
    if (errorString.contains('404') || errorString.contains('not found')) {
      return 'Dịch vụ tạm thời không khả dụng.';
    }

    // 401/403 - Auth errors
    if (errorString.contains('401') ||
        errorString.contains('403') ||
        errorString.contains('unauthorized') ||
        errorString.contains('forbidden')) {
      return 'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.';
    }

    // 500 - Server error
    if (errorString.contains('500') ||
        errorString.contains('internal server error')) {
      return 'Đã xảy ra lỗi. Chúng tôi đang khắc phục.';
    }

    // 503 - Maintenance
    if (errorString.contains('503') ||
        errorString.contains('service unavailable')) {
      return 'Máy chủ đang bảo trì. Vui lòng quay lại sau.';
    }

    // Default message
    return 'Đã có lỗi xảy ra. Vui lòng thử lại.';
  }

  /// Get detailed error for debug mode only
  static String getDebugMessage(dynamic error) {
    if (kDebugMode) {
      return error.toString();
    }
    return getFriendlyMessage(error);
  }

  /// Log error (can be extended to send to Crashlytics/Sentry)
  static void logError(dynamic error, {StackTrace? stackTrace}) {
    if (kDebugMode) {
      print('❌ [ErrorHandler] $error');
      if (stackTrace != null) {
        print(stackTrace);
      }
    }
    // TODO: In production, send to Firebase Crashlytics or Sentry
    // FirebaseCrashlytics.instance.recordError(error, stackTrace);
  }
}
