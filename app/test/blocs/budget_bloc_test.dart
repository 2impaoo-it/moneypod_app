import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moneypod/bloc/budget/budget_bloc.dart';
import 'package:moneypod/bloc/budget/budget_event.dart';
import 'package:moneypod/bloc/budget/budget_state.dart';
import 'package:moneypod/models/budget.dart';
import '../mocks/repositories.dart';

void main() {
  late MockBudgetRepository mockRepository;
  late BudgetBloc bloc;

  setUp(() {
    mockRepository = MockBudgetRepository();
    bloc = BudgetBloc(repository: mockRepository);
  });

  tearDown(() {
    bloc.close();
  });

  final testBudgets = [
    Budget(
      id: '1',
      category: 'Food',
      amount: 5000000,
      spent: 1000000,
      month: 1,
      year: 2026,
    ),
  ];

  group('BudgetBloc', () {
    test('initial state is BudgetInitial', () {
      expect(bloc.state, equals(BudgetInitial()));
    });

    blocTest<BudgetBloc, BudgetState>(
      'emits [BudgetLoading, BudgetLoaded] when BudgetLoadRequested succeeds',
      build: () {
        when(
          () => mockRepository.getBudgets(any(), any()),
        ).thenAnswer((_) async => testBudgets);
        return bloc;
      },
      act: (bloc) => bloc.add(const BudgetLoadRequested(month: 1, year: 2026)),
      expect: () => [
        BudgetLoading(),
        BudgetLoaded(budgets: testBudgets, month: 1, year: 2026),
      ],
    );

    blocTest<BudgetBloc, BudgetState>(
      'emits [BudgetLoading, BudgetError] when BudgetLoadRequested fails',
      build: () {
        when(
          () => mockRepository.getBudgets(any(), any()),
        ).thenThrow(Exception('API Error'));
        return bloc;
      },
      act: (bloc) => bloc.add(const BudgetLoadRequested(month: 1, year: 2026)),
      expect: () => [
        BudgetLoading(),
        const BudgetError('Exception: API Error'),
      ],
    );

    blocTest<BudgetBloc, BudgetState>(
      'emits [BudgetLoading, BudgetLoaded, BudgetOperationSuccess, BudgetLoaded] when BudgetCreateRequested succeeds',
      build: () {
        when(
          () => mockRepository.createBudget(
            category: any(named: 'category'),
            amount: any(named: 'amount'),
            month: any(named: 'month'),
            year: any(named: 'year'),
          ),
        ).thenAnswer((_) async => testBudgets.first);

        when(
          () => mockRepository.getBudgets(any(), any()),
        ).thenAnswer((_) async => testBudgets);
        return bloc;
      },
      act: (bloc) => bloc.add(
        const BudgetCreateRequested(
          category: 'Food',
          amount: 5000000,
          month: 1,
          year: 2026,
        ),
      ),
      expect: () => [
        BudgetLoading(),
        BudgetLoaded(budgets: testBudgets, month: 1, year: 2026),
        const BudgetOperationSuccess("Tạo ngân sách thành công!"),
        BudgetLoaded(budgets: testBudgets, month: 1, year: 2026),
      ],
    );
  });
}
