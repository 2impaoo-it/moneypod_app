import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moneypod/services/auth_service.dart';

class MockDio extends Mock implements Dio {}

class MockResponse extends Mock implements Response {}

// Note: AuthService instantiates FlutterSecureStorage directly as top-level const or final field.
// To test calls to storage, we might need to rely on the fact that FlutterSecureStorage
// uses MethodChannels, and we can mock the channel.
// However, AuthService has storage as a public final field? No, it's public final.
// We can't inject it easily without refactoring AuthService constructor.
// But we can check if AuthService allows injecting Dio.
// Constructor: AuthService({Dio? dio})
// So Dio key logic can be tested. Storage logic is secondary or integration test.
// We will focus on API calls.

void main() {
  late AuthService authService;
  late MockDio mockDio;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized(); // Required for MethodChannels if needed
  });

  setUp(() {
    mockDio = MockDio();
    // Mock base options accessor
    when(() => mockDio.options).thenReturn(BaseOptions());

    authService = AuthService(dio: mockDio);
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

        verify(
          () => mockDio.post(
            '/register',
            data: {'email': email, 'password': password, 'full_name': fullName},
          ),
        ).called(1);
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
  });
}
