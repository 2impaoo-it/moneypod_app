import 'package:equatable/equatable.dart';
import '../../models/transaction.dart';

class ReportData {
  final double totalIncome;
  final double totalExpense;
  final double previousMonthIncome;
  final double previousMonthExpense;
  final Map<String, double> categoryAllocation; // Use category name as key
  final List<MonthlyTrend> trends; // Current + previous months
  final Map<int, double> dailyIncome;
  final Map<int, double> dailyExpense;
  final List<Transaction> transactions;
  final Map<String, double> previousCategoryAllocation; // For trend analysis

  ReportData({
    required this.totalIncome,
    required this.totalExpense,
    required this.previousMonthIncome,
    required this.previousMonthExpense,
    required this.categoryAllocation,
    required this.trends,
    required this.dailyIncome,
    required this.dailyExpense,
    required this.transactions,
    required this.previousCategoryAllocation,
  });
}

class MonthlyTrend {
  final int month;
  final int year;
  final double income;
  final double expense;

  MonthlyTrend({
    required this.month,
    required this.year,
    required this.income,
    required this.expense,
  });
}

abstract class FinancialReportState extends Equatable {
  const FinancialReportState();

  @override
  List<Object> get props => [];
}

class ReportInitial extends FinancialReportState {}

class ReportLoading extends FinancialReportState {}

class ReportLoaded extends FinancialReportState {
  final ReportData data;
  final bool isBarChart; // View mode preference
  final int currentMonth;
  final int currentYear;

  const ReportLoaded({
    required this.data,
    required this.currentMonth,
    required this.currentYear,
    this.isBarChart = true,
  });

  ReportLoaded copyWith({
    ReportData? data,
    int? currentMonth,
    int? currentYear,
    bool? isBarChart,
  }) {
    return ReportLoaded(
      data: data ?? this.data,
      currentMonth: currentMonth ?? this.currentMonth,
      currentYear: currentYear ?? this.currentYear,
      isBarChart: isBarChart ?? this.isBarChart,
    );
  }

  @override
  List<Object> get props => [data, isBarChart, currentMonth, currentYear];
}

class ReportError extends FinancialReportState {
  final String message;

  const ReportError(this.message);

  @override
  List<Object> get props => [message];
}
