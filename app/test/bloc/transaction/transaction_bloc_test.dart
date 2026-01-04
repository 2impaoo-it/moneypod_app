import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moneypod/bloc/transaction/transaction_bloc.dart';
import 'package:moneypod/bloc/transaction/transaction_event.dart';
import 'package:moneypod/bloc/transaction/transaction_state.dart';
import 'package:moneypod/models/transaction.dart';
import 'package:moneypod/repositories/transaction_repository.dart';

class MockTransactionRepository extends Mock implements TransactionRepository {}

void main() {
  late MockTransactionRepository mockRepository;

  setUp(() {
    mockRepository = MockTransactionRepository();
  });

  group('TransactionBloc Edge Cases', () {
    final transaction = Transaction(
      id: 't1',
      title: 'Food',
      category: 'Food',
      amount: 50.0,
      date: DateTime.now(),
      isExpense: true,
    );

    blocTest<TransactionBloc, TransactionState>(
      'emits [TransactionLoading, TransactionError] when loading fails',
      build: () {
        when(
          () =>
              mockRepository.getTransactions(walletId: any(named: 'walletId')),
        ).thenThrow(Exception('Failed to load'));
        return TransactionBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const TransactionLoadRequested()),
      expect: () => [
        TransactionLoading(),
        isA<TransactionError>().having(
          (e) => e.message,
          'message',
          contains('Failed to load'),
        ),
      ],
    );

    blocTest<TransactionBloc, TransactionState>(
      'emits [TransactionLoading, TransactionError] when add fails',
      build: () {
        when(
          () => mockRepository.createTransaction(
            walletId: any(named: 'walletId'),
            amount: any(named: 'amount'),
            category: any(named: 'category'),
            type: any(named: 'type'),
            note: any(named: 'note'),
          ),
        ).thenThrow(Exception('Failed to create'));
        return TransactionBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(TransactionAddRequested(transaction)),
      expect: () => [
        TransactionLoading(),
        isA<TransactionError>().having(
          (e) => e.message,
          'message',
          contains('Failed to create'),
        ),
      ],
    );

    blocTest<TransactionBloc, TransactionState>(
      'emits [TransactionLoading, TransactionError] when delete fails',
      build: () {
        when(
          () => mockRepository.deleteTransaction(any()),
        ).thenThrow(Exception('Failed to delete'));
        return TransactionBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const TransactionDeleteRequested('t1')),
      expect: () => [
        TransactionLoading(),
        isA<TransactionError>().having(
          (e) => e.message,
          'message',
          contains('Failed to delete'),
        ),
      ],
    );
  });
}
