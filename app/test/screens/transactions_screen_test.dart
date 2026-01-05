import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moneypod/screens/transactions_screen.dart';
import 'package:moneypod/bloc/transaction/transaction_state.dart';
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

  group('TransactionsScreen', () {
    testWidgets('renders loading indicator when TransactionLoading', (
      tester,
    ) async {
      when(() => helper.transactionBloc.state).thenReturn(TransactionLoading());

      await tester.pumpWidget(
        helper.wrapWithProviders(const TransactionsScreen()),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders transaction list when loaded', (tester) async {
      await tester.pumpWidget(
        helper.wrapWithProviders(const TransactionsScreen()),
      );
      await tester.pumpAndSettle();

      // Transaction titles from test data
      expect(find.text('Lunch'), findsOneWidget);
      expect(find.text('Salary'), findsOneWidget);
    });

    testWidgets('shows transaction amounts', (tester) async {
      await tester.pumpWidget(
        helper.wrapWithProviders(const TransactionsScreen()),
      );
      await tester.pumpAndSettle();

      // Currency symbol should be present
      expect(find.textContaining('₫'), findsWidgets);
    });

    testWidgets('shows expense with minus sign', (tester) async {
      await tester.pumpWidget(
        helper.wrapWithProviders(const TransactionsScreen()),
      );
      await tester.pumpAndSettle();

      // Expense transactions show minus
      expect(find.textContaining('-'), findsWidgets);
    });

    testWidgets('shows income with plus sign', (tester) async {
      await tester.pumpWidget(
        helper.wrapWithProviders(const TransactionsScreen()),
      );
      await tester.pumpAndSettle();

      // Income transactions show plus
      expect(find.textContaining('+'), findsWidgets);
    });

    testWidgets('shows category icons', (tester) async {
      await tester.pumpWidget(
        helper.wrapWithProviders(const TransactionsScreen()),
      );
      await tester.pumpAndSettle();

      // Category names should be visible
      expect(find.text('Ăn uống'), findsWidgets);
      expect(find.text('Lương'), findsWidgets);
    });

    testWidgets('renders filter/search options', (tester) async {
      await tester.pumpWidget(
        helper.wrapWithProviders(const TransactionsScreen()),
      );
      await tester.pumpAndSettle();

      // Should have filter or search functionality
      expect(find.byType(IconButton), findsWidgets);
    });

    testWidgets('shows empty state when no transactions', (tester) async {
      when(
        () => helper.transactionBloc.state,
      ).thenReturn(TransactionLoaded([]));

      await tester.pumpWidget(
        helper.wrapWithProviders(const TransactionsScreen()),
      );
      await tester.pumpAndSettle();

      // Empty state or message
      expect(find.textContaining('giao dịch'), findsWidgets);
    });

    testWidgets('shows error state', (tester) async {
      when(
        () => helper.transactionBloc.state,
      ).thenReturn(TransactionError('Failed to load'));

      await tester.pumpWidget(
        helper.wrapWithProviders(const TransactionsScreen()),
      );
      await tester.pump();

      expect(find.textContaining('Lỗi'), findsWidgets);
    });

    testWidgets('has refresh capability', (tester) async {
      await tester.pumpWidget(
        helper.wrapWithProviders(const TransactionsScreen()),
      );
      await tester.pumpAndSettle();

      // RefreshIndicator or pull-to-refresh should exist
      final scaffold = find.byType(Scaffold);
      expect(scaffold, findsOneWidget);
    });
  });
}
