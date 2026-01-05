import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moneypod/screens/budget/budget_list_screen.dart';
import 'package:moneypod/bloc/budget/budget_state.dart';
import '../mocks/test_helper.dart';

void main() {
  late TestHelper helper;

  setUpAll(() {
    TestHelper.registerFallbacks();
  });

  setUp(() {
    helper = TestHelper();
    helper.setUp();
  });

  group('BudgetListScreen', () {
    testWidgets('renders loading indicator when BudgetLoading', (tester) async {
      when(() => helper.budgetBloc.state).thenReturn(BudgetLoading());

      await tester.pumpWidget(
        helper.wrapWithProviders(const BudgetListScreen()),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders budget list when loaded', (tester) async {
      await tester.pumpWidget(
        helper.wrapWithProviders(const BudgetListScreen()),
      );
      await tester.pumpAndSettle();

      // Budget category from test data
      expect(find.text('Ăn uống'), findsOneWidget);
    });

    testWidgets('shows budget amounts', (tester) async {
      await tester.pumpWidget(
        helper.wrapWithProviders(const BudgetListScreen()),
      );
      await tester.pumpAndSettle();

      // Currency symbol should be present
      expect(find.textContaining('₫'), findsWidgets);
    });

    testWidgets('shows budget progress', (tester) async {
      await tester.pumpWidget(
        helper.wrapWithProviders(const BudgetListScreen()),
      );
      await tester.pumpAndSettle();

      // Progress indicator
      expect(find.byType(LinearProgressIndicator), findsWidgets);
    });

    testWidgets('has add budget FAB button', (tester) async {
      await tester.pumpWidget(
        helper.wrapWithProviders(const BudgetListScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('shows empty state when no budgets', (tester) async {
      when(
        () => helper.budgetBloc.state,
      ).thenReturn(BudgetLoaded(budgets: [], month: 1, year: 2026));

      await tester.pumpWidget(
        helper.wrapWithProviders(const BudgetListScreen()),
      );
      await tester.pumpAndSettle();

      // Empty state message
      expect(find.textContaining('ngân sách'), findsWidgets);
    });

    testWidgets('shows error state', (tester) async {
      when(
        () => helper.budgetBloc.state,
      ).thenReturn(BudgetError('Failed to load'));

      await tester.pumpWidget(
        helper.wrapWithProviders(const BudgetListScreen()),
      );
      await tester.pump();

      expect(find.textContaining('Lỗi'), findsWidgets);
    });

    testWidgets('shows spent vs total', (tester) async {
      await tester.pumpWidget(
        helper.wrapWithProviders(const BudgetListScreen()),
      );
      await tester.pumpAndSettle();

      // Should show spent amount (2,000,000 / 5,000,000)
      expect(find.textContaining('/'), findsWidgets);
    });

    testWidgets('month selector is present', (tester) async {
      await tester.pumpWidget(
        helper.wrapWithProviders(const BudgetListScreen()),
      );
      await tester.pumpAndSettle();

      // Month/year selector
      expect(find.textContaining('2026'), findsWidgets);
    });

    testWidgets('shows remaining budget', (tester) async {
      await tester.pumpWidget(
        helper.wrapWithProviders(const BudgetListScreen()),
      );
      await tester.pumpAndSettle();

      // Remaining amount
      expect(find.textContaining('còn lại'), findsWidgets);
    });
  });
}
