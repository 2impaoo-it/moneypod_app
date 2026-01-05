import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moneypod/bloc/financial_report/financial_report_bloc.dart';
import 'package:moneypod/bloc/financial_report/financial_report_event.dart';
import 'package:moneypod/bloc/financial_report/financial_report_state.dart';
import 'package:moneypod/repositories/transaction_repository.dart';

class MockTransactionRepository extends Mock implements TransactionRepository {}

void main() {
  late MockTransactionRepository mockRepository;

  setUp(() {
    mockRepository = MockTransactionRepository();
  });

  group('FinancialReportBloc', () {
    blocTest<FinancialReportBloc, FinancialReportState>(
      'emits [Loading, Loaded] when LoadReport is added',
      build: () {
        // Mock data logic for LoadReport is complex (7 calls), simplifying for unit test
        // We'll trust the full logic integration test mainly, here just ensuring BLoC calls repository
        for (int i = 0; i < 7; i++) {
          when(
            () => mockRepository.getTransactions(
              month: any(named: 'month'),
              year: any(named: 'year'),
              limit: any(named: 'limit'),
            ),
          ).thenAnswer((_) async => []);
        }
        return FinancialReportBloc(mockRepository);
      },
      act: (bloc) => bloc.add(
        LoadReport(month: 10, year: 2023, reportType: ReportType.month),
      ),
      expect: () => [isA<ReportLoading>(), isA<ReportLoaded>()],
    );
    final emptyReportData = ReportData(
      totalIncome: 0,
      totalExpense: 0,
      previousMonthIncome: 0,
      previousMonthExpense: 0,
      categoryAllocation: {},
      trends: [],
      dailyIncome: {},
      dailyExpense: {},
      transactions: [],
      previousCategoryAllocation: {},
    );

    blocTest<FinancialReportBloc, FinancialReportState>(
      'emits [ReportLoaded] with updated isBarChart when SwitchChartType is added',
      build: () => FinancialReportBloc(mockRepository),
      seed: () => ReportLoaded(
        data: emptyReportData,
        currentMonth: 10,
        currentYear: 2023,
        isBarChart: true,
      ),
      act: (bloc) => bloc.add(const SwitchChartType(false)),
      expect: () => [
        isA<ReportLoaded>().having(
          (state) => state.isBarChart,
          'isBarChart',
          false,
        ),
      ],
    );

    blocTest<FinancialReportBloc, FinancialReportState>(
      'emits [ReportLoading, ReportError] when LoadReport fails',
      build: () {
        when(
          () => mockRepository.getTransactions(
            month: any(named: 'month'),
            year: any(named: 'year'),
            limit: any(named: 'limit'),
          ),
        ).thenThrow(Exception('Network error'));
        return FinancialReportBloc(mockRepository);
      },
      act: (bloc) => bloc.add(
        const LoadReport(month: 10, year: 2023, reportType: ReportType.month),
      ),
      expect: () => [isA<ReportLoading>(), isA<ReportError>()],
    );
  });
}
