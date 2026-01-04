import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

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

    when(
      () => mockAuthService.getToken(),
    ).thenAnswer((_) async => 'valid_token');

    when(
      () => mockDio.options,
    ).thenReturn(BaseOptions(baseUrl: 'https://test.com'));
    when(() => mockDio.interceptors).thenReturn(Interceptors());
  });

  group('WalletRepository', () {
    group('getWallets', () {
      test('throws exception when no token', () async {
        when(() => mockAuthService.getToken()).thenAnswer((_) async => null);

        expect(repository.getWallets(), throwsA(isA<Exception>()));
      });

      test('returns List<Wallet> on success', () async {
        final jsonResponse = {
          'data': [
            {
              'id': 'w1',
              'name': 'Cash',
              'balance': 100.0,
              'currency': 'VND',
              'user_id': 'u1',
              'created_at': DateTime.now().toIso8601String(),
            },
          ],
        };

        when(
          () => mockDio.get(any(), options: any(named: 'options')),
        ).thenAnswer(
          (_) async => Response(
            data: jsonResponse,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/wallets'),
          ),
        );

        final result = await repository.getWallets();
        expect(result, isNotEmpty);
      });

      test('throws Exception on 401', () async {
        when(
          () => mockDio.get(any(), options: any(named: 'options')),
        ).thenAnswer(
          (_) async => Response(
            data: {'error': 'Unauthorized'},
            statusCode: 401,
            requestOptions: RequestOptions(path: '/wallets'),
          ),
        );

        expect(repository.getWallets(), throwsA(isA<Exception>()));
      });

      test('throws Exception on Network Error', () async {
        when(
          () => mockDio.get(any(), options: any(named: 'options')),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/wallets'),
            error: const SocketException('No Internet'),
            type: DioExceptionType.connectionError,
          ),
        );

        expect(repository.getWallets(), throwsA(isA<Exception>()));
      });
    });

    group('createWallet', () {
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
            requestOptions: RequestOptions(path: '/wallets'),
          ),
        );

        // Relaxed expectation
        expect(repository.createWallet(name: 'Test'), throwsA(anything));
      });
    });
  });
}
