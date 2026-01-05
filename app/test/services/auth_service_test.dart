import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moneypod/services/auth_service.dart';

class MockDio extends Mock implements Dio {}

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late AuthService authService;
  late MockDio mockDio;
  late MockFlutterSecureStorage mockStorage;

  setUp(() {
    mockDio = MockDio();
    mockStorage = MockFlutterSecureStorage();
    // Mock base options accessor
    when(() => mockDio.options).thenReturn(BaseOptions());

    authService = AuthService(dio: mockDio, secureStorage: mockStorage);
  });

  group('AuthService', () {
    const email = 'test@example.com';
    const password = 'password123';
    const fullName = 'Test User';

    group('register', () {
      test('should return success map when API returns 201', () async {
        when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/register'),
            statusCode: 201,
            data: {'message': 'Registered successfully'},
          ),
        );

        final result = await authService.register(
          email: email,
          password: password,
          fullName: fullName,
        );

        expect(result['success'], isTrue);
        expect(result['message'], 'Registered successfully');
      });

      test('should return failure map on API error', () async {
        when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/register'),
            statusCode: 400,
            data: {'error': 'Email exists'},
          ),
        );

        final result = await authService.register(
          email: email,
          password: password,
          fullName: fullName,
        );

        expect(result['success'], isFalse);
        expect(result['message'], 'Email exists');
      });
    });

    group('login', () {
      test('writes token to storage on success', () async {
        when(
          () => mockStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          ),
        ).thenAnswer((_) async {});

        when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/login'),
            statusCode: 200,
            data: {'token': 'fake_token', 'message': 'Login success'},
          ),
        );

        final result = await authService.login(
          email: email,
          password: password,
        );

        expect(result['success'], isTrue);
        expect(result['token'], 'fake_token');

        verify(
          () => mockStorage.write(key: 'auth_token', value: 'fake_token'),
        ).called(1);
      });

      test('returns failure on 401', () async {
        when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/login'),
            statusCode: 401,
            data: {'error': 'Invalid credentials'},
          ),
        );

        final result = await authService.login(
          email: email,
          password: password,
        );

        expect(result['success'], isFalse);
        verifyNever(
          () => mockStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          ),
        );
      });
    });

    group('token management', () {
      test('getToken reads from storage', () async {
        when(
          () => mockStorage.read(key: 'auth_token'),
        ).thenAnswer((_) async => 'saved_token');

        expect(await authService.getToken(), 'saved_token');
      });

      test('logout deletes from storage', () async {
        when(
          () => mockStorage.delete(key: 'auth_token'),
        ).thenAnswer((_) async {});

        await authService.logout();

        verify(() => mockStorage.delete(key: 'auth_token')).called(1);
      });

      test('isLoggedIn returns true if token exists', () async {
        when(
          () => mockStorage.read(key: 'auth_token'),
        ).thenAnswer((_) async => 'token');

        expect(await authService.isLoggedIn(), isTrue);
      });

      test('isLoggedIn returns false if token is null', () async {
        when(
          () => mockStorage.read(key: 'auth_token'),
        ).thenAnswer((_) async => null);

        expect(await authService.isLoggedIn(), isFalse);
      });
    });
  });
}
