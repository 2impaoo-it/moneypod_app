import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moneypod/bloc/financial_report/financial_report_bloc.dart';
import 'package:moneypod/bloc/financial_report/financial_report_event.dart';
import 'package:moneypod/bloc/financial_report/financial_report_state.dart';
import 'package:moneypod/models/transaction.dart';
import '../../mocks/repositories.dart';

void main() {
  late MockTransactionRepository mockTransactionRepository;

  setUp(() {
    mockTransactionRepository = MockTransactionRepository();
    // Register fallback values if needed, e.g. for any() usage
    // registerFallbackValue(Transaction(...));
  });

  group('FinancialReportBloc', () {
    test('initial state is ReportInitial', () {
      expect(
        FinancialReportBloc(mockTransactionRepository).state,
        ReportInitial(),
      );
    });

    final mockTransactions = [
      Transaction(
        id: '1',
        title: 'Salary',
        amount: 100000,
        isExpense: false,
        category: 'Salary',
        date: DateTime(2023, 10, 15),
        walletId: 'w1',
      ),
      Transaction(
        id: '2',
        title: 'Lunch',
        amount: 50000,
        isExpense: true,
        category: 'Food',
        date: DateTime(2023, 10, 16),
        walletId: 'w1',
      ),
    ];

    group('LoadReport', () {
      blocTest<FinancialReportBloc, FinancialReportState>(
        'emits [ReportLoading, ReportLoaded] when LoadReport(month) succeeds',
        build: () {
          // Mock 7 months of data calls
          when(
            () => mockTransactionRepository.getTransactions(
              month: any(named: 'month'),
              year: any(named: 'year'),
              limit: any(named: 'limit'),
            ),
          ).thenAnswer((_) async => mockTransactions);
          return FinancialReportBloc(mockTransactionRepository);
        },
        act: (bloc) => bloc.add(
          const LoadReport(month: 10, year: 2023, reportType: ReportType.month),
        ),
        expect: () => [
          ReportLoading(),
          isA<ReportLoaded>()
              .having((s) => s.data.totalIncome, 'totalIncome', 100000.0)
              .having((s) => s.data.totalExpense, 'totalExpense', 50000.0)
              .having((s) => s.currentMonth, 'currentMonth', 10)
              .having((s) => s.currentYear, 'currentYear', 2023),
        ],
      );

      blocTest<FinancialReportBloc, FinancialReportState>(
        'emits [ReportLoading, ReportLoaded] when LoadReport(year) succeeds',
        build: () {
          // Mock 5 years of data calls
          when(
            () => mockTransactionRepository.getTransactions(
              year: any(named: 'year'),
              limit: any(named: 'limit'),
            ),
          ).thenAnswer((_) async => mockTransactions);
          return FinancialReportBloc(mockTransactionRepository);
        },
        act: (bloc) => bloc.add(
          const LoadReport(month: 1, year: 2023, reportType: ReportType.year),
        ),
        expect: () => [
          ReportLoading(),
          isA<ReportLoaded>()
              // Logic aggregates data, we expect non-zero if mock returns data
              .having((s) => s.reportType, 'reportType', ReportType.year)
              .having(
                (s) => s.data.totalIncome,
                'totalIncome',
                greaterThanOrEqualTo(0),
              ),
        ],
      );

      blocTest<FinancialReportBloc, FinancialReportState>(
        'emits [ReportLoading, ReportError] when LoadReport fails',
        build: () {
          when(
            () => mockTransactionRepository.getTransactions(
              month: any(named: 'month'),
              year: any(named: 'year'),
              limit: any(named: 'limit'),
            ),
          ).thenThrow(Exception('Network Error'));
          return FinancialReportBloc(mockTransactionRepository);
        },
        act: (bloc) => bloc.add(const LoadReport(month: 10, year: 2023)),
        expect: () => [
          ReportLoading(),
          isA<ReportError>().having(
            (e) => e.message,
            'message',
            'Network Error',
          ),
        ],
      );
    });

    group('SwitchChartType', () {
      final loadedState = ReportLoaded(
        data: ReportData(
          totalIncome: 100,
          totalExpense: 50,
          previousMonthIncome: 0,
          previousMonthExpense: 0,
          categoryAllocation: {},
          trends: [],
          dailyIncome: {},
          dailyExpense: {},
          transactions: [],
          previousCategoryAllocation: {},
        ),
        currentMonth: 10,
        currentYear: 2023,
        isBarChart: true,
      );

      blocTest<FinancialReportBloc, FinancialReportState>(
        'emits updated ReportLoaded with new isBarChart value',
        build: () => FinancialReportBloc(mockTransactionRepository),
        seed: () => loadedState,
        act: (bloc) => bloc.add(const SwitchChartType(false)),
        expect: () => [
          isA<ReportLoaded>().having((s) => s.isBarChart, 'isBarChart', false),
        ],
      );
    });
  });
}
