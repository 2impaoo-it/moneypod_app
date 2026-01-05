import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneypod/screens/financial_report/filter_transaction_dialog.dart';

void main() {
  group('FilterTransactionDialog', () {
    Widget createTestWidget() {
      return MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => const FilterTransactionDialog(),
                );
              },
              child: const Text('Open Filter'),
            ),
          ),
        ),
      );
    }

    testWidgets('opens as modal bottom sheet', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle();

      expect(find.byType(FilterTransactionDialog), findsOneWidget);
    });

    testWidgets('shows filter title', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle();

      expect(find.text('Bộ lọc'), findsOneWidget);
    });

    testWidgets('has apply and reset buttons', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle();

      expect(find.text('Áp dụng'), findsOneWidget);
      expect(find.text('Đặt lại'), findsOneWidget);
    });

    testWidgets('has tab options for income and expense', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle();

      expect(find.text('Chi tiêu'), findsWidgets);
      expect(find.text('Thu nhập'), findsWidgets);
    });
  });
}
