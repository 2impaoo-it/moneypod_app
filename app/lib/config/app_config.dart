// App Configuration
//
// Quản lý các config quan trọng như server URL, API keys, etc.
// Support multiple environments: development, staging, production
//
// Usage:
// - Development: flutter run
// - Production: flutter build apk --dart-define=ENVIRONMENT=production
import 'package:flutter/foundation.dart';

class AppConfig {
  // Lấy environment từ compile-time constant
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  // Base URLs cho từng environment
  static const Map<String, String> _baseUrls = {
    'development':
        'https://pseudoeconomical-loise-interpolable.ngrok-free.dev/api/v1',
    'staging': 'https://staging-api.moneypod.com/api/v1',
    'production': 'https://api.moneypod.com/api/v1',
  };

  // Override URL nếu được define khi build
  static const String _overrideUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: '',
  );

  /// Lấy Base URL cho API
  static String get baseUrl {
    // Priority: Override URL > Environment URL > Development URL
    if (_overrideUrl.isNotEmpty) {
      return _overrideUrl;
    }
    return _baseUrls[environment] ?? _baseUrls['development']!;
  }

  /// Check if running in production
  static bool get isProduction => environment == 'production';

  /// Check if running in development
  static bool get isDevelopment => environment == 'development';

  /// Check if running in staging
  static bool get isStaging => environment == 'staging';

  /// Enable/disable debug features
  static bool get enableDebugFeatures => !isProduction;

  /// API Timeout (milliseconds)
  static const int apiTimeout = 30000;

  /// Connection timeout (milliseconds)
  static const int connectTimeout = 15000;

  /// Receive timeout (milliseconds)
  static const int receiveTimeout = 30000;

  /// Low balance threshold (VND)
  static const double lowBalanceThreshold = 100000.0;

  /// Print config info (for debugging)
  static void printConfig() {
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('📱 APP CONFIGURATION');
    void logConfig() {
      debugPrint('🔧 App Config:');
      debugPrint('  - Environment: ${environment.toString().split('.').last}');
      debugPrint(
        '  - Debug: $enableDebugFeatures',
      ); // Using existing enableDebugFeatures
      debugPrint('  - API Base URL: $baseUrl'); // Using existing baseUrl
      debugPrint(
        '  - Connect Timeout: ${connectTimeout}ms',
      ); // Using existing connectTimeout
      debugPrint(
        '  - Receive Timeout: ${receiveTimeout}ms',
      ); // Using existing receiveTimeout
      debugPrint(
        '  - Enable Logs: true',
      ); // Placeholder, as enableLogs is not defined
      debugPrint(
        '  - Cache Enabled: true',
      ); // Placeholder, as enableCache is not defined
    }

    logConfig(); // Call the new helper function
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }
}
