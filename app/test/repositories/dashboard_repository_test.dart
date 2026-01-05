import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moneypod/repositories/dashboard_repository.dart';
import 'package:moneypod/services/auth_service.dart';

class MockDio extends Mock implements Dio {
  @override
  BaseOptions get options => BaseOptions(baseUrl: 'https://test.com');
}

class MockAuthService extends Mock implements AuthService {}

void main() {
  late MockDio mockDio;
  late MockAuthService mockAuthService;
  late DashboardRepository repository;

  setUp(() {
    mockDio = MockDio();
    mockAuthService = MockAuthService();
    repository = DashboardRepository(
      authService: mockAuthService,
      dio: mockDio,
    );
  });

  group('DashboardRepository', () {
    group('getDashboardData', () {
      test('returns DashboardData on successful response', () async {
        when(
          () => mockAuthService.getToken(),
        ).thenAnswer((_) async => 'valid_token');
        when(
          () => mockDio.get('/dashboard', options: any(named: 'options')),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/dashboard'),
            statusCode: 200,
            data: {
              'data': {
                'user_info': {'email': 'test@example.com'},
                'total_balance': 10000000.0,
                'wallets': [],
                'recent_transactions': [],
              },
            },
          ),
        );

        final result = await repository.getDashboardData();

        expect(result.userInfo.email, 'test@example.com');
        expect(result.totalBalance, 10000000.0);
        verify(() => mockAuthService.getToken()).called(1);
      });

      test('throws exception when no token', () async {
        when(() => mockAuthService.getToken()).thenAnswer((_) async => null);

        expect(
          () => repository.getDashboardData(),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('đăng nhập'),
            ),
          ),
        );
      });

      test('throws exception on non-200 status', () async {
        when(
          () => mockAuthService.getToken(),
        ).thenAnswer((_) async => 'valid_token');
        when(
          () => mockDio.get('/dashboard', options: any(named: 'options')),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/dashboard'),
            statusCode: 401,
            data: {'error': 'Unauthorized'},
          ),
        );

        expect(() => repository.getDashboardData(), throwsA(isA<Exception>()));
      });

      test('handles DioException with error response', () async {
        when(
          () => mockAuthService.getToken(),
        ).thenAnswer((_) async => 'valid_token');
        when(
          () => mockDio.get('/dashboard', options: any(named: 'options')),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/dashboard'),
            response: Response(
              requestOptions: RequestOptions(path: '/dashboard'),
              statusCode: 500,
              data: {'error': 'Server error'},
            ),
          ),
        );

        expect(() => repository.getDashboardData(), throwsA(isA<Exception>()));
      });
    });

    group('getTransactionsWithFilter', () {
      test('returns transactions on successful response', () async {
        when(
          () => mockAuthService.getToken(),
        ).thenAnswer((_) async => 'valid_token');
        when(
          () => mockDio.get(
            '/transactions',
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/transactions'),
            statusCode: 200,
            data: {
              'data': [
                {'id': '1', 'title': 'Test', 'amount': 50000},
                {'id': '2', 'title': 'Test2', 'amount': 100000},
              ],
            },
          ),
        );

        final result = await repository.getTransactionsWithFilter(
          month: 1,
          year: 2026,
          type: 'expense',
        );

        expect(result, hasLength(2));
        expect(result[0]['title'], 'Test');
      });

      test('returns empty list when no token', () async {
        when(() => mockAuthService.getToken()).thenAnswer((_) async => null);

        final result = await repository.getTransactionsWithFilter();

        expect(result, isEmpty);
      });

      test('returns empty list on error', () async {
        when(
          () => mockAuthService.getToken(),
        ).thenAnswer((_) async => 'valid_token');
        when(
          () => mockDio.get(
            '/transactions',
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          ),
        ).thenThrow(Exception('Network error'));

        final result = await repository.getTransactionsWithFilter();

        expect(result, isEmpty);
      });

      test('passes correct query parameters', () async {
        when(
          () => mockAuthService.getToken(),
        ).thenAnswer((_) async => 'valid_token');
        when(
          () => mockDio.get(
            '/transactions',
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/transactions'),
            statusCode: 200,
            data: {'data': []},
          ),
        );

        await repository.getTransactionsWithFilter(
          month: 6,
          year: 2026,
          category: 'Ăn uống',
          type: 'expense',
          page: 2,
          pageSize: 50,
        );

        verify(
          () => mockDio.get(
            '/transactions',
            queryParameters: {
              'page': 2,
              'page_size': 50,
              'month': 6,
              'year': 2026,
              'category': 'Ăn uống',
              'type': 'expense',
            },
            options: any(named: 'options'),
          ),
        ).called(1);
      });
    });
  });
}
