import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moneypod/bloc/transaction/transaction_bloc.dart';
import 'package:moneypod/bloc/transaction/transaction_event.dart';
import 'package:moneypod/bloc/transaction/transaction_state.dart';
import 'package:moneypod/models/transaction.dart';
import '../mocks/repositories.dart';

void main() {
  late MockTransactionRepository mockRepository;
  late TransactionBloc bloc;

  setUp(() {
    mockRepository = MockTransactionRepository();
    bloc = TransactionBloc(repository: mockRepository);
  });

  tearDown(() {
    bloc.close();
  });

  final testTransactions = [
    Transaction(
      id: '1',
      title: 'Test Tx',
      category: 'Food',
      amount: 100,
      date: DateTime.now(),
      isExpense: true,
    ),
  ];

  final newTransaction = Transaction(
    id: 'new',
    title: 'New Tx',
    category: 'Income',
    amount: 500,
    date: DateTime.now(),
    isExpense: false,
    walletId: 'wallet1',
  );

  group('TransactionBloc', () {
    test('initial state is TransactionInitial', () {
      expect(bloc.state, equals(TransactionInitial()));
    });

    blocTest<TransactionBloc, TransactionState>(
      'emits [TransactionLoading, TransactionLoaded] when TransactionLoadRequested succeeds',
      build: () {
        when(
          () =>
              mockRepository.getTransactions(walletId: any(named: 'walletId')),
        ).thenAnswer((_) async => testTransactions);
        return bloc;
      },
      act: (bloc) => bloc.add(const TransactionLoadRequested()),
      expect: () => [TransactionLoading(), TransactionLoaded(testTransactions)],
      verify: (_) {
        verify(() => mockRepository.getTransactions()).called(1);
      },
    );

    blocTest<TransactionBloc, TransactionState>(
      'emits [TransactionLoading, TransactionError] when TransactionLoadRequested fails',
      build: () {
        when(
          () =>
              mockRepository.getTransactions(walletId: any(named: 'walletId')),
        ).thenThrow(Exception('Failed to load'));
        return bloc;
      },
      act: (bloc) => bloc.add(const TransactionLoadRequested()),
      expect: () => [
        TransactionLoading(),
        const TransactionError('Exception: Failed to load'),
      ],
    );

    blocTest<TransactionBloc, TransactionState>(
      'emits [TransactionLoading, TransactionLoaded, TransactionOperationSuccess] when TransactionAddRequested succeeds',
      build: () {
        // Mock create
        when(
          () => mockRepository.createTransaction(
            walletId: any(named: 'walletId'),
            amount: any(named: 'amount'),
            category: any(named: 'category'),
            type: any(named: 'type'),
            note: any(named: 'note'),
          ),
        ).thenAnswer((_) async {});

        // Mock reload
        when(
          () => mockRepository.getTransactions(),
        ).thenAnswer((_) async => testTransactions);
        return bloc;
      },
      act: (bloc) => bloc.add(TransactionAddRequested(newTransaction)),
      expect: () => [
        TransactionLoading(),
        TransactionLoaded(testTransactions),
        const TransactionOperationSuccess('Đã thêm giao dịch'),
      ],
      verify: (_) {
        verify(
          () => mockRepository.createTransaction(
            walletId: newTransaction.walletId!,
            amount: newTransaction.amount,
            category: newTransaction.category,
            type: 'income',
            note: newTransaction.title,
          ),
        ).called(1);
        verify(() => mockRepository.getTransactions()).called(1);
      },
    );

    blocTest<TransactionBloc, TransactionState>(
      'emits [TransactionLoading, TransactionError] when TransactionAddRequested fails',
      build: () {
        when(
          () => mockRepository.createTransaction(
            walletId: any(named: 'walletId'),
            amount: any(named: 'amount'),
            category: any(named: 'category'),
            type: any(named: 'type'),
            note: any(named: 'note'),
          ),
        ).thenThrow(Exception('Network error'));
        return bloc;
      },
      act: (bloc) => bloc.add(TransactionAddRequested(newTransaction)),
      expect: () => [
        TransactionLoading(),
        const TransactionError('Network error'),
      ],
    );

    blocTest<TransactionBloc, TransactionState>(
      'emits [TransactionLoading, TransactionLoaded, TransactionOperationSuccess] when TransactionDeleteRequested succeeds',
      build: () {
        when(
          () => mockRepository.deleteTransaction(any()),
        ).thenAnswer((_) async {});
        when(
          () => mockRepository.getTransactions(),
        ).thenAnswer((_) async => testTransactions);
        return bloc;
      },
      act: (bloc) => bloc.add(const TransactionDeleteRequested('1')),
      expect: () => [
        TransactionLoading(),
        TransactionLoaded(testTransactions),
        const TransactionOperationSuccess('Đã xóa giao dịch'),
      ],
      verify: (_) {
        verify(() => mockRepository.deleteTransaction('1')).called(1);
        verify(() => mockRepository.getTransactions()).called(1);
      },
    );
  });
}
