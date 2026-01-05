import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moneypod/bloc/dashboard/dashboard_bloc.dart';
import 'package:moneypod/bloc/dashboard/dashboard_event.dart';
import 'package:moneypod/bloc/dashboard/dashboard_state.dart';
import 'package:moneypod/models/dashboard_data.dart';
import 'package:moneypod/models/user.dart';
import '../mocks/repositories.dart';

void main() {
  late MockDashboardRepository mockRepository;
  late DashboardBloc bloc;

  setUp(() {
    mockRepository = MockDashboardRepository();
    bloc = DashboardBloc(repository: mockRepository);
  });

  tearDown(() {
    bloc.close();
  });

  final testData = DashboardData(
    userInfo: User(email: 'test@example.com', fullName: 'Test Name'),
    totalBalance: 1000000.0,
    wallets: [],
    recentTransactions: [],
  );

  group('DashboardBloc', () {
    test('initial state is DashboardInitial', () {
      expect(bloc.state, isA<DashboardInitial>());
    });

    blocTest<DashboardBloc, DashboardState>(
      'emits [DashboardLoading, DashboardLoaded] when DashboardLoadRequested succeeds',
      build: () {
        when(
          () => mockRepository.getDashboardData(),
        ).thenAnswer((_) async => testData);
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
    );

    blocTest<DashboardBloc, DashboardState>(
      'emits [DashboardLoading, DashboardError] when DashboardLoadRequested fails',
      build: () {
        when(
          () => mockRepository.getDashboardData(),
        ).thenThrow(Exception('API Error'));
        return DashboardBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(DashboardLoadRequested()),
      expect: () => [isA<DashboardLoading>(), isA<DashboardError>()],
    );

    blocTest<DashboardBloc, DashboardState>(
      'emits DashboardLoaded with stats when data succeeds',
      build: () {
        when(
          () => mockRepository.getDashboardData(),
        ).thenAnswer((_) async => testData);
        when(
          () => mockRepository.getTransactionsWithFilter(
            month: any(named: 'month'),
            year: any(named: 'year'),
            type: 'expense',
          ),
        ).thenAnswer(
          (_) async => [
            {'category': 'Food', 'amount': 50000.0},
            {'category': 'Food', 'amount': 20000.0},
            {'category': 'Transport', 'amount': 30000.0},
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
        isA<DashboardLoaded>().having((s) => s.categoryStats, 'categoryStats', {
          'Food': 70000.0,
          'Transport': 30000.0,
        }),
      ],
    );
  });
}
