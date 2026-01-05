import 'package:flutter_test/flutter_test.dart';
import 'package:moneypod/main.dart';

// Note: Testing main.dart directly is limited because:
// 1. Firebase.initializeApp() requires platform setup
// 2. GoRouter initialization happens in State
// 3. This file primarily sets up app bootstrap
// Full app testing should use integration_test/

void main() {
  group('main.dart', () {
    group('AppColors', () {
      test('primary color is defined', () {
        expect(AppColors.primary, isNotNull);
        expect(AppColors.primary.toARGB32(), equals(0xFF14B8A6));
      });

      test('primaryDark color is defined', () {
        expect(AppColors.primaryDark, isNotNull);
        expect(AppColors.primaryDark.toARGB32(), equals(0xFF0F766E));
      });

      test('background color is defined', () {
        expect(AppColors.background, isNotNull);
        expect(AppColors.background.toARGB32(), equals(0xFFF8FAFC));
      });

      test('success color is green', () {
        expect(AppColors.success.toARGB32(), equals(0xFF22C55E));
      });

      test('danger color is red', () {
        expect(AppColors.danger.toARGB32(), equals(0xFFEF4444));
      });

      test('warning color is amber', () {
        expect(AppColors.warning.toARGB32(), equals(0xFFF59E0B));
      });
    });

    group('Navigator Keys', () {
      test('rootNavigatorKey is defined', () {
        expect(rootNavigatorKey, isNotNull);
      });

      test('shellNavigatorKey is defined', () {
        expect(shellNavigatorKey, isNotNull);
      });
    });

    group('Background Handler', () {
      test('firebaseMessagingBackgroundHandler exists', () {
        expect(firebaseMessagingBackgroundHandler, isA<Function>());
      });
    });
  });
}
