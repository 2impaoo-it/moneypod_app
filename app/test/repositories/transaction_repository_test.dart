import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moneypod/models/transaction.dart' as model;
import 'package:moneypod/repositories/transaction_repository.dart';
import 'package:moneypod/services/auth_service.dart';

class MockDio extends Mock implements Dio {}

class MockAuthService extends Mock implements AuthService {}

class MockResponse extends Mock implements Response {}

void main() {
  late TransactionRepository repository;
  late MockDio mockDio;
  late MockAuthService mockAuthService;

  setUpAll(() {
    registerFallbackValue(Options());
    registerFallbackValue(FormData());
  });

  setUp(() {
    mockDio = MockDio();
    mockAuthService = MockAuthService();

    // Default implementation for Dio.options which is accessed in constructor
    when(() => mockDio.options).thenReturn(BaseOptions());

    repository = TransactionRepository(
      authService: mockAuthService,
      dio: mockDio,
    );
  });

  group('TransactionRepository', () {
    const userId = 'user1';
    const walletId = 'wallet1';
    const token = 'fake-token';

    group('createTransaction', () {
      test('should call bio.post with correct data', () async {
        when(() => mockAuthService.getToken()).thenAnswer((_) async => token);

        when(
          () => mockDio.post(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/transactions'),
            statusCode: 201,
            data: {'message': 'Success'},
          ),
        );

        await repository.createTransaction(
          walletId: walletId,
          amount: 50000,
          category: 'Food',
          type: 'expense',
          note: 'Lunch',
        );

        verify(
          () => mockDio.post(
            '/transactions',
            data: {
              'wallet_id': walletId,
              'amount': 50000.0,
              'category': 'Food',
              'type': 'expense',
              'note': 'Lunch',
            },
            options: any(named: 'options'),
          ),
        ).called(1);
      });

      test('should throw Exception when auth token is missing', () async {
        when(() => mockAuthService.getToken()).thenAnswer((_) async => null);

        expect(
          () => repository.createTransaction(
            walletId: walletId,
            amount: 50000,
            category: 'Food',
            type: 'expense',
          ),
          throwsException,
        );

        verifyNever(
          () => mockDio.post(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        );
      });

      test('should throw Exception on API error', () async {
        when(() => mockAuthService.getToken()).thenAnswer((_) async => token);

        when(
          () => mockDio.post(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/transactions'),
            statusCode: 400,
            data: {'error': 'Invalid data'},
          ),
        );

        expect(
          () => repository.createTransaction(
            walletId: walletId,
            amount: 50000,
            category: 'Food',
            type: 'expense',
          ),
          throwsException,
        );
      });
    });

    group('getTransactions', () {
      final transactionJson = {
        '_id': 't1',
        'title': 'Test Transaction', // Note: Model might use title or note?
        'amount': 50000,
        'category': 'Food',
        'date': DateTime.now().toIso8601String(),
        'type': 'expense',
        'wallet_id': walletId,
        'user_id': userId,
      };

      test('should return list of transactions on success', () async {
        when(() => mockAuthService.getToken()).thenAnswer((_) async => token);

        when(
          () => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/transactions'),
            statusCode: 200,
            data: {
              'data': [transactionJson],
            },
          ),
        );

        final result = await repository.getTransactions(walletId: walletId);

        expect(result, isA<List<model.Transaction>>());
        expect(result.length, 1);
        expect(result.first.amount, 50000);

        verify(
          () => mockDio.get(
            '/transactions',
            queryParameters: {'wallet_id': walletId},
            options: any(named: 'options'),
          ),
        ).called(1);
      });
    });

    group('deleteTransaction', () {
      test('should call delete successfully', () async {
        when(() => mockAuthService.getToken()).thenAnswer((_) async => token);

        when(
          () => mockDio.delete(any(), options: any(named: 'options')),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/transactions/t1'),
            statusCode: 200,
            data: {'message': 'Deleted'},
          ),
        );

        await repository.deleteTransaction('t1');

        verify(
          () => mockDio.delete(
            '/transactions/t1',
            options: any(named: 'options'),
          ),
        ).called(1);
      });
    });
  });
}
