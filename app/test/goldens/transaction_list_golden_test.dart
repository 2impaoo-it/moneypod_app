import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moneypod/bloc/transaction/transaction_bloc.dart';
import 'package:moneypod/bloc/transaction/transaction_state.dart';
import 'package:moneypod/bloc/settings/settings_cubit.dart'; // SettingsCubit
import 'package:moneypod/screens/transactions_screen.dart';
import 'package:moneypod/models/transaction.dart';

class MockTransactionBloc extends Mock implements TransactionBloc {}

class MockSettingsCubit extends Mock implements SettingsCubit {}

void main() {
  late MockTransactionBloc mockTransactionBloc;
  late MockSettingsCubit mockSettingsCubit;

  setUp(() {
    mockTransactionBloc = MockTransactionBloc();
    mockSettingsCubit = MockSettingsCubit();

    when(
      () => mockTransactionBloc.stream,
    ).thenAnswer((_) => Stream.value(TransactionInitial()));
    when(() => mockTransactionBloc.state).thenReturn(TransactionInitial());
    when(() => mockTransactionBloc.close()).thenAnswer((_) async {});

    // Fix: SettingsCubit might be needed if TransactionItem or Screen uses it
    when(
      () => mockSettingsCubit.stream,
    ).thenAnswer((_) => Stream.value(false)); // Light mode
    when(() => mockSettingsCubit.state).thenReturn(false);
  });

  testWidgets('TransactionsScreen list state golden test', (
    WidgetTester tester,
  ) async {
    final transactions = [
      Transaction(
        id: 't1',
        title: 'Lunch',
        amount: 50.0,
        category: 'Food',
        isExpense: true,
        date: DateTime(2023, 1, 1, 12, 0),
      ),
      Transaction(
        id: 't2',
        title: 'Salary',
        amount: 5000.0,
        category: 'Income',
        isExpense: false,
        date: DateTime(2023, 1, 1, 9, 0),
      ),
    ];

    when(
      () => mockTransactionBloc.state,
    ).thenReturn(TransactionLoaded(transactions));

    await tester.pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<TransactionBloc>.value(value: mockTransactionBloc),
            BlocProvider<SettingsCubit>.value(value: mockSettingsCubit),
          ],
          child: const TransactionsScreen(),
        ),
      ),
    );

    // Load fonts or wait
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(TransactionsScreen),
      matchesGoldenFile('goldens/transactions_screen_list.png'),
    );
  });
}
