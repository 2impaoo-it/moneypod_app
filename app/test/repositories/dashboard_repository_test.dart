import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:moneypod/repositories/dashboard_repository.dart';
import 'package:moneypod/services/auth_service.dart';

class MockDio extends Mock implements Dio {}

class MockAuthService extends Mock implements AuthService {}

void main() {
  late MockDio mockDio;
  late MockAuthService mockAuthService;
  late DashboardRepository repository;

  setUp(() {
    mockDio = MockDio();
    mockAuthService = MockAuthService();
    repository = DashboardRepository(
      dio: mockDio,
      authService: mockAuthService,
    );
  });

  group('DashboardRepository', () {
    test('getDashboardData parses response correctly', () async {
      when(() => mockAuthService.getToken()).thenAnswer((_) async => 'token');
      when(
        () => mockDio.get('/dashboard', options: any(named: 'options')),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/dashboard'),
          statusCode: 200,
          data: {
            'data': {
              'user_info': {'id': 'u1', 'email': 'test@test.com'},
              'total_balance': 1000000,
              'wallets': [],
              'recent_transactions': [],
            },
          },
        ),
      );

      final data = await repository.getDashboardData();

      expect(data.totalBalance, 1000000.0);
      expect(data.userInfo.id, 'u1');
    });
  });
}
