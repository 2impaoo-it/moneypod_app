import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moneypod/bloc/transaction/transaction_bloc.dart';
import 'package:moneypod/bloc/transaction/transaction_event.dart';
import 'package:moneypod/bloc/transaction/transaction_state.dart';
import 'package:moneypod/models/transaction.dart';
import 'package:moneypod/screens/transactions_screen.dart';

class MockTransactionBloc extends MockBloc<TransactionEvent, TransactionState>
    implements TransactionBloc {}

void main() {
  late MockTransactionBloc mockTransactionBloc;

  setUp(() {
    mockTransactionBloc = MockTransactionBloc();
  });

  Future<void> pumpTransactionsScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<TransactionBloc>.value(
          value: mockTransactionBloc,
          child: const TransactionsScreen(),
        ),
      ),
    );
  }

  group('Transaction Flow Integration', () {
    testWidgets('Displays loading indicator when state is TransactionLoading', (
      tester,
    ) async {
      when(() => mockTransactionBloc.state).thenReturn(TransactionLoading());

      await pumpTransactionsScreen(tester);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Displays transactions when state is TransactionLoaded', (
      tester,
    ) async {
      final transactions = [
        Transaction(
          id: '1',
          amount: 50000,
          category: 'Ăn uống',
          date: DateTime.now(),
          isExpense: true,
          title: 'Phở bò',
          walletId: 'wallet1',
        ),
        Transaction(
          id: '2',
          amount: 1000000,
          category: 'Lương',
          date: DateTime.now().subtract(const Duration(days: 1)),
          isExpense: false,
          title: 'Thưởng',
          walletId: 'wallet1',
        ),
      ];

      when(
        () => mockTransactionBloc.state,
      ).thenReturn(TransactionLoaded(transactions));

      await pumpTransactionsScreen(tester);
      await tester.pumpAndSettle();

      expect(find.text('Phở bò'), findsOneWidget);
      expect(find.text('Thưởng'), findsOneWidget);
      expect(find.text('Hôm nay'), findsOneWidget);
    });

    testWidgets('Filter transactions triggers reload', (tester) async {
      when(() => mockTransactionBloc.state).thenReturn(TransactionLoaded([]));

      await pumpTransactionsScreen(tester);
      await tester.pumpAndSettle();

      // Find "Ăn uống" filter chip
      await tester.tap(find.text('Ăn uống'));
      await tester.pump();

      verify(
        () =>
            mockTransactionBloc.add(any(that: isA<TransactionLoadRequested>())),
      ).called(greaterThan(0));
    });

    testWidgets('Tap transaction shows detail modal', (tester) async {
      final transactions = [
        Transaction(
          id: '1',
          amount: 50000,
          category: 'Ăn uống',
          date: DateTime.now(),
          isExpense: true,
          title: 'Phở bò',
          walletId: 'wallet1',
        ),
      ];

      when(
        () => mockTransactionBloc.state,
      ).thenReturn(TransactionLoaded(transactions));

      await pumpTransactionsScreen(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Phở bò'));
      await tester.pumpAndSettle();

      expect(
        find.text('Chi tiết giao dịch'),
        findsNothing,
      ); // Title absent in modal code
      expect(find.text('Loại giao dịch'), findsOneWidget); // Found in modal
      expect(find.text('Chi tiêu'), findsOneWidget);
    });
  });
}
