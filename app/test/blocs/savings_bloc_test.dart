import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moneypod/bloc/savings/savings_bloc.dart';
import 'package:moneypod/bloc/savings/savings_event.dart';
import 'package:moneypod/bloc/savings/savings_state.dart';
import 'package:moneypod/repositories/savings_repository.dart';
import 'package:moneypod/models/savings_goal.dart';

class MockSavingsRepository extends Mock implements SavingsRepository {}

void main() {
  late MockSavingsRepository mockRepository;

  setUp(() {
    mockRepository = MockSavingsRepository();
  });

  group('SavingsBloc', () {
    final mockGoal = SavingsGoal(
      id: 'g1',
      userId: 'u1',
      name: 'Goal 1',
      targetAmount: 1000,
      currentAmount: 0,
      status: 'IN_PROGRESS',
      createdAt: DateTime.now(),
      deadline: DateTime.now().add(const Duration(days: 30)),
      color: 'blue',
      icon: 'star',
      isOverdue: false,
    );

    blocTest<SavingsBloc, SavingsState>(
      'emits [Loading, Loaded] when LoadSavingsGoals is added',
      build: () {
        when(
          () => mockRepository.getSavingsGoals(),
        ).thenAnswer((_) async => [mockGoal]);
        return SavingsBloc(mockRepository);
      },
      act: (bloc) => bloc.add(LoadSavingsGoals()),
      expect: () => [isA<SavingsLoading>(), isA<SavingsLoaded>()],
    );

    blocTest<SavingsBloc, SavingsState>(
      'emits ActionSuccess when CreateSavingsGoal succeeds',
      build: () {
        when(
          () => mockRepository.createSavingsGoal(
            name: any(named: 'name'),
            targetAmount: any(named: 'targetAmount'),
            color: any(named: 'color'),
            icon: any(named: 'icon'),
            deadline: any(named: 'deadline'),
          ),
        ).thenAnswer((_) async {});
        when(
          () => mockRepository.getSavingsGoals(),
        ).thenAnswer((_) async => [mockGoal]);
        return SavingsBloc(mockRepository);
      },
      act: (bloc) => bloc.add(
        CreateSavingsGoal(
          name: 'New Goal',
          targetAmount: 5000,
          color: 'red',
          icon: 'home',
          deadline: DateTime.now(),
        ),
      ),
      expect: () => [isA<SavingsLoading>(), isA<SavingsActionSuccess>()],
    );
  });
}
