import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moneypod/bloc/dashboard/dashboard_bloc.dart';
import 'package:moneypod/bloc/dashboard/dashboard_event.dart';
import 'package:moneypod/bloc/dashboard/dashboard_state.dart';
import 'package:moneypod/models/dashboard_data.dart';
import 'package:moneypod/models/user.dart';
import 'package:moneypod/repositories/dashboard_repository.dart';

class MockDashboardRepository extends Mock implements DashboardRepository {}

void main() {
  late MockDashboardRepository mockRepository;

  final testDashboardData = DashboardData(
    userInfo: const User(email: 'test@example.com', fullName: 'Test User'),
    totalBalance: 10000000,
    wallets: [],
    recentTransactions: [],
  );

  setUp(() {
    mockRepository = MockDashboardRepository();
  });

  group('DashboardBloc', () {
    test('initial state is DashboardInitial', () {
      final bloc = DashboardBloc(repository: mockRepository);
      expect(bloc.state, isA<DashboardInitial>());
    });

    group('DashboardLoadRequested', () {
      blocTest<DashboardBloc, DashboardState>(
        'emits [DashboardLoading, DashboardLoaded] when load succeeds',
        build: () {
          when(
            () => mockRepository.getDashboardData(),
          ).thenAnswer((_) async => testDashboardData);
          when(
            () => mockRepository.getTransactionsWithFilter(
              month: any(named: 'month'),
              year: any(named: 'year'),
              type: any(named: 'type'),
            ),
          ).thenAnswer((_) async => []);
          return DashboardBloc(repository: mockRepository);
        },
        act: (bloc) => bloc.add(DashboardLoadRequested()),
        expect: () => [isA<DashboardLoading>(), isA<DashboardLoaded>()],
        verify: (_) {
          verify(() => mockRepository.getDashboardData()).called(1);
        },
      );

      blocTest<DashboardBloc, DashboardState>(
        'emits [DashboardLoading, DashboardError] when load fails',
        build: () {
          when(
            () => mockRepository.getDashboardData(),
          ).thenThrow(Exception('Network error'));
          return DashboardBloc(repository: mockRepository);
        },
        act: (bloc) => bloc.add(DashboardLoadRequested()),
        expect: () => [
          isA<DashboardLoading>(),
          isA<DashboardError>().having(
            (e) => e.message,
            'message',
            contains('Network error'),
          ),
        ],
      );

      blocTest<DashboardBloc, DashboardState>(
        'fetches category stats along with dashboard data',
        build: () {
          when(
            () => mockRepository.getDashboardData(),
          ).thenAnswer((_) async => testDashboardData);
          when(
            () => mockRepository.getTransactionsWithFilter(
              month: any(named: 'month'),
              year: any(named: 'year'),
              type: 'expense',
            ),
          ).thenAnswer(
            (_) async => [
              {'category': 'Ăn uống', 'amount': 500000},
              {'category': 'Di chuyển', 'amount': 200000},
            ],
          );
          when(
            () => mockRepository.getTransactionsWithFilter(
              month: any(named: 'month'),
              year: any(named: 'year'),
              type: 'income',
            ),
          ).thenAnswer(
            (_) async => [
              {'category': 'Lương', 'amount': 10000000},
            ],
          );
          return DashboardBloc(repository: mockRepository);
        },
        act: (bloc) => bloc.add(DashboardLoadRequested()),
        expect: () => [
          isA<DashboardLoading>(),
          isA<DashboardLoaded>().having(
            (s) => s.categoryStats,
            'categoryStats',
            isNotEmpty,
          ),
        ],
      );
    });

    group('DashboardRefreshRequested', () {
      blocTest<DashboardBloc, DashboardState>(
        'emits [DashboardLoaded] on refresh without loading state',
        build: () {
          when(
            () => mockRepository.getDashboardData(),
          ).thenAnswer((_) async => testDashboardData);
          when(
            () => mockRepository.getTransactionsWithFilter(
              month: any(named: 'month'),
              year: any(named: 'year'),
              type: any(named: 'type'),
            ),
          ).thenAnswer((_) async => []);
          return DashboardBloc(repository: mockRepository);
        },
        act: (bloc) => bloc.add(DashboardRefreshRequested()),
        expect: () => [isA<DashboardLoaded>()],
      );

      blocTest<DashboardBloc, DashboardState>(
        'emits [DashboardError] when refresh fails',
        build: () {
          when(
            () => mockRepository.getDashboardData(),
          ).thenThrow(Exception('Refresh failed'));
          return DashboardBloc(repository: mockRepository);
        },
        act: (bloc) => bloc.add(DashboardRefreshRequested()),
        expect: () => [
          isA<DashboardError>().having(
            (e) => e.message,
            'message',
            contains('Refresh failed'),
          ),
        ],
      );
    });

    group('DashboardReset', () {
      blocTest<DashboardBloc, DashboardState>(
        'emits [DashboardInitial] on reset',
        build: () => DashboardBloc(repository: mockRepository),
        seed: () => DashboardLoaded(
          testDashboardData,
          categoryStats: {'Ăn uống': 100000},
          incomeStats: {'Lương': 5000000},
        ),
        act: (bloc) => bloc.add(DashboardReset()),
        expect: () => [isA<DashboardInitial>()],
      );
    });

    group('_fetchMonthlyStats', () {
      blocTest<DashboardBloc, DashboardState>(
        'aggregates amounts by category correctly',
        build: () {
          when(
            () => mockRepository.getDashboardData(),
          ).thenAnswer((_) async => testDashboardData);
          when(
            () => mockRepository.getTransactionsWithFilter(
              month: any(named: 'month'),
              year: any(named: 'year'),
              type: 'expense',
            ),
          ).thenAnswer(
            (_) async => [
              {'category': 'Ăn uống', 'amount': 100000},
              {'category': 'Ăn uống', 'amount': 200000},
              {'category': 'Di chuyển', 'amount': 50000},
            ],
          );
          when(
            () => mockRepository.getTransactionsWithFilter(
              month: any(named: 'month'),
              year: any(named: 'year'),
              type: 'income',
            ),
          ).thenAnswer((_) async => []);
          return DashboardBloc(repository: mockRepository);
        },
        act: (bloc) => bloc.add(DashboardLoadRequested()),
        expect: () => [
          isA<DashboardLoading>(),
          isA<DashboardLoaded>().having(
            (s) => s.categoryStats['Ăn uống'],
            'Ăn uống total',
            300000, // 100000 + 200000
          ),
        ],
      );

      blocTest<DashboardBloc, DashboardState>(
        'handles amount as String',
        build: () {
          when(
            () => mockRepository.getDashboardData(),
          ).thenAnswer((_) async => testDashboardData);
          when(
            () => mockRepository.getTransactionsWithFilter(
              month: any(named: 'month'),
              year: any(named: 'year'),
              type: any(named: 'type'),
            ),
          ).thenAnswer(
            (_) async => [
              {'category': 'Test', 'amount': '500000'},
            ],
          );
          return DashboardBloc(repository: mockRepository);
        },
        act: (bloc) => bloc.add(DashboardLoadRequested()),
        expect: () => [
          isA<DashboardLoading>(),
          isA<DashboardLoaded>().having(
            (s) => s.categoryStats['Test'],
            'Test amount from string',
            500000.0,
          ),
        ],
      );
    });
  });
}
