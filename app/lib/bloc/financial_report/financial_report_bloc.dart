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
        // --- YEAR REPORT: Aggregate by YEARS (not months) ---
        // Fetch transactions for the last 5 years
        final currentYear = event.year;
        final List<Future<List<Transaction>>> futures = [];

        for (int y = currentYear - 4; y <= currentYear; y++) {
          futures.add(_repository.getTransactions(year: y, limit: 2000));
        }

        final results = await Future.wait(futures);

        // Aggregate by year
        final List<MonthlyTrend> trends = [];
        List<Transaction> allTransactions = [];

        for (int i = 0; i < 5; i++) {
          final year = currentYear - 4 + i;
          final yearTxs = results[i];
          allTransactions.addAll(yearTxs);

          double inc = 0;
          double exp = 0;
          for (var t in yearTxs) {
            if (t.type == 'income') {
              inc += t.amount;
            } else {
              exp += t.amount;
            }
          }
          // Use month field to store year for display purposes
          trends.add(
            MonthlyTrend(month: year, year: year, income: inc, expense: exp),
          );
        }

        // Calculate totals for current year
        final currentYearTxs = results[4];
        double totalIncome = 0;
        double totalExpense = 0;
        final Map<String, double> allocation = {};

        for (var t in currentYearTxs) {
          if (t.type == 'income') {
            totalIncome += t.amount;
          } else {
            totalExpense += t.amount;
            allocation[t.category] = (allocation[t.category] ?? 0) + t.amount;
          }
        }

        // Previous year for comparison
        final prevYearTxs = results[3];
        double prevTotalIncome = 0;
        double prevTotalExpense = 0;
        final Map<String, double> prevAllocation = {};

        for (var t in prevYearTxs) {
          if (t.type == 'income') {
            prevTotalIncome += t.amount;
          } else {
            prevTotalExpense += t.amount;
            prevAllocation[t.category] =
                (prevAllocation[t.category] ?? 0) + t.amount;
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
              dailyIncome: {},
              dailyExpense: {},
              transactions: currentYearTxs,
              previousCategoryAllocation: prevAllocation,
            ),
            currentMonth: event.month,
            currentYear: event.year,
            reportType: ReportType.year,
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
          // Filter transactions by week number within the current month
          final firstDayOfMonth = DateTime(event.year, event.month, 1);
          final firstDayWeekday = firstDayOfMonth.weekday;

          // Calculate start and end day of the selected week
          int startDay = 1 + (event.week - 1) * 7 - (firstDayWeekday - 1);
          if (startDay < 1) {
            startDay = 1;
          }

          final lastDayOfMonth = DateTime(event.year, event.month + 1, 0).day;
          int endDay = startDay + 6;
          if (endDay > lastDayOfMonth) {
            endDay = lastDayOfMonth;
          }

          // Filter transactions within the selected week
          targetTransactions = currentTransactions.where((t) {
            return t.date.day >= startDay && t.date.day <= endDay;
          }).toList();

          // Previous week (last 7 days before this week or previous month)
          if (event.week == 1) {
            // Previous week is in the previous month
            targetPrevTransactions = prevTransactions.where((t) {
              // Last week of previous month
              final prevLastDay = DateTime(event.year, event.month, 0).day;
              return t.date.day > prevLastDay - 7;
            }).toList();
          } else {
            // Previous week is in the same month
            int prevStartDay = startDay - 7;
            if (prevStartDay < 1) {
              prevStartDay = 1;
            }
            int prevEndDay = startDay - 1;
            targetPrevTransactions = currentTransactions.where((t) {
              return t.date.day >= prevStartDay && t.date.day <= prevEndDay;
            }).toList();
          }
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
            reportType: event.reportType,
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
