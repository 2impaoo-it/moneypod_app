import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/transaction_repository.dart';
import '../../models/transaction.dart';
import 'financial_report_event.dart';
import 'financial_report_state.dart';

class FinancialReportBloc
    extends Bloc<FinancialReportEvent, FinancialReportState> {
  final TransactionRepository _repository;

  FinancialReportBloc(this._repository) : super(ReportInitial()) {
    on<LoadReport>(_onLoadReport);
    on<SwitchChartType>(_onSwitchChartType);
  }

  Future<void> _onLoadReport(
    LoadReport event,
    Emitter<FinancialReportState> emit,
  ) async {
    try {
      emit(ReportLoading());

      if (event.reportType == ReportType.year) {
        // --- YEAR REPORT ---
        // Fetch all transactions for the year (limit 2000 to be safe)
        final transactions = await _repository.getTransactions(
          year: event.year,
          limit: 2000,
        );

        // Fetch previous year for comparison
        final prevTransactions = await _repository.getTransactions(
          year: event.year - 1,
          limit: 2000,
        );

        // Calculate Totals
        double totalIncome = 0;
        double totalExpense = 0;
        final Map<String, double> allocation = {};

        for (var t in transactions) {
          if (t.type == 'income') {
            totalIncome += t.amount;
          } else {
            totalExpense += t.amount;
            allocation[t.category] = (allocation[t.category] ?? 0) + t.amount;
          }
        }

        double prevTotalIncome = 0;
        double prevTotalExpense = 0;
        final Map<String, double> prevAllocation = {};

        for (var t in prevTransactions) {
          if (t.type == 'income') {
            prevTotalIncome += t.amount;
            prevAllocation[t.category] =
                (prevAllocation[t.category] ?? 0) + t.amount;
          } else {
            prevTotalExpense += t.amount;
            prevAllocation[t.category] =
                (prevAllocation[t.category] ?? 0) + t.amount;
          }
        }

        // Generate Trends (Jan-Dec)
        final List<MonthlyTrend> trends = [];
        for (int m = 1; m <= 12; m++) {
          double inc = 0;
          double exp = 0;
          // Filter from loaded transactions
          for (var t in transactions) {
            if (t.date.month == m) {
              if (t.type == 'income')
                inc += t.amount;
              else
                exp += t.amount;
            }
          }
          trends.add(
            MonthlyTrend(month: m, year: event.year, income: inc, expense: exp),
          );
        }

        emit(
          ReportLoaded(
            data: ReportData(
              totalIncome: totalIncome,
              totalExpense: totalExpense,
              previousMonthIncome: prevTotalIncome,
              previousMonthExpense: prevTotalExpense,
              categoryAllocation: allocation,
              trends: trends,
              dailyIncome: {}, // Not used/needed for year view chart
              dailyExpense: {},
              transactions: transactions,
              previousCategoryAllocation: prevAllocation,
            ),
            currentMonth: event.month,
            currentYear: event.year,
          ),
        );
      } else {
        // --- MONTH / WEEK REPORT (Existing Logic with Limit Update) ---
        // 1-6. Fetch data for the last 7 months (Current + 6 previous)
        final List<Future<List<Transaction>>> futures = [];
        for (int i = 0; i < 7; i++) {
          final date = DateTime(event.year, event.month - i);
          futures.add(
            _repository.getTransactions(
              month: date.month,
              year: date.year,
              limit: 1000,
            ),
          );
        }

        final results = await Future.wait(futures);

        final currentTransactions = results[0];
        final prevTransactions = results[1];

        // Calculate Trends for all 7 months
        final List<MonthlyTrend> trends = [];
        for (int i = 6; i >= 0; i--) {
          final date = DateTime(event.year, event.month - i);
          final txs = results[i];

          double inc = 0;
          double exp = 0;
          for (var t in txs) {
            if (t.type == 'income') {
              inc += t.amount;
            } else {
              exp += t.amount;
            }
          }

          trends.add(
            MonthlyTrend(
              month: date.month,
              year: date.year,
              income: inc,
              expense: exp,
            ),
          );
        }

        // Calculate Current Month Totals
        double totalIncome = 0;
        double totalExpense = 0;
        final Map<String, double> allocation = {};
        final Map<int, double> dailyIncome = {};
        final Map<int, double> dailyExpense = {};

        // Filter for Week View if needed (Optional: Logic can be refined to strict week)
        // For now, load Month data, and UI can filter daily keys.
        // BUT, TotalIncome/Expense should reflect the VIEW.

        List<Transaction> targetTransactions = currentTransactions;
        List<Transaction> targetPrevTransactions = prevTransactions;

        if (event.reportType == ReportType.week) {
          // Filter Current Month Txs to CURRENT WEEK (or selected week)
          // Assumption: We show "Week containing today" or first week?
          // Let's use "Week of the selectedDate" logic.
          // Determine start/end of week for DateTime(event.year, event.month, currentDay?)
          // Since we only have month/year, let's assume we want to show the week containing "Now" if within that month,
          // or the first week of that month?
          // Better: Use "Selected Date" from UI if passed? UI only passes month/year.
          // Let's rely on UI to filter `dailyIncome` if needed,
          // OR calculate Week totals here?

          // Simplification: For Week View, just calculate Totals for the WHOLE MONTH for now (as "Week" tab might just mean 'Show Daily Chart').
          // Screen "Theo tuần" usually shows specific week.
          // Let's keep Month Data but Screen will render Day Chart.
          // If we really want Week Totals, we need `day` in event.
        }

        for (var t in targetTransactions) {
          final day = t.date.day;
          if (t.type == 'income') {
            totalIncome += t.amount;
            dailyIncome[day] = (dailyIncome[day] ?? 0) + t.amount;
          } else {
            totalExpense += t.amount;
            dailyExpense[day] = (dailyExpense[day] ?? 0) + t.amount;
            final category = t.category;
            allocation[category] = (allocation[category] ?? 0) + t.amount;
          }
        }

        // Calculate Previous Month Totals
        double prevTotalIncome = 0;
        double prevTotalExpense = 0;
        final Map<String, double> prevAllocation = {};

        for (var t in targetPrevTransactions) {
          if (t.type == 'income') {
            prevTotalIncome += t.amount;
            final category = t.category;
            prevAllocation[category] =
                (prevAllocation[category] ?? 0) + t.amount;
          } else {
            prevTotalExpense += t.amount;
            final category = t.category;
            prevAllocation[category] =
                (prevAllocation[category] ?? 0) + t.amount;
          }
        }

        emit(
          ReportLoaded(
            data: ReportData(
              totalIncome: totalIncome,
              totalExpense: totalExpense,
              previousMonthIncome: prevTotalIncome,
              previousMonthExpense: prevTotalExpense,
              categoryAllocation: allocation,
              trends: trends,
              dailyIncome: dailyIncome,
              dailyExpense: dailyExpense,
              transactions: targetTransactions,
              previousCategoryAllocation: prevAllocation,
            ),
            currentMonth: event.month,
            currentYear: event.year,
          ),
        );
      }
    } catch (e) {
      emit(ReportError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  void _onSwitchChartType(
    SwitchChartType event,
    Emitter<FinancialReportState> emit,
  ) {
    if (state is ReportLoaded) {
      final currentState = state as ReportLoaded;
      emit(currentState.copyWith(isBarChart: event.isBarChart));
    }
  }
}
