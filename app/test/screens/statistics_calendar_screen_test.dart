import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moneypod/screens/financial_report/statistics_calendar_screen.dart';
import 'package:moneypod/bloc/financial_report/financial_report_bloc.dart';
import 'package:moneypod/bloc/financial_report/financial_report_state.dart';

class MockFinancialReportBloc extends Mock implements FinancialReportBloc {
  final ReportLoaded _state;

  MockFinancialReportBloc()
    : _state = ReportLoaded(
        data: ReportData(
          totalIncome: 0,
          totalExpense: 0,
          previousMonthIncome: 0,
          previousMonthExpense: 0,
          categoryAllocation: const {},
          trends: const [],
          dailyIncome: const {},
          dailyExpense: const {},
          transactions: const [],
          previousCategoryAllocation: const {},
        ),
        currentMonth: DateTime.now().month,
        currentYear: DateTime.now().year,
      );

  @override
  Stream<FinancialReportState> get stream => Stream.value(_state);

  @override
  FinancialReportState get state => _state;
}

void main() {
  late MockFinancialReportBloc mockBloc;

  setUp(() {
    mockBloc = MockFinancialReportBloc();
  });

  Widget createTestWidget() {
    return MaterialApp(
      home: BlocProvider<FinancialReportBloc>.value(
        value: mockBloc,
        child: const StatisticsCalendarScreen(),
      ),
    );
  }

  group('StatisticsCalendarScreen', () {
    testWidgets('renders screen', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(StatisticsCalendarScreen), findsOneWidget);
    });

    testWidgets('shows calendar view options', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Should have week/month/year tabs
      expect(find.text('Tuần'), findsOneWidget);
      expect(find.text('Tháng'), findsOneWidget);
      expect(find.text('Năm'), findsOneWidget);
    });
  });

  group('CalendarTab enum', () {
    test('has three values', () {
      expect(CalendarTab.values.length, equals(3));
      expect(CalendarTab.values, contains(CalendarTab.week));
      expect(CalendarTab.values, contains(CalendarTab.month));
      expect(CalendarTab.values, contains(CalendarTab.year));
    });
  });
}
