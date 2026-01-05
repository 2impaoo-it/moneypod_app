import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:moneypod/repositories/savings_repository.dart';
import 'package:moneypod/services/auth_service.dart';

class MockDio extends Mock implements Dio {}

class MockAuthService extends Mock implements AuthService {}

void main() {
  late MockDio mockDio;
  late MockAuthService mockAuthService;
  late SavingsRepository repository;

  setUp(() {
    mockDio = MockDio();
    mockAuthService = MockAuthService();
    repository = SavingsRepository(dio: mockDio, authService: mockAuthService);
  });

  group('SavingsRepository', () {
    test('getSavingsGoals returns list', () async {
      when(() => mockAuthService.getToken()).thenAnswer((_) async => 'token');
      when(
        () => mockDio.get('/savings', options: any(named: 'options')),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/savings'),
          statusCode: 200,
          data: {
            'data': [
              {
                'id': 's1',
                'name': 'Goal 1',
                'target_amount': 1000,
                'current_amount': 0,
                'status': 'IN_PROGRESS',
              },
            ],
          },
        ),
      );

      final goals = await repository.getSavingsGoals();

      expect(goals.length, 1);
      expect(goals.first.name, 'Goal 1');
    });

    test('depositToGoal sends correct request', () async {
      when(() => mockAuthService.getToken()).thenAnswer((_) async => 'token');
      when(
        () => mockDio.post(
          '/savings/s1/deposit',
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/savings/s1/deposit'),
          statusCode: 200,
          data: {'status': 'IN_PROGRESS', 'message': 'Success'},
        ),
      );

      final result = await repository.depositToGoal(
        goalId: 's1',
        walletId: 'w1',
        amount: 100,
      );

      expect(result['success'], true);
    });
  });
}
