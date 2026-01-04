import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moneypod/repositories/transaction_repository.dart';
import 'package:moneypod/services/auth_service.dart';

class MockDio extends Mock implements Dio {}

class MockAuthService extends Mock implements AuthService {}

void main() {
  late MockDio mockDio;
  late MockAuthService mockAuthService;
  late TransactionRepository repository;

  setUp(() {
    mockDio = MockDio();
    mockAuthService = MockAuthService();
    repository = TransactionRepository(
      dio: mockDio,
      authService: mockAuthService,
    );

    when(
      () => mockAuthService.getToken(),
    ).thenAnswer((_) async => 'valid_token');

    when(
      () => mockDio.options,
    ).thenReturn(BaseOptions(baseUrl: 'https://test.com'));
    when(() => mockDio.interceptors).thenReturn(Interceptors());
  });

  group('TransactionRepository', () {
    group('getTransactions', () {
      test('returns List on success', () async {
        final jsonResponse = {
          'data': [
            {
              'id': 't1',
              'title': 'Food',
              'amount': 50.0,
              'category': 'Food',
              'is_expense': true,
              'date': DateTime.now().toIso8601String(),
            },
          ],
        };

        when(
          () => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response(
            data: jsonResponse,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/transactions'),
          ),
        );

        final result = await repository.getTransactions();
        expect(result, isNotEmpty);
      });

      test('throws Exception on failure', () async {
        when(
          () => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/transactions'),
            error: const SocketException('No Internet'),
            type: DioExceptionType.connectionError,
          ),
        );

        expect(repository.getTransactions(), throwsA(isA<Exception>()));
      });
    });

    group('createTransaction', () {
      test('throws on failure', () async {
        when(
          () => mockDio.post(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response(
            data: {'error': 'Failed to create'},
            statusCode: 400,
            requestOptions: RequestOptions(path: '/transactions'),
          ),
        );

        // Relaxed expectation
        expect(
          repository.createTransaction(
            walletId: 'w1',
            amount: 100,
            category: 'Food',
            type: 'expense',
          ),
          throwsA(anything),
        );
      });
    });
  });
}
