import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneypod/widgets/transaction_item.dart';
import 'package:moneypod/models/transaction.dart';

void main() {
  final testTransaction = Transaction(
    id: '1',
    title: 'Cafe',
    category: 'Ăn uống',
    amount: 50000,
    date: DateTime(2023, 10, 27, 9, 30),
    isExpense: true,
    hashtag: '#coffee',
    walletName: 'Ví tiền mặt',
  );

  Widget createWidgetUnderTest({VoidCallback? onTap}) {
    return MaterialApp(
      home: Scaffold(
        body: TransactionItem(
          transaction: testTransaction,
          onTap: onTap ?? () {},
        ),
      ),
    );
  }

  group('TransactionItem', () {
    testWidgets('renders transaction details correctly', (tester) async {
      tester.view.physicalSize = const Size(2000, 3000);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Cafe'), findsOneWidget);
      expect(find.text('Ăn uống'), findsOneWidget);
      expect(find.text('#coffee'), findsOneWidget);
      expect(find.text('Ví tiền mặt'), findsOneWidget);
      // Amount format is dynamic, check partial match
      expect(find.textContaining('50.000'), findsOneWidget);
      expect(find.textContaining('09:30'), findsOneWidget);
    });

    testWidgets('triggers onTap callback when tapped', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        createWidgetUnderTest(onTap: () => tapped = true),
      );

      await tester.tap(find.byType(TransactionItem));
      expect(tapped, isTrue);
    });
  });
}
