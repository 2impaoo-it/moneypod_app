import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moneypod/bloc/auth/auth_bloc.dart';
import 'package:moneypod/bloc/auth/auth_state.dart';
import 'package:moneypod/services/biometric_service.dart'; // Import BiometricService
import 'package:moneypod/services/fcm_service.dart'; // Import FCMService
import 'package:moneypod/screens/auth/login_screen.dart';

class MockAuthBloc extends Mock implements AuthBloc {}

class MockBiometricService extends Mock implements BiometricService {}

class MockFCMService extends Mock implements FCMService {}

void main() {
  late MockAuthBloc mockAuthBloc;
  late MockBiometricService mockBiometricService;
  late MockFCMService mockFCMService;

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    mockBiometricService = MockBiometricService();
    mockFCMService = MockFCMService();

    when(
      () => mockAuthBloc.stream,
    ).thenAnswer((_) => Stream.value(AuthInitial()));
    when(() => mockAuthBloc.state).thenReturn(AuthInitial());
    when(() => mockAuthBloc.close()).thenAnswer((_) async {});

    // Stub BiometricService
    when(
      () => mockBiometricService.isBiometricAvailable(),
    ).thenAnswer((_) async => false);
    when(
      () => mockBiometricService.getSavedAccounts(),
    ).thenAnswer((_) async => []);

    // Stub FCMService to avoid Firebase calls
    when(() => mockFCMService.initialize()).thenAnswer((_) async {});
  });

  testWidgets('LoginScreen initial state golden test', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<AuthBloc>.value(
          value: mockAuthBloc,
          child: LoginScreen(
            biometricService: mockBiometricService,
            fcmService: mockFCMService,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await expectLater(
      find.byType(LoginScreen),
      matchesGoldenFile('goldens/login_screen_initial.png'),
    );
  });
}
