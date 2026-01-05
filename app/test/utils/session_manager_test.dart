import 'package:flutter_test/flutter_test.dart';
import 'package:moneypod/utils/session_manager.dart';

// Note: SessionManager uses static FlutterSecureStorage.
// This cannot be easily mocked without refactoring.
// These tests verify static constants and class structure.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SessionManager', () {
    test('timeoutSeconds is defined', () {
      expect(SessionManager.timeoutSeconds, equals(600));
    });

    test('timeoutSeconds is reasonable (between 1-60 min)', () {
      expect(SessionManager.timeoutSeconds, greaterThanOrEqualTo(30));
      expect(SessionManager.timeoutSeconds, lessThanOrEqualTo(3600));
    });

    test('isLoggedIn returns Future<bool>', () async {
      // In test environment without stored token, should return false
      final result = await SessionManager.isLoggedIn();
      expect(result, isA<bool>());
    });

    test('checkSessionExpired returns Future<bool>', () async {
      final result = await SessionManager.checkSessionExpired();
      expect(result, isA<bool>());
    });

    test('saveLastActiveTime does not throw', () async {
      await expectLater(SessionManager.saveLastActiveTime(), completes);
    });

    test('resetPauseTime does not throw', () async {
      await expectLater(SessionManager.resetPauseTime(), completes);
    });

    test('clearSession does not throw', () async {
      await expectLater(SessionManager.clearSession(), completes);
    });
  });
}
