import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moneypod/services/api_service.dart';

class MockDio extends Mock implements Dio {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockDio mockDio;
  late ApiService apiService;

  setUp(() {
    mockDio = MockDio();
    apiService = ApiService(dio: mockDio);
  });

  group('ApiService', () {
    test('baseUrl is defined and valid', () {
      expect(ApiService.baseUrl, isNotEmpty);
      expect(ApiService.baseUrl, startsWith('https://'));
      expect(ApiService.baseUrl, contains('/api/v1'));
    });

    test('can be instantiated with DI', () {
      expect(apiService, isA<ApiService>());
    });
  });

  group('checkHealth', () {
    test(
      'returns healthy when server responds with 200 and moneypod message',
      () async {
        when(
          () => mockDio.get(any(), options: any(named: 'options')),
        ).thenAnswer(
          (_) async => Response(
            data: {'message': 'Welcome to MoneyPod API'},
            statusCode: 200,
            requestOptions: RequestOptions(path: '/ping'),
          ),
        );

        final result = await apiService.checkHealth();

        expect(result['isHealthy'], isTrue);
        expect(result['errorType'], isNull);
      },
    );

    test('returns maintenance when server responds with 503', () async {
      when(() => mockDio.get(any(), options: any(named: 'options'))).thenAnswer(
        (_) async => Response(
          data: {'message': 'Server đang bảo trì'},
          statusCode: 503,
          requestOptions: RequestOptions(path: '/ping'),
        ),
      );

      final result = await apiService.checkHealth();

      expect(result['isHealthy'], isFalse);
      expect(result['errorType'], equals('maintenance'));
      expect(result['message'], contains('bảo trì'));
    });

    test(
      'returns maintenance with default message when 503 data is not Map',
      () async {
        when(
          () => mockDio.get(any(), options: any(named: 'options')),
        ).thenAnswer(
          (_) async => Response(
            data: 'string response',
            statusCode: 503,
            requestOptions: RequestOptions(path: '/ping'),
          ),
        );

        final result = await apiService.checkHealth();

        expect(result['isHealthy'], isFalse);
        expect(result['errorType'], equals('maintenance'));
      },
    );

    test(
      'returns unknown when 200 but message does not contain moneypod',
      () async {
        when(
          () => mockDio.get(any(), options: any(named: 'options')),
        ).thenAnswer(
          (_) async => Response(
            data: {'message': 'Hello World'},
            statusCode: 200,
            requestOptions: RequestOptions(path: '/ping'),
          ),
        );

        final result = await apiService.checkHealth();

        expect(result['isHealthy'], isFalse);
        expect(result['errorType'], equals('unknown'));
      },
    );

    test('returns no_internet on SocketException', () async {
      when(() => mockDio.get(any(), options: any(named: 'options'))).thenThrow(
        DioException(
          type: DioExceptionType.unknown,
          error: const SocketException('No internet'),
          requestOptions: RequestOptions(path: '/ping'),
        ),
      );

      final result = await apiService.checkHealth();

      expect(result['isHealthy'], isFalse);
      expect(result['errorType'], equals('no_internet'));
    });

    test('returns no_internet on connectionTimeout', () async {
      when(() => mockDio.get(any(), options: any(named: 'options'))).thenThrow(
        DioException(
          type: DioExceptionType.connectionTimeout,
          requestOptions: RequestOptions(path: '/ping'),
        ),
      );

      final result = await apiService.checkHealth();

      expect(result['isHealthy'], isFalse);
      expect(result['errorType'], equals('no_internet'));
    });

    test('returns unknown on other DioException', () async {
      when(() => mockDio.get(any(), options: any(named: 'options'))).thenThrow(
        DioException(
          type: DioExceptionType.badResponse,
          response: Response(
            data: {'error': 'Bad request'},
            statusCode: 400,
            requestOptions: RequestOptions(path: '/ping'),
          ),
          requestOptions: RequestOptions(path: '/ping'),
        ),
      );

      final result = await apiService.checkHealth();

      expect(result['isHealthy'], isFalse);
      expect(result['errorType'], equals('unknown'));
      expect(result['message'], equals('Bad request'));
    });

    test('returns unknown on general exception', () async {
      when(
        () => mockDio.get(any(), options: any(named: 'options')),
      ).thenThrow(Exception('Unknown error'));

      final result = await apiService.checkHealth();

      expect(result['isHealthy'], isFalse);
      expect(result['errorType'], equals('unknown'));
      expect(result['message'], contains('Unknown error'));
    });

    test('handles null message in response', () async {
      when(() => mockDio.get(any(), options: any(named: 'options'))).thenAnswer(
        (_) async => Response(
          data: {},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/ping'),
        ),
      );

      final result = await apiService.checkHealth();

      expect(result['isHealthy'], isFalse);
      expect(result['errorType'], equals('unknown'));
    });
  });

  group('checkServerHealth (static)', () {
    test('static method exists and returns Future', () {
      expect(ApiService.checkServerHealth, isA<Function>());
    });
  });
}
