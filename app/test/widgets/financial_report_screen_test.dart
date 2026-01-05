import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moneypod/screens/financial_report/financial_report_screen.dart';
import 'package:moneypod/bloc/financial_report/financial_report_bloc.dart';
import 'package:moneypod/bloc/financial_report/financial_report_event.dart';
import 'package:moneypod/bloc/financial_report/financial_report_state.dart';
import 'package:moneypod/models/transaction.dart';

// Mocks
class MockFinancialReportBloc extends Mock implements FinancialReportBloc {
  @override
  Stream<FinancialReportState> get stream =>
      const Stream<FinancialReportState>.empty();
}

// Fakes
class FakeFinancialReportEvent extends Fake implements FinancialReportEvent {}

class FakeFinancialReportState extends Fake implements FinancialReportState {}

void main() {
  late MockFinancialReportBloc mockBloc;

  setUpAll(() {
    registerFallbackValue(FakeFinancialReportEvent());
    registerFallbackValue(FakeFinancialReportState());
    registerFallbackValue(LoadReport(month: 1, year: 2024));
  });

  setUp(() {
    mockBloc = MockFinancialReportBloc();
    when(() => mockBloc.state).thenReturn(ReportInitial());
    when(() => mockBloc.add(any())).thenReturn(null);
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: BlocProvider<FinancialReportBloc>.value(
        value: mockBloc,
        child: const FinancialReportScreen(),
      ),
    );
  }

  // Mock Data
  final mockTransactions = [
    Transaction(
      id: 't1',
      amount: 5000000,
      isExpense: false, // Income
      category: 'Lương',
      date: DateTime.now(),
      title: 'Salary',
    ),
    Transaction(
      id: 't2',
      amount: 200000,
      isExpense: true, // Expense
      category: 'Ăn uống',
      date: DateTime.now(),
      title: 'Dinner',
    ),
  ];

  final mockMonthlyTrends = [
    MonthlyTrend(
      month: 1,
      year: 2024,
      income: 4000000,
      expense: 1500000,
    ), // Previous
    MonthlyTrend(
      month: 2,
      year: 2024,
      income: 5000000,
      expense: 2000000,
    ), // Current
  ];

  final mockReportData = ReportData(
    totalIncome: 5000000,
    totalExpense: 2000000,
    previousMonthIncome: 4000000,
    previousMonthExpense: 1500000,
    categoryAllocation: {'Ăn uống': 200000, 'Lương': 5000000},
    trends: mockMonthlyTrends,
    dailyIncome: {1: 5000000},
    dailyExpense: {1: 200000},
    transactions: mockTransactions,
    previousCategoryAllocation: {},
  );

  testWidgets('renders initial loading state', (tester) async {
    when(() => mockBloc.state).thenReturn(ReportLoading());
    await tester.pumpWidget(createWidgetUnderTest());
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('triggers LoadReport event when switching to Year tab', (
    tester,
  ) async {
    when(() => mockBloc.state).thenReturn(
      ReportLoaded(data: mockReportData, currentMonth: 2, currentYear: 2024),
    );

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Tap "Theo năm"
    await tester.tap(find.text('Theo năm'));
    await tester.pumpAndSettle();

    // Verify load event with ReportType.year
    verify(
      () => mockBloc.add(
        any(
          that: isA<LoadReport>().having(
            (e) => e.reportType,
            'reportType',
            ReportType.year,
          ),
        ),
      ),
    ).called(1);
  });

  testWidgets('updates displayed amount when switching sub-tabs', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(2000, 3000);
    addTearDown(tester.view.resetPhysicalSize);

    when(() => mockBloc.state).thenReturn(
      ReportLoaded(data: mockReportData, currentMonth: 2, currentYear: 2024),
    );

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Initially Difference: 3.000.000
    expect(find.textContaining('3.000.000'), findsOneWidget);

    // Switch to Income (Thu nhập) -> 5.000.000
    // Use specific finder to avoid conflict with Legend or Title (Title is "Tổng thu...")
    // Sub-tab is wrapped in GestureDetector
    final incomeTabFinder = find.descendant(
      of: find.byType(GestureDetector),
      matching: find.text('Thu nhập'),
    );
    await tester.tap(incomeTabFinder);
    await tester.pumpAndSettle();

    expect(find.textContaining('5.000.000'), findsWidgets);

    // Switch to Expense (Chi tiêu) -> 2.000.000
    final expenseTabFinder = find.descendant(
      of: find.byType(GestureDetector),
      matching: find.text('Chi tiêu'),
    );
    await tester.tap(expenseTabFinder);
    await tester.pumpAndSettle();

    expect(find.textContaining('2.000.000'), findsWidgets);
  });
}
