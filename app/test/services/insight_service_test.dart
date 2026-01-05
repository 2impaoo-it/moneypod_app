import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moneypod/services/insight_service.dart';
import 'package:moneypod/services/auth_service.dart';

class MockDio extends Mock implements Dio {
  @override
  BaseOptions options = BaseOptions(baseUrl: 'https://test.com');
}

class MockAuthService extends Mock implements AuthService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockDio mockDio;
  late MockAuthService mockAuthService;
  late InsightService insightService;

  setUp(() {
    mockDio = MockDio();
    mockAuthService = MockAuthService();
    insightService = InsightService(authService: mockAuthService, dio: mockDio);
  });

  group('InsightService', () {
    test('instance can be created with DI', () {
      expect(insightService, isA<InsightService>());
    });

    test(
      'getMonthlyInsight returns error message when not authenticated',
      () async {
        when(() => mockAuthService.getToken()).thenAnswer((_) async => null);

        final result = await insightService.getMonthlyInsight();

        // Should return error message, not throw
        expect(result, isA<String>());
        expect(result, isNotEmpty);
      },
    );

    test('getMonthlyInsight returns error message on empty token', () async {
      when(() => mockAuthService.getToken()).thenAnswer((_) async => '');

      final result = await insightService.getMonthlyInsight();

      expect(result, isA<String>());
    });

    test('getMonthlyInsight returns insight on successful API call', () async {
      when(
        () => mockAuthService.getToken(),
      ).thenAnswer((_) async => 'valid_token_123456789');

      final now = DateTime.now();
      final lastMonth = DateTime(now.year, now.month - 1, 1);

      when(
        () => mockDio.get(
          '/insights/monthly',
          queryParameters: {'month': lastMonth.month, 'year': lastMonth.year},
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: {'insight': 'Test insight message'},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/insights/monthly'),
        ),
      );

      final result = await insightService.getMonthlyInsight();

      expect(result, equals('Test insight message'));
    });

    test('getMonthlyInsight handles 404 gracefully', () async {
      when(
        () => mockAuthService.getToken(),
      ).thenAnswer((_) async => 'valid_token_123456789');

      final now = DateTime.now();
      final lastMonth = DateTime(now.year, now.month - 1, 1);

      when(
        () => mockDio.get(
          '/insights/monthly',
          queryParameters: {'month': lastMonth.month, 'year': lastMonth.year},
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioException(
          type: DioExceptionType.badResponse,
          response: Response(
            statusCode: 404,
            requestOptions: RequestOptions(path: '/insights/monthly'),
          ),
          requestOptions: RequestOptions(path: '/insights/monthly'),
        ),
      );

      final result = await insightService.getMonthlyInsight();

      expect(result, contains('đang được cập nhật'));
    });

    test('getMonthlyInsight handles timeout gracefully', () async {
      when(
        () => mockAuthService.getToken(),
      ).thenAnswer((_) async => 'valid_token_123456789');

      final now = DateTime.now();
      final lastMonth = DateTime(now.year, now.month - 1, 1);

      when(
        () => mockDio.get(
          '/insights/monthly',
          queryParameters: {'month': lastMonth.month, 'year': lastMonth.year},
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioException(
          type: DioExceptionType.receiveTimeout,
          requestOptions: RequestOptions(path: '/insights/monthly'),
        ),
      );

      final result = await insightService.getMonthlyInsight();

      expect(result, contains('đang được tạo'));
    });
  });

  group('clearOldCache', () {
    test('does not throw', () async {
      await expectLater(insightService.clearOldCache(), completes);
    });
  });
}
