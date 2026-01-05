import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moneypod/bloc/savings/savings_bloc.dart';
import 'package:moneypod/bloc/savings/savings_event.dart';
import 'package:moneypod/bloc/savings/savings_state.dart';
import 'package:moneypod/models/savings_goal.dart';
import 'package:moneypod/repositories/savings_repository.dart';

class MockSavingsRepository extends Mock implements SavingsRepository {}

void main() {
  late MockSavingsRepository mockRepository;

  final testGoals = [
    SavingsGoal(
      id: '1',
      userId: 'user1',
      name: 'Vacation',
      targetAmount: 10000000,
      currentAmount: 5000000,
      status: 'IN_PROGRESS',
      isOverdue: false,
      createdAt: DateTime.now(),
    ),
    SavingsGoal(
      id: '2',
      userId: 'user1',
      name: 'New Phone',
      targetAmount: 20000000,
      currentAmount: 15000000,
      status: 'IN_PROGRESS',
      isOverdue: false,
      createdAt: DateTime.now(),
    ),
  ];

  setUp(() {
    mockRepository = MockSavingsRepository();
  });

  group('SavingsBloc', () {
    test('initial state is SavingsInitial', () {
      final bloc = SavingsBloc(mockRepository);
      expect(bloc.state, isA<SavingsInitial>());
    });

    group('LoadSavingsGoals', () {
      blocTest<SavingsBloc, SavingsState>(
        'emits [SavingsLoading, SavingsLoaded] when load succeeds',
        build: () {
          when(
            () => mockRepository.getSavingsGoals(),
          ).thenAnswer((_) async => testGoals);
          return SavingsBloc(mockRepository);
        },
        act: (bloc) => bloc.add(LoadSavingsGoals()),
        expect: () => [
          isA<SavingsLoading>(),
          isA<SavingsLoaded>().having((s) => s.goals, 'goals', hasLength(2)),
        ],
      );

      blocTest<SavingsBloc, SavingsState>(
        'emits [SavingsLoading, SavingsError] when load fails',
        build: () {
          when(
            () => mockRepository.getSavingsGoals(),
          ).thenThrow(Exception('Load failed'));
          return SavingsBloc(mockRepository);
        },
        act: (bloc) => bloc.add(LoadSavingsGoals()),
        expect: () => [isA<SavingsLoading>(), isA<SavingsError>()],
      );
    });

    group('CreateSavingsGoal', () {
      blocTest<SavingsBloc, SavingsState>(
        'emits [SavingsLoading, SavingsActionSuccess] when create succeeds',
        build: () {
          when(
            () => mockRepository.createSavingsGoal(
              name: any(named: 'name'),
              targetAmount: any(named: 'targetAmount'),
              color: any(named: 'color'),
              icon: any(named: 'icon'),
              deadline: any(named: 'deadline'),
            ),
          ).thenAnswer((_) async => {});
          when(
            () => mockRepository.getSavingsGoals(),
          ).thenAnswer((_) async => testGoals);
          return SavingsBloc(mockRepository);
        },
        act: (bloc) => bloc.add(
          CreateSavingsGoal(name: 'New Goal', targetAmount: 5000000),
        ),
        expect: () => [
          isA<SavingsLoading>(),
          isA<SavingsActionSuccess>().having(
            (s) => s.message,
            'message',
            contains('thành công'),
          ),
        ],
      );
    });

    group('DepositToGoal', () {
      blocTest<SavingsBloc, SavingsState>(
        'emits [SavingsLoading, SavingsActionSuccess] on normal deposit',
        build: () {
          when(
            () => mockRepository.depositToGoal(
              goalId: any(named: 'goalId'),
              walletId: any(named: 'walletId'),
              amount: any(named: 'amount'),
              note: any(named: 'note'),
            ),
          ).thenAnswer((_) async => {'status': 'IN_PROGRESS'});
          when(
            () => mockRepository.getSavingsGoals(),
          ).thenAnswer((_) async => testGoals);
          return SavingsBloc(mockRepository);
        },
        act: (bloc) => bloc.add(
          DepositToGoal(goalId: '1', walletId: 'w1', amount: 100000),
        ),
        expect: () => [isA<SavingsLoading>(), isA<SavingsActionSuccess>()],
      );

      blocTest<SavingsBloc, SavingsState>(
        'emits [SavingsLoading, SavingsGoalCompleted] when goal completed',
        build: () {
          when(
            () => mockRepository.depositToGoal(
              goalId: any(named: 'goalId'),
              walletId: any(named: 'walletId'),
              amount: any(named: 'amount'),
              note: any(named: 'note'),
            ),
          ).thenAnswer(
            (_) async => {'status': 'COMPLETED', 'message': '🎉 Hoàn thành!'},
          );
          when(
            () => mockRepository.getSavingsGoals(),
          ).thenAnswer((_) async => testGoals);
          return SavingsBloc(mockRepository);
        },
        act: (bloc) => bloc.add(
          DepositToGoal(
            goalId: '1',
            walletId: 'w1',
            amount: 5000000, // Completes the goal
          ),
        ),
        expect: () => [isA<SavingsLoading>(), isA<SavingsGoalCompleted>()],
      );
    });

    group('WithdrawFromGoal', () {
      blocTest<SavingsBloc, SavingsState>(
        'emits [SavingsLoading, SavingsActionSuccess] on withdraw',
        build: () {
          when(
            () => mockRepository.withdrawFromGoal(
              goalId: any(named: 'goalId'),
              walletId: any(named: 'walletId'),
              amount: any(named: 'amount'),
              note: any(named: 'note'),
            ),
          ).thenAnswer((_) async => {});
          when(
            () => mockRepository.getSavingsGoals(),
          ).thenAnswer((_) async => testGoals);
          return SavingsBloc(mockRepository);
        },
        act: (bloc) => bloc.add(
          WithdrawFromGoal(goalId: '1', walletId: 'w1', amount: 500000),
        ),
        expect: () => [isA<SavingsLoading>(), isA<SavingsActionSuccess>()],
      );
    });

    group('UpdateSavingsGoal', () {
      blocTest<SavingsBloc, SavingsState>(
        'emits [SavingsLoading, SavingsActionSuccess] on update',
        build: () {
          when(
            () => mockRepository.updateSavingsGoal(
              goalId: any(named: 'goalId'),
              name: any(named: 'name'),
              color: any(named: 'color'),
              icon: any(named: 'icon'),
              targetAmount: any(named: 'targetAmount'),
              deadline: any(named: 'deadline'),
            ),
          ).thenAnswer((_) async => {});
          when(
            () => mockRepository.getSavingsGoals(),
          ).thenAnswer((_) async => testGoals);
          return SavingsBloc(mockRepository);
        },
        act: (bloc) => bloc.add(
          UpdateSavingsGoal(
            goalId: '1',
            name: 'Updated Goal',
            targetAmount: 15000000,
          ),
        ),
        expect: () => [isA<SavingsLoading>(), isA<SavingsActionSuccess>()],
      );
    });

    group('DeleteSavingsGoal', () {
      blocTest<SavingsBloc, SavingsState>(
        'emits [SavingsLoading, SavingsDeleteSuccess] on delete',
        build: () {
          when(
            () => mockRepository.deleteSavingsGoal('1'),
          ).thenAnswer((_) async => {});
          return SavingsBloc(mockRepository);
        },
        act: (bloc) => bloc.add(const DeleteSavingsGoal('1')),
        expect: () => [isA<SavingsLoading>(), isA<SavingsDeleteSuccess>()],
      );
    });

    group('LoadGoalTransactions', () {
      blocTest<SavingsBloc, SavingsState>(
        'emits [SavingsLoading, SavingsTransactionsLoaded] on load',
        build: () {
          when(
            () => mockRepository.getGoalTransactions('1'),
          ).thenAnswer((_) async => []);
          return SavingsBloc(mockRepository);
        },
        act: (bloc) => bloc.add(const LoadGoalTransactions('1')),
        expect: () => [isA<SavingsLoading>(), isA<SavingsTransactionsLoaded>()],
      );
    });

    group('ResetSavings', () {
      blocTest<SavingsBloc, SavingsState>(
        'emits [SavingsInitial] on reset',
        build: () => SavingsBloc(mockRepository),
        seed: () => SavingsLoaded(testGoals),
        act: (bloc) => bloc.add(ResetSavings()),
        expect: () => [isA<SavingsInitial>()],
      );
    });
  });
}
