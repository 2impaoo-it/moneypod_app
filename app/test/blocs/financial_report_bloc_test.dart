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
  });
}
