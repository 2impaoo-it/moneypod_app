import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moneypod/screens/auth/login_screen.dart';
import 'package:moneypod/bloc/auth/auth_bloc.dart';

import 'package:moneypod/bloc/auth/auth_state.dart';
import 'package:moneypod/services/auth_service.dart';
import 'package:moneypod/services/biometric_service.dart';
import 'package:moneypod/services/fcm_service.dart';
import 'package:go_router/go_router.dart';

import 'package:bloc_test/bloc_test.dart';
import 'package:moneypod/bloc/dashboard/dashboard_bloc.dart';
import 'package:moneypod/bloc/dashboard/dashboard_event.dart';
import 'package:moneypod/bloc/dashboard/dashboard_state.dart';

class MockDashboardBloc extends MockBloc<DashboardEvent, DashboardState>
    implements DashboardBloc {}

class MockAuthService extends Mock implements AuthService {}

class MockBiometricService extends Mock implements BiometricService {}

class MockFCMService extends Mock implements FCMService {}

class MockGoRouter extends Mock implements GoRouter {}

void main() {
  late MockAuthService mockAuthService;
  late MockBiometricService mockBiometricService;
  late MockFCMService mockFCMService;
  late AuthBloc authBloc;

  late MockDashboardBloc mockDashboardBloc;

  setUp(() {
    mockAuthService = MockAuthService();
    mockBiometricService = MockBiometricService();
    mockFCMService = MockFCMService();
    authBloc = AuthBloc(authService: mockAuthService);
    mockDashboardBloc = MockDashboardBloc();
    when(
      () => mockDashboardBloc.state,
    ).thenReturn(DashboardLoading()); // Or Initial

    // Default mock setup
    when(
      () => mockBiometricService.isBiometricAvailable(),
    ).thenAnswer((_) async => false);
    when(
      () => mockBiometricService.getSavedAccounts(),
    ).thenAnswer((_) async => []);
    when(
      () => mockFCMService.getCurrentToken(),
    ).thenAnswer((_) async => 'fcm-token');
  });

  tearDown(() {
    authBloc.close();
  });

  Future<void> pumpLoginScreen(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => LoginScreen(
            biometricService: mockBiometricService,
            fcmService: mockFCMService,
          ),
        ),
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('Dashboard')),
        ),
      ],
    );

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<AuthService>.value(value: mockAuthService),
        ],
        child: MultiBlocProvider(
          providers: [
            // LoginScreen might need DashboardBloc for refresh event
            BlocProvider<AuthBloc>.value(value: authBloc),
            BlocProvider<DashboardBloc>.value(value: mockDashboardBloc),
            // Note: DashboardBloc usually needs repository, pass null or mock if safe
            // But LoginScreen uses context.read<DashboardBloc>().add(...)
            // So we need to provide it.
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      ),
    );
  }

  group('Login Flow Integration', () {
    testWidgets('Valid login credentials triggers AuthAuthenticated', (
      tester,
    ) async {
      // Arrange
      when(
        () => mockAuthService.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
          fcmToken: any(named: 'fcmToken'),
        ),
      ).thenAnswer(
        (_) async => {
          'success': true,
          'token': 'fake-jwt-token',
          'message': 'Login success',
        },
      );

      // Act
      await pumpLoginScreen(tester);
      await tester.pumpAndSettle(); // Wait for init

      // Fill form
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'test@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.pump();

      // Tap Login
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump(); // Start request

      // Assert Loading State
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle(); // Finish request

      // Assert State Transition
      expect(authBloc.state, isA<AuthAuthenticated>());
    });

    testWidgets('Invalid login shows error snackbar', (tester) async {
      // Arrange
      when(
        () => mockAuthService.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
          fcmToken: any(named: 'fcmToken'),
        ),
      ).thenAnswer(
        (_) async => {'success': false, 'message': 'Invalid credentials'},
      );

      // Act
      await pumpLoginScreen(tester);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'wrong@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'wrongpass');
      await tester.tap(find.byType(ElevatedButton));

      await tester.pump(); // Loading
      await tester.pumpAndSettle(); // Error

      // Verify login was actually called
      verify(
        () => mockAuthService.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
          fcmToken: any(named: 'fcmToken'),
        ),
      ).called(1);

      // Debug: print all widgets to see if dialog is there
      // debugDumpApp(); // Too large

      // Check if any dialog exists
      expect(find.byType(Dialog), findsOneWidget, reason: 'Dialog not found');
      expect(
        find.textContaining('Invalid credentials'),
        findsOneWidget,
        reason: 'Text not found',
      );
    });

    testWidgets('Empty fields show validation errors', (tester) async {
      await pumpLoginScreen(tester);
      await tester.pumpAndSettle();

      // Tap login without entering text
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Vui lòng nhập email'), findsOneWidget);
      expect(find.text('Vui lòng nhập mật khẩu'), findsOneWidget);

      // Verify no login call
      verifyNever(
        () => mockAuthService.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
          fcmToken: any(named: 'fcmToken'),
        ),
      );
    });
  });
}
