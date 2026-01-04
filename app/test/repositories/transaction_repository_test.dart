import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
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
  });

  group('TransactionRepository', () {
    test('createTransaction sends correct data', () async {
      when(() => mockAuthService.getToken()).thenAnswer((_) async => 'token');
      when(
        () => mockDio.post(
          '/transactions',
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/transactions'),
          statusCode: 200,
          data: {'data': 'success'},
        ),
      );

      await repository.createTransaction(
        walletId: 'w1',
        amount: 100000,
        category: 'Food',
        type: 'expense',
      );

      verify(
        () => mockDio.post(
          '/transactions',
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).called(1);
    });

    test('getTransactions returns list', () async {
      when(() => mockAuthService.getToken()).thenAnswer((_) async => 'token');
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
              {
                'id': 't1',
                'amount': 100000,
                'category': 'Food',
                'type': 'expense',
                'date': '2023-10-27T10:00:00Z',
                'wallet_id': 'w1',
              },
            ],
          },
        ),
      );

      final transactions = await repository.getTransactions();

      expect(transactions.length, 1);
      expect(transactions.first.amount, 100000.0);
    });
  });
}
