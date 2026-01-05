import 'package:flutter_test/flutter_test.dart';
import 'package:moneypod/config/app_config.dart';

void main() {
  group('AppConfig', () {
    test('default environment is development', () {
      // Note: This test runs with default compile-time constants
      expect(AppConfig.environment, equals('development'));
    });

    test('baseUrl returns valid URL for development', () {
      expect(AppConfig.baseUrl, contains('api'));
      expect(AppConfig.baseUrl, startsWith('https://'));
    });

    test('isDevelopment returns true in default environment', () {
      expect(AppConfig.isDevelopment, isTrue);
    });

    test('isProduction returns false in development', () {
      expect(AppConfig.isProduction, isFalse);
    });

    test('isStaging returns false in development', () {
      expect(AppConfig.isStaging, isFalse);
    });

    test('enableDebugFeatures returns true in non-production', () {
      expect(AppConfig.enableDebugFeatures, isTrue);
    });

    test('timeout constants are defined correctly', () {
      expect(AppConfig.apiTimeout, equals(30000));
      expect(AppConfig.connectTimeout, equals(15000));
      expect(AppConfig.receiveTimeout, equals(30000));
    });

    test('lowBalanceThreshold is defined', () {
      expect(AppConfig.lowBalanceThreshold, equals(100000.0));
    });

    test('printConfig does not throw', () {
      // Just verify it runs without error
      expect(() => AppConfig.printConfig(), returnsNormally);
    });
  });
}
