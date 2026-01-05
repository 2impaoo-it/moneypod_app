import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moneypod/bloc/budget/budget_bloc.dart';
import 'package:moneypod/bloc/budget/budget_event.dart';
import 'package:moneypod/bloc/budget/budget_state.dart';
import 'package:moneypod/models/budget.dart';
import 'package:moneypod/repositories/budget_repository.dart';

class MockBudgetRepository extends Mock implements BudgetRepository {}

void main() {
  late MockBudgetRepository mockRepository;

  final testBudgets = [
    Budget(
      id: '1',
      category: 'Ăn uống',
      amount: 5000000,
      spent: 2000000,
      month: 1,
      year: 2026,
    ),
    Budget(
      id: '2',
      category: 'Di chuyển',
      amount: 2000000,
      spent: 500000,
      month: 1,
      year: 2026,
    ),
  ];

  setUp(() {
    mockRepository = MockBudgetRepository();
  });

  group('BudgetBloc', () {
    test('initial state is BudgetInitial', () {
      final bloc = BudgetBloc(repository: mockRepository);
      expect(bloc.state, isA<BudgetInitial>());
    });

    group('BudgetLoadRequested', () {
      blocTest<BudgetBloc, BudgetState>(
        'emits [BudgetLoading, BudgetLoaded] when load succeeds',
        build: () {
          when(
            () => mockRepository.getBudgets(1, 2026),
          ).thenAnswer((_) async => testBudgets);
          return BudgetBloc(repository: mockRepository);
        },
        act: (bloc) =>
            bloc.add(const BudgetLoadRequested(month: 1, year: 2026)),
        expect: () => [
          isA<BudgetLoading>(),
          isA<BudgetLoaded>().having((s) => s.budgets, 'budgets', hasLength(2)),
        ],
        verify: (_) {
          verify(() => mockRepository.getBudgets(1, 2026)).called(1);
        },
      );

      blocTest<BudgetBloc, BudgetState>(
        'emits [BudgetLoading, BudgetError] when load fails',
        build: () {
          when(
            () => mockRepository.getBudgets(any(), any()),
          ).thenThrow(Exception('Load failed'));
          return BudgetBloc(repository: mockRepository);
        },
        act: (bloc) =>
            bloc.add(const BudgetLoadRequested(month: 1, year: 2026)),
        expect: () => [
          isA<BudgetLoading>(),
          isA<BudgetError>().having(
            (e) => e.message,
            'message',
            contains('Load failed'),
          ),
        ],
      );

      blocTest<BudgetBloc, BudgetState>(
        'returns empty list when no budgets exist',
        build: () {
          when(
            () => mockRepository.getBudgets(any(), any()),
          ).thenAnswer((_) async => []);
          return BudgetBloc(repository: mockRepository);
        },
        act: (bloc) =>
            bloc.add(const BudgetLoadRequested(month: 12, year: 2025)),
        expect: () => [
          isA<BudgetLoading>(),
          isA<BudgetLoaded>().having((s) => s.budgets, 'budgets', isEmpty),
        ],
      );
    });

    group('BudgetCreateRequested', () {
      blocTest<BudgetBloc, BudgetState>(
        'emits states in correct order when create succeeds',
        build: () {
          when(
            () => mockRepository.createBudget(
              category: 'Giải trí',
              amount: 1000000,
              month: 1,
              year: 2026,
            ),
          ).thenAnswer(
            (_) async => Budget(
              id: 'new-id',
              category: 'Giải trí',
              amount: 1000000,
              spent: 0,
              month: 1,
              year: 2026,
            ),
          );
          when(
            () => mockRepository.getBudgets(1, 2026),
          ).thenAnswer((_) async => testBudgets);
          return BudgetBloc(repository: mockRepository);
        },
        act: (bloc) => bloc.add(
          const BudgetCreateRequested(
            category: 'Giải trí',
            amount: 1000000,
            month: 1,
            year: 2026,
          ),
        ),
        expect: () => [
          isA<BudgetLoading>(),
          isA<BudgetLoaded>(),
          isA<BudgetOperationSuccess>().having(
            (s) => s.message,
            'message',
            contains('thành công'),
          ),
          isA<BudgetLoaded>(),
        ],
      );

      blocTest<BudgetBloc, BudgetState>(
        'emits error then reloads list when create fails',
        build: () {
          when(
            () => mockRepository.createBudget(
              category: any(named: 'category'),
              amount: any(named: 'amount'),
              month: any(named: 'month'),
              year: any(named: 'year'),
            ),
          ).thenThrow(Exception('Create failed'));
          when(
            () => mockRepository.getBudgets(any(), any()),
          ).thenAnswer((_) async => testBudgets);
          return BudgetBloc(repository: mockRepository);
        },
        act: (bloc) => bloc.add(
          const BudgetCreateRequested(
            category: 'Test',
            amount: 500000,
            month: 1,
            year: 2026,
          ),
        ),
        expect: () => [
          isA<BudgetLoading>(),
          isA<BudgetError>(),
          isA<BudgetLoaded>(), // Reloaded after error
        ],
      );
    });

    group('BudgetUpdateRequested', () {
      blocTest<BudgetBloc, BudgetState>(
        'emits success states when update succeeds',
        build: () {
          when(
            () => mockRepository.updateBudget(
              id: '1',
              amount: 6000000,
              category: 'Ăn uống',
            ),
          ).thenAnswer((_) async => {});
          when(
            () => mockRepository.getBudgets(1, 2026),
          ).thenAnswer((_) async => testBudgets);
          return BudgetBloc(repository: mockRepository);
        },
        act: (bloc) => bloc.add(
          const BudgetUpdateRequested(
            id: '1',
            category: 'Ăn uống',
            amount: 6000000,
            month: 1,
            year: 2026,
          ),
        ),
        expect: () => [
          isA<BudgetLoading>(),
          isA<BudgetLoaded>(),
          isA<BudgetOperationSuccess>(),
          isA<BudgetLoaded>(),
        ],
      );
    });

    group('BudgetDeleteRequested', () {
      blocTest<BudgetBloc, BudgetState>(
        'emits success states when delete succeeds',
        build: () {
          when(
            () => mockRepository.deleteBudget('1'),
          ).thenAnswer((_) async => {});
          when(
            () => mockRepository.getBudgets(1, 2026),
          ).thenAnswer((_) async => [testBudgets[1]]); // One less
          return BudgetBloc(repository: mockRepository);
        },
        act: (bloc) => bloc.add(
          const BudgetDeleteRequested(id: '1', month: 1, year: 2026),
        ),
        expect: () => [
          isA<BudgetLoading>(),
          isA<BudgetLoaded>().having((s) => s.budgets, 'budgets', hasLength(1)),
          isA<BudgetOperationSuccess>(),
          isA<BudgetLoaded>(),
        ],
      );

      blocTest<BudgetBloc, BudgetState>(
        'emits error then reloads when delete fails',
        build: () {
          when(
            () => mockRepository.deleteBudget(any()),
          ).thenThrow(Exception('Delete failed'));
          when(
            () => mockRepository.getBudgets(any(), any()),
          ).thenAnswer((_) async => testBudgets);
          return BudgetBloc(repository: mockRepository);
        },
        act: (bloc) => bloc.add(
          const BudgetDeleteRequested(id: '1', month: 1, year: 2026),
        ),
        expect: () => [
          isA<BudgetLoading>(),
          isA<BudgetError>(),
          isA<BudgetLoaded>(),
        ],
      );
    });
  });
}
