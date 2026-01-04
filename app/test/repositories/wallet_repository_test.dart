import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:moneypod/repositories/wallet_repository.dart';
import 'package:moneypod/services/auth_service.dart';

class MockDio extends Mock implements Dio {}

class MockAuthService extends Mock implements AuthService {}

void main() {
  late MockDio mockDio;
  late MockAuthService mockAuthService;
  late WalletRepository repository;

  setUp(() {
    mockDio = MockDio();
    mockAuthService = MockAuthService();
    repository = WalletRepository(dio: mockDio, authService: mockAuthService);
  });

  group('WalletRepository', () {
    test('createWallet sends correct request', () async {
      when(
        () => mockAuthService.getToken(),
      ).thenAnswer((_) async => 'mock_token_longer_than_20_chars_for_test');
      when(
        () => mockDio.post(
          '/wallets',
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/wallets'),
          statusCode: 200,
          data: {'data': 'success'},
        ),
      );

      await repository.createWallet(name: 'Cash', balance: 500000);

      verify(
        () => mockDio.post(
          '/wallets',
          data: {'name': 'Cash', 'balance': 500000.0},
          options: any(named: 'options'),
        ),
      ).called(1);
    });

    test('getWallets returns list', () async {
      when(
        () => mockAuthService.getToken(),
      ).thenAnswer((_) async => 'mock_token_longer_than_20_chars_for_test');
      when(
        () => mockDio.get('/wallets', options: any(named: 'options')),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/wallets'),
          statusCode: 200,
          data: {
            'data': [
              {'id': 'w1', 'name': 'Cash', 'balance': 1000000, 'type': 'cash'},
            ],
          },
        ),
      );

      final wallets = await repository.getWallets();

      expect(wallets.length, 1);
      expect(wallets.first.name, 'Cash');
    });
  });
}
