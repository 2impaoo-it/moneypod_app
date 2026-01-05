import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneypod/models/transaction.dart';
import 'package:moneypod/widgets/transaction_item.dart';
import 'package:moneypod/theme/app_colors.dart';

void main() {
  group('TransactionItem', () {
    final expenseTransaction = Transaction(
      id: 't1',
      title: 'Lunch', // Note: Widget checks title
      amount: 50000,
      category: 'Ăn uống',
      date: DateTime(2023, 10, 27, 12, 30),
      isExpense: true,
      walletId: 'w1',
      walletName: 'Cash',
      userName: 'u1',
    );

    final incomeTransaction = Transaction(
      id: 't2',
      title: 'Salary',
      amount: 10000000,
      category: 'Lương',
      date: DateTime(2023, 10, 27, 9, 0),
      isExpense: false,
      walletId: 'w2',
      walletName: 'Bank',
      userName: 'u1',
    );

    testWidgets('renders expense transaction correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionItem(
              transaction: expenseTransaction,
              onTap: () {},
            ),
          ),
        ),
      );

      // Verify category
      expect(find.text('Ăn uống'), findsOneWidget);
      // Verify wallet name
      expect(find.text('Cash'), findsOneWidget);
      // Verify title
      expect(find.text('Lunch'), findsOneWidget);
      // Verify time
      expect(find.text('12:30'), findsOneWidget);
      // Verify amount (expense has -, red color)
      // Verify amount (expense has -, red color)
      final amountFinder = find.textContaining('50.000');
      expect(amountFinder, findsOneWidget);

      final textWidget = tester.widget<Text>(amountFinder);
      expect(textWidget.style?.color, AppColors.danger);
    });

    testWidgets('renders income transaction correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionItem(transaction: incomeTransaction, onTap: () {}),
          ),
        ),
      );

      // Verify category
      expect(find.text('Lương'), findsOneWidget);
      // Verify amount (income has +, green color)
      // Verify amount (income has +, green color)
      final amountFinder = find.textContaining('10.000.000');
      expect(amountFinder, findsOneWidget);

      final textWidget = tester.widget<Text>(amountFinder);
      expect(textWidget.style?.color, AppColors.success);
    });

    testWidgets('triggers onTap callback', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionItem(
              transaction: expenseTransaction,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TransactionItem));
      expect(tapped, isTrue);
    });
  });
}
