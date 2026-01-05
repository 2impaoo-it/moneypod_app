import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moneypod/screens/auth/login_screen.dart';
import 'package:moneypod/bloc/auth/auth_bloc.dart';
import 'package:moneypod/bloc/auth/auth_event.dart';
import 'package:moneypod/bloc/auth/auth_state.dart';
import 'package:moneypod/bloc/dashboard/dashboard_bloc.dart';
import 'package:moneypod/bloc/dashboard/dashboard_event.dart';
import 'package:moneypod/bloc/dashboard/dashboard_state.dart';
import 'package:moneypod/services/biometric_service.dart';
import 'package:moneypod/services/fcm_service.dart';

// Mocks
class MockAuthBloc extends Mock implements AuthBloc {
  @override
  Stream<AuthState> get stream => const Stream<AuthState>.empty();
}

class MockDashboardBloc extends Mock implements DashboardBloc {
  @override
  Stream<DashboardState> get stream => const Stream<DashboardState>.empty();
}

class MockBiometricService extends Mock implements BiometricService {}

class MockFCMService extends Mock implements FCMService {}

// Fake Events and States for Mocktail
class FakeAuthEvent extends Fake implements AuthEvent {}

class FakeAuthState extends Fake implements AuthState {}

class FakeDashboardEvent extends Fake implements DashboardEvent {}

class FakeDashboardState extends Fake implements DashboardState {}

void main() {
  late MockAuthBloc mockAuthBloc;
  late MockDashboardBloc mockDashboardBloc;
  late MockBiometricService mockBiometricService;
  late MockFCMService mockFCMService;

  setUpAll(() {
    registerFallbackValue(FakeAuthEvent());
    registerFallbackValue(FakeAuthState());
    registerFallbackValue(FakeDashboardEvent());
    registerFallbackValue(FakeDashboardState());
    registerFallbackValue(AuthLoginRequested(email: '', password: ''));
  });

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    mockDashboardBloc = MockDashboardBloc();
    mockBiometricService = MockBiometricService();
    mockFCMService = MockFCMService();

    // Default mock behavior for BLoCs
    when(() => mockDashboardBloc.state).thenReturn(DashboardInitial());
    when(() => mockDashboardBloc.add(any())).thenReturn(null);

    // Default mock behavior for Services
    when(
      () => mockBiometricService.isBiometricAvailable(),
    ).thenAnswer((_) async => false);
    when(
      () => mockBiometricService.getSavedAccounts(),
    ).thenAnswer((_) async => []);
    when(
      () => mockFCMService.getCurrentToken(),
    ).thenAnswer((_) async => 'mock_fcm_token');
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          BlocProvider<DashboardBloc>.value(value: mockDashboardBloc),
        ],
        child: LoginScreen(
          biometricService: mockBiometricService,
          fcmService: mockFCMService,
        ),
      ),
    );
  }

  testWidgets('renders login form initially when no saved accounts', (
    tester,
  ) async {
    when(() => mockAuthBloc.state).thenReturn(AuthInitial());

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Chào mừng trở lại! 👋'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Mật khẩu'), findsOneWidget);
    expect(find.text('Đăng nhập'), findsOneWidget);
  });

  testWidgets('renders saved accounts list when accounts exist', (
    tester,
  ) async {
    when(() => mockAuthBloc.state).thenReturn(AuthInitial());
    when(() => mockBiometricService.getSavedAccounts()).thenAnswer(
      (_) async => [
        {'email': 'test@test.com', 'name': 'Test User', 'avatar_url': null},
      ],
    );

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Should see "Xin chào trở lại!" instead of login form
    expect(find.text('Xin chào trở lại!'), findsOneWidget);
    expect(find.text('Test User'), findsOneWidget);
    expect(find.text('test@test.com'), findsOneWidget);
    // Should NOT see email input field of login form
    expect(find.text('Nhập email của bạn'), findsNothing);
  });

  testWidgets('shows loading indicator when AuthLoading', (tester) async {
    when(() => mockAuthBloc.state).thenReturn(AuthLoading());

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump(); // Pump frame

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('submits login event on button press', (tester) async {
    when(() => mockAuthBloc.state).thenReturn(AuthInitial());
    when(() => mockAuthBloc.add(any())).thenReturn(null);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Fill form
    await tester.enterText(
      find.ancestor(
        of: find.text('Nhập email của bạn'),
        matching: find.byType(TextFormField),
      ),
      'user@example.com',
    );
    await tester.enterText(
      find.ancestor(
        of: find.text('Nhập mật khẩu'),
        matching: find.byType(TextFormField),
      ),
      'password123',
    );

    // Tap login
    await tester.tap(find.text('Đăng nhập'));
    await tester.pump();

    verify(
      () => mockAuthBloc.add(any(that: isA<AuthLoginRequested>())),
    ).called(1);
  });
}
