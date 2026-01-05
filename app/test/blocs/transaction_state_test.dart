import 'package:flutter_test/flutter_test.dart';
import 'package:moneypod/models/transaction.dart';
import 'package:moneypod/bloc/transaction/transaction_state.dart';

void main() {
  group('TransactionState', () {
    group('TransactionLoaded', () {
      final testTransactions = [
        Transaction(
          id: '1',
          title: 'Lương tháng 1',
          category: 'Lương',
          amount: 15000000,
          date: DateTime(2026, 1, 1),
          isExpense: false,
        ),
        Transaction(
          id: '2',
          title: 'Ăn sáng',
          category: 'Ăn uống',
          amount: 50000,
          date: DateTime(2026, 1, 2),
          isExpense: true,
        ),
        Transaction(
          id: '3',
          title: 'Tiền nhà',
          category: 'Hóa đơn',
          amount: 5000000,
          date: DateTime(2026, 1, 3),
          isExpense: true,
        ),
        Transaction(
          id: '4',
          title: 'Thưởng',
          category: 'Thưởng',
          amount: 3000000,
          date: DateTime(2026, 1, 4),
          isExpense: false,
        ),
      ];

      test('totalIncome calculates sum of income transactions', () {
        final state = TransactionLoaded(testTransactions);

        // Income: 15,000,000 + 3,000,000 = 18,000,000
        expect(state.totalIncome, 18000000);
      });

      test('totalExpense calculates sum of expense transactions', () {
        final state = TransactionLoaded(testTransactions);

        // Expense: 50,000 + 5,000,000 = 5,050,000
        expect(state.totalExpense, 5050000);
      });

      test('balance calculates income minus expense', () {
        final state = TransactionLoaded(testTransactions);

        // Balance: 18,000,000 - 5,050,000 = 12,950,000
        expect(state.balance, 12950000);
      });

      test('recentTransactions returns max 10 sorted by date desc', () {
        final state = TransactionLoaded(testTransactions);
        final recent = state.recentTransactions;

        expect(recent.length, 4);
        // Most recent first (Jan 4)
        expect(recent.first.id, '4');
        // Oldest last (Jan 1)
        expect(recent.last.id, '1');
      });

      test('recentTransactions returns only 10 when more exist', () {
        final manyTransactions = List.generate(
          15,
          (i) => Transaction(
            id: '$i',
            title: 'Transaction $i',
            category: 'Khác',
            amount: 1000,
            date: DateTime(2026, 1, i + 1),
            isExpense: true,
          ),
        );

        final state = TransactionLoaded(manyTransactions);

        expect(state.recentTransactions.length, 10);
      });

      test('totalIncome returns 0 when no income transactions', () {
        final expensesOnly = [
          Transaction(
            id: '1',
            title: 'Expense',
            category: 'Khác',
            amount: 1000,
            date: DateTime.now(),
            isExpense: true,
          ),
        ];

        final state = TransactionLoaded(expensesOnly);

        expect(state.totalIncome, 0);
      });

      test('totalExpense returns 0 when no expense transactions', () {
        final incomeOnly = [
          Transaction(
            id: '1',
            title: 'Income',
            category: 'Lương',
            amount: 10000000,
            date: DateTime.now(),
            isExpense: false,
          ),
        ];

        final state = TransactionLoaded(incomeOnly);

        expect(state.totalExpense, 0);
      });

      test('empty transactions list has zero totals', () {
        final state = TransactionLoaded([]);

        expect(state.totalIncome, 0);
        expect(state.totalExpense, 0);
        expect(state.balance, 0);
        expect(state.recentTransactions, isEmpty);
      });
    });

    group('Equatable', () {
      test('same transactions list produces equal states', () {
        final transactions = [
          Transaction(
            id: '1',
            title: 'Test',
            category: 'Khác',
            amount: 1000,
            date: DateTime(2026, 1, 1),
            isExpense: true,
          ),
        ];

        final state1 = TransactionLoaded(transactions);
        final state2 = TransactionLoaded(transactions);

        expect(state1, equals(state2));
      });

      test('different transactions produce different states', () {
        final tx1 = [
          Transaction(
            id: '1',
            title: 'Test',
            category: 'Khác',
            amount: 1000,
            date: DateTime(2026, 1, 1),
            isExpense: true,
          ),
        ];
        final tx2 = [
          Transaction(
            id: '2',
            title: 'Different',
            category: 'Khác',
            amount: 2000,
            date: DateTime(2026, 1, 1),
            isExpense: true,
          ),
        ];

        expect(TransactionLoaded(tx1), isNot(equals(TransactionLoaded(tx2))));
      });

      test('TransactionError states with same message are equal', () {
        const error1 = TransactionError('Network error');
        const error2 = TransactionError('Network error');

        expect(error1, equals(error2));
      });

      test('TransactionError states with different messages are not equal', () {
        const error1 = TransactionError('Error 1');
        const error2 = TransactionError('Error 2');

        expect(error1, isNot(equals(error2)));
      });

      test(
        'TransactionOperationSuccess states with same message are equal',
        () {
          const success1 = TransactionOperationSuccess('Done');
          const success2 = TransactionOperationSuccess('Done');

          expect(success1, equals(success2));
        },
      );
    });
  });
}
