import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moneypod/repositories/wallet_repository.dart';
import 'package:moneypod/services/auth_service.dart';

class MockDio extends Mock implements Dio {
  @override
  BaseOptions get options => BaseOptions(baseUrl: 'https://test.com');
}

class MockAuthService extends Mock implements AuthService {}

void main() {
  late MockDio mockDio;
  late MockAuthService mockAuthService;
  late WalletRepository repository;

  final now = DateTime.now();

  setUp(() {
    mockDio = MockDio();
    mockAuthService = MockAuthService();
    repository = WalletRepository(authService: mockAuthService, dio: mockDio);
  });

  group('WalletRepository', () {
    group('getWallets', () {
      test('returns list of wallets on success', () async {
        when(
          () => mockAuthService.getToken(),
        ).thenAnswer((_) async => 'valid_token');
        when(
          () => mockDio.get('/wallets', options: any(named: 'options')),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/wallets'),
            statusCode: 200,
            data: {
              'data': [
                {
                  'id': '1',
                  'name': 'Cash',
                  'balance': 5000000,
                  'currency': 'VND',
                  'user_id': 'user1',
                  'created_at': now.toIso8601String(),
                },
                {
                  'id': '2',
                  'name': 'Bank',
                  'balance': 10000000,
                  'currency': 'VND',
                  'user_id': 'user1',
                  'created_at': now.toIso8601String(),
                },
              ],
            },
          ),
        );

        final result = await repository.getWallets();

        expect(result, hasLength(2));
        expect(result[0].name, 'Cash');
        expect(result[1].name, 'Bank');
      });

      test('throws exception when no token', () async {
        when(() => mockAuthService.getToken()).thenAnswer((_) async => null);

        expect(() => repository.getWallets(), throwsA(isA<Exception>()));
      });

      test('handles DioException', () async {
        when(
          () => mockAuthService.getToken(),
        ).thenAnswer((_) async => 'valid_token');
        when(
          () => mockDio.get('/wallets', options: any(named: 'options')),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/wallets'),
            response: Response(
              requestOptions: RequestOptions(path: '/wallets'),
              statusCode: 500,
              data: {'error': 'Server error'},
            ),
          ),
        );

        expect(() => repository.getWallets(), throwsA(isA<Exception>()));
      });
    });

    group('createWallet', () {
      test('creates wallet successfully', () async {
        when(
          () => mockAuthService.getToken(),
        ).thenAnswer((_) async => 'valid_token');
        when(
          () => mockDio.post(
            '/wallets',
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/wallets'),
            statusCode: 201,
            data: {
              'data': {
                'id': 'new-id',
                'name': 'New Wallet',
                'balance': 1000000,
                'currency': 'VND',
                'user_id': 'user1',
                'created_at': now.toIso8601String(),
              },
            },
          ),
        );

        // Should not throw and verify call was made
        await repository.createWallet(name: 'New Wallet', balance: 1000000);

        verify(
          () => mockDio.post(
            '/wallets',
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        ).called(1);
      });

      test('throws exception when no token', () async {
        when(() => mockAuthService.getToken()).thenAnswer((_) async => null);

        expect(
          () => repository.createWallet(name: 'Test'),
          throwsA(isA<Exception>()),
        );
      });

      test('throws exception on server error', () async {
        when(
          () => mockAuthService.getToken(),
        ).thenAnswer((_) async => 'valid_token');
        when(
          () => mockDio.post(
            '/wallets',
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/wallets'),
            statusCode: 400,
            data: {'error': 'Invalid data'},
          ),
        );

        expect(
          () => repository.createWallet(name: 'Test'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('updateWallet', () {
      test('updates wallet successfully', () async {
        when(
          () => mockAuthService.getToken(),
        ).thenAnswer((_) async => 'valid_token');
        when(
          () => mockDio.put(
            '/wallets/1',
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/wallets/1'),
            statusCode: 200,
            data: {'message': 'Updated'},
          ),
        );

        // Should not throw
        await repository.updateWallet(id: '1', name: 'Updated Name');

        verify(
          () => mockDio.put(
            '/wallets/1',
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        ).called(1);
      });
    });

    group('deleteWallet', () {
      test('deletes wallet successfully', () async {
        when(
          () => mockAuthService.getToken(),
        ).thenAnswer((_) async => 'valid_token');
        when(
          () => mockDio.delete('/wallets/1', options: any(named: 'options')),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/wallets/1'),
            statusCode: 200,
            data: {'message': 'Deleted'},
          ),
        );

        // Should not throw
        await repository.deleteWallet('1');

        verify(
          () => mockDio.delete('/wallets/1', options: any(named: 'options')),
        ).called(1);
      });
    });

    group('transferBetweenWallets', () {
      test('transfers money successfully', () async {
        when(
          () => mockAuthService.getToken(),
        ).thenAnswer((_) async => 'valid_token');
        when(
          () => mockDio.post(
            '/wallets/transfer',
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/wallets/transfer'),
            statusCode: 200,
            data: {'message': 'Transfer successful'},
          ),
        );

        await repository.transferBetweenWallets(
          fromWalletId: 'wallet1',
          toWalletId: 'wallet2',
          amount: 500000,
          note: 'Test transfer',
        );

        verify(
          () => mockDio.post(
            '/wallets/transfer',
            data: {
              'from_wallet_id': 'wallet1',
              'to_wallet_id': 'wallet2',
              'amount': 500000,
              'note': 'Test transfer',
            },
            options: any(named: 'options'),
          ),
        ).called(1);
      });

      test('throws exception on transfer failure', () async {
        when(
          () => mockAuthService.getToken(),
        ).thenAnswer((_) async => 'valid_token');
        when(
          () => mockDio.post(
            '/wallets/transfer',
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/wallets/transfer'),
            response: Response(
              requestOptions: RequestOptions(path: '/wallets/transfer'),
              statusCode: 400,
              data: {'error': 'Insufficient balance'},
            ),
          ),
        );

        expect(
          () => repository.transferBetweenWallets(
            fromWalletId: 'wallet1',
            toWalletId: 'wallet2',
            amount: 500000,
          ),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
