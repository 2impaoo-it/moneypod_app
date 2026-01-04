import 'package:flutter_test/flutter_test.dart';
import 'package:moneypod/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthService Interface Tests', () {
    late AuthService authService;

    setUp(() {
      authService = AuthService();
    });

    group('register', () {
      test('method exists and is callable', () {
        expect(authService.register, isNotNull);
      });
    });

    group('login', () {
      test('method exists and is callable', () {
        expect(authService.login, isNotNull);
      });
    });

    group('getToken', () {
      test('method exists', () {
        expect(authService.getToken, isNotNull);
      });
    });

    group('logout', () {
      test('method exists', () {
        expect(authService.logout, isNotNull);
      });
    });

    group('isLoggedIn', () {
      test('method exists', () {
        expect(authService.isLoggedIn, isNotNull);
      });
    });

    group('changePassword', () {
      test('method exists', () {
        expect(authService.changePassword, isNotNull);
      });
    });

    group('forgotPassword', () {
      test('method exists', () {
        expect(authService.forgotPassword, isNotNull);
      });
    });

    group('updateFCMToken', () {
      test('method exists', () {
        expect(authService.updateFCMToken, isNotNull);
      });
    });
  });

  group('AuthService Constants', () {
    test('service can be instantiated', () {
      final authService = AuthService();
      expect(authService, isNotNull);
    });

    test('storage is initialized', () {
      final authService = AuthService();
      expect(authService.storage, isNotNull);
    });
  });
}
