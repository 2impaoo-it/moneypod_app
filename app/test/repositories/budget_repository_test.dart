import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:moneypod/repositories/budget_repository.dart';
import 'package:moneypod/services/auth_service.dart';

class MockDio extends Mock implements Dio {}

class MockAuthService extends Mock implements AuthService {}

void main() {
  late MockDio mockDio;
  late MockAuthService mockAuthService;
  late BudgetRepository repository;

  setUp(() {
    mockDio = MockDio();
    mockAuthService = MockAuthService();
    repository = BudgetRepository(dio: mockDio, authService: mockAuthService);
  });

  group('BudgetRepository', () {
    test('getBudgets returns list of budgets', () async {
      when(() => mockAuthService.getToken()).thenAnswer((_) async => 'token');
      when(
        () => mockDio.get(
          '/budgets',
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/budgets'),
          statusCode: 200,
          data: {
            'data': [
              {
                'id': '1',
                'category': 'Food',
                'amount': 5000000,
                'spent': 1000000,
                'month': 10,
                'year': 2023,
              },
            ],
          },
        ),
      );

      final budgets = await repository.getBudgets(10, 2023);

      expect(budgets.length, 1);
      expect(budgets.first.category, 'Food');
    });

    test('createBudget sends correct data', () async {
      when(() => mockAuthService.getToken()).thenAnswer((_) async => 'token');
      when(
        () => mockDio.post(
          '/budgets',
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/budgets'),
          statusCode: 200,
          data: {
            'data': {
              'id': '1',
              'category': 'Food',
              'amount': 5000000,
              'month': 10,
              'year': 2023,
            },
          },
        ),
      );

      final budget = await repository.createBudget(
        category: 'Food',
        amount: 5000000,
        month: 10,
        year: 2023,
      );

      expect(budget.amount, 5000000.0);
    });
  });
}
