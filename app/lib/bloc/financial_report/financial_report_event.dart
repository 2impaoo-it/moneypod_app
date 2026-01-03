import 'package:equatable/equatable.dart';

abstract class FinancialReportEvent extends Equatable {
  const FinancialReportEvent();

  @override
  List<Object> get props => [];
}

enum ReportType { week, month, year }

class LoadReport extends FinancialReportEvent {
  final int month;
  final int year;
  final bool isRefresh;
  final ReportType reportType;

  const LoadReport({
    required this.month,
    required this.year,
    this.isRefresh = false,
    this.reportType = ReportType.month,
  });

  @override
  List<Object> get props => [month, year, isRefresh, reportType];
}

class SwitchChartType extends FinancialReportEvent {
  final bool isBarChart;

  const SwitchChartType(this.isBarChart);

  @override
  List<Object> get props => [isBarChart];
}
