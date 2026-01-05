import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moneypod/bloc/auth/auth_bloc.dart';
import 'package:moneypod/bloc/auth/auth_event.dart';
import 'package:moneypod/bloc/auth/auth_state.dart';
import '../mocks/repositories.dart';

void main() {
  late MockAuthService mockAuthService;
  late AuthBloc bloc;

  setUp(() {
    mockAuthService = MockAuthService();
    bloc = AuthBloc(authService: mockAuthService);
  });

  tearDown(() {
    bloc.close();
  });

  group('AuthBloc', () {
    test('initial state is AuthInitial', () {
      expect(bloc.state, equals(AuthInitial()));
    });

    group('AuthLoginRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthAuthenticated] when login succeeds',
        build: () {
          when(
            () => mockAuthService.login(
              email: 'test@example.com',
              password: 'password',
              fcmToken: any(named: 'fcmToken'),
            ),
          ).thenAnswer((_) async => {'success': true, 'token': 'fake_token'});
          return bloc;
        },
        act: (bloc) => bloc.add(
          const AuthLoginRequested(
            email: 'test@example.com',
            password: 'password',
          ),
        ),
        expect: () => [
          AuthLoading(),
          isA<AuthAuthenticated>()
              .having((s) => s.user.token, 'token', 'fake_token')
              .having((s) => s.user.email, 'email', 'test@example.com'),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError, AuthUnauthenticated] when login fails',
        build: () {
          when(
            () => mockAuthService.login(
              email: 'test@example.com',
              password: 'wrong',
              fcmToken: any(named: 'fcmToken'),
            ),
          ).thenAnswer(
            (_) async => {'success': false, 'message': 'Invalid credentials'},
          );
          return bloc;
        },
        act: (bloc) => bloc.add(
          const AuthLoginRequested(
            email: 'test@example.com',
            password: 'wrong',
          ),
        ),
        expect: () => [
          AuthLoading(),
          const AuthError('Invalid credentials'),
          AuthUnauthenticated(),
        ],
      );
    });

    group('AuthLogoutRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthUnauthenticated] when logout succeeds',
        build: () {
          when(() => mockAuthService.logout()).thenAnswer((_) async {});
          return bloc;
        },
        act: (bloc) => bloc.add(AuthLogoutRequested()),
        expect: () => [AuthUnauthenticated()],
        verify: (_) {
          verify(() => mockAuthService.logout()).called(1);
        },
      );
    });

    group('AuthCheckRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthAuthenticated] via AuthTokenLoaded when token exists',
        build: () {
          when(
            () => mockAuthService.getToken(),
          ).thenAnswer((_) async => 'valid_token');
          return bloc;
        },
        act: (bloc) => bloc.add(AuthCheckRequested()),
        expect: () => [
          isA<AuthAuthenticated>().having(
            (s) => s.user.token,
            'token',
            'valid_token',
          ),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthUnauthenticated] when token is null',
        build: () {
          when(() => mockAuthService.getToken()).thenAnswer((_) async => null);
          return bloc;
        },
        act: (bloc) => bloc.add(AuthCheckRequested()),
        expect: () => [AuthUnauthenticated()],
      );
    });
  });
}
