import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moneypod/models/dashboard_data.dart';

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

    // Default behaviors
    when(
      () => mockAuthService.getToken(),
    ).thenAnswer((_) async => 'valid_token');

    // Fix interceptors getter access
    when(
      () => mockDio.options,
    ).thenReturn(BaseOptions(baseUrl: 'https://test.com'));
    when(() => mockDio.interceptors).thenReturn(Interceptors());
  });

  group('DashboardRepository', () {
    test('throws exception when no token found', () async {
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

    test('returns DashboardData on 200 success', () async {
      final jsonResponse = {
        'data': {
          'user_info': {
            'id': 'u1',
            'email': 'test@test.com',
            'full_name': 'Test',
          },
          'total_balance': 1000000.0,
          'wallets': [],
          'recent_transactions': [],
        },
      };

      when(() => mockDio.get(any(), options: any(named: 'options'))).thenAnswer(
        (_) async => Response(
          data: jsonResponse,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/dashboard'),
        ),
      );

      final result = await repository.getDashboardData();

      expect(result, isA<DashboardData>());
      expect(result.totalBalance, equals(1000000.0));
    });

    test('throws Exception on 401 Unauthorized', () async {
      when(() => mockDio.get(any(), options: any(named: 'options'))).thenAnswer(
        (_) async => Response(
          data: {'error': 'Unauthorized'},
          statusCode: 401,
          requestOptions: RequestOptions(path: '/dashboard'),
        ),
      );

      expect(
        () => repository.getDashboardData(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Unauthorized'),
          ),
        ),
      );
    });

    test('throws Exception on 500 Server Error', () async {
      when(() => mockDio.get(any(), options: any(named: 'options'))).thenAnswer(
        (_) async => Response(
          data: {'error': 'Internal Server Error'},
          statusCode: 500,
          requestOptions: RequestOptions(path: '/dashboard'),
        ),
      );

      expect(
        () => repository.getDashboardData(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Server Error'),
          ),
        ),
      );
    });

    test('throws Exception on Network Error (SocketException)', () async {
      when(() => mockDio.get(any(), options: any(named: 'options'))).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/dashboard'),
          error: const SocketException('No Internet'),
          type: DioExceptionType.connectionError,
        ),
      );

      expect(
        () => repository.getDashboardData(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('kết nối mạng'),
          ),
        ),
      );
    });

    test('throws Exception on Generic DioException', () async {
      when(() => mockDio.get(any(), options: any(named: 'options'))).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/dashboard'),
          response: Response(
            requestOptions: RequestOptions(path: '/dashboard'),
            data: {'error': 'Custom Error'},
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      expect(
        () => repository.getDashboardData(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Custom Error'),
          ),
        ),
      );
    });
  });
}
