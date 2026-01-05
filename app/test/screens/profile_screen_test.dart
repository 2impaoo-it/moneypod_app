import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moneypod/screens/profile/profile_screen.dart';
import 'package:moneypod/bloc/auth/auth_event.dart';

import 'package:moneypod/services/auth_service.dart';
import '../mocks/test_helper.dart';

class FakeAuthService extends Mock implements AuthService {}

void main() {
  late TestHelper helper;

  setUpAll(() {
    TestHelper.registerFallbacks();
  });

  setUp(() {
    helper = TestHelper();
    helper.setUp();
  });

  group('ProfileScreen', () {
    testWidgets('renders profile info when authenticated', (tester) async {
      await tester.pumpWidget(
        helper.wrapWithProviders(
          ProfileScreen(
            profileService: helper.profileService,
            token: 'test-token',
            authService:
                FakeAuthService(), // Or mock if necessary but it might be used internally
            biometricService: helper.biometricService,
            firebaseAuth: helper.firebaseAuth,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // User info from TestHelper
      expect(find.text('Test User'), findsOneWidget);
      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('shows avatar', (tester) async {
      await tester.pumpWidget(
        helper.wrapWithProviders(
          ProfileScreen(
            profileService: helper.profileService,
            token: 'test-token',
            authService: FakeAuthService(),
            biometricService: helper.biometricService,
            firebaseAuth: helper.firebaseAuth,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CircleAvatar), findsWidgets);
    });

    testWidgets('renders settings section', (tester) async {
      await tester.pumpWidget(
        helper.wrapWithProviders(
          ProfileScreen(
            profileService: helper.profileService,
            token: 'test-token',
            authService: FakeAuthService(),
            biometricService: helper.biometricService,
            firebaseAuth: helper.firebaseAuth,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cài đặt chung'), findsOneWidget);
      expect(find.text('Bảo mật'), findsOneWidget);
    });

    testWidgets('shows logout button', (tester) async {
      await tester.pumpWidget(
        helper.wrapWithProviders(
          ProfileScreen(
            profileService: helper.profileService,
            token: 'test-token',
            authService: FakeAuthService(),
            biometricService: helper.biometricService,
            firebaseAuth: helper.firebaseAuth,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Đăng xuất'), findsOneWidget);
    });

    testWidgets('logout triggers AuthLogoutRequested', (tester) async {
      when(() => helper.authBloc.add(any())).thenReturn(null);

      await tester.pumpWidget(
        helper.wrapWithProviders(
          ProfileScreen(
            profileService: helper.profileService,
            token: 'test-token',
            authService: FakeAuthService(),
            biometricService: helper.biometricService,
            firebaseAuth: helper.firebaseAuth,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to logout button if needed
      await tester.scrollUntilVisible(
        find.text('Đăng xuất'),
        500,
        scrollable: find.byType(Scrollable),
      );

      await tester.tap(find.text('Đăng xuất'));
      await tester.pumpAndSettle();

      // Confirm dialog
      expect(find.text('Xác nhận đăng xuất'), findsOneWidget);
      await tester.tap(find.text('Đăng xuất').last);
      await tester.pump();

      verify(
        () => helper.authBloc.add(any(that: isA<AuthLogoutRequested>())),
      ).called(1);
    });

    testWidgets('toggle biometric switch', (tester) async {
      await tester.pumpWidget(
        helper.wrapWithProviders(
          ProfileScreen(
            profileService: helper.profileService,
            token: 'test-token',
            authService: FakeAuthService(),
            biometricService: helper.biometricService,
            firebaseAuth: helper.firebaseAuth,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final switchWidget = find.byType(Switch);
      if (switchWidget.evaluate().isNotEmpty) {
        await tester.tap(switchWidget.first);
        await tester.pump();
        // Verify functionality depending on mock behavior
      }
    });

    testWidgets('shows edit profile option', (tester) async {
      await tester.pumpWidget(
        helper.wrapWithProviders(
          ProfileScreen(
            profileService: helper.profileService,
            token: 'test-token',
            authService: FakeAuthService(),
            biometricService: helper.biometricService,
            firebaseAuth: helper.firebaseAuth,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.edit), findsWidgets);
    });

    testWidgets('shows change password option', (tester) async {
      await tester.pumpWidget(
        helper.wrapWithProviders(
          ProfileScreen(
            profileService: helper.profileService,
            token: 'test-token',
            authService: FakeAuthService(),
            biometricService: helper.biometricService,
            firebaseAuth: helper.firebaseAuth,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Đổi mật khẩu'), findsOneWidget);
    });

    testWidgets('shows notification settings option', (tester) async {
      await tester.pumpWidget(
        helper.wrapWithProviders(
          ProfileScreen(
            profileService: helper.profileService,
            token: 'test-token',
            authService: FakeAuthService(),
            biometricService: helper.biometricService,
            firebaseAuth: helper.firebaseAuth,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Thông báo & Nhắc nhở'), findsOneWidget);
    });

    testWidgets('renders version info', (tester) async {
      await tester.pumpWidget(
        helper.wrapWithProviders(
          ProfileScreen(
            profileService: helper.profileService,
            token: 'test-token',
            authService: FakeAuthService(),
            biometricService: helper.biometricService,
            firebaseAuth: helper.firebaseAuth,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Phiên bản'), findsOneWidget);
    });
  });
}
