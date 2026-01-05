import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moneypod/screens/budget/budget_amount_screen.dart';
import 'package:moneypod/bloc/budget/budget_bloc.dart';
import 'package:moneypod/bloc/budget/budget_state.dart';
import 'package:moneypod/bloc/transaction/transaction_bloc.dart';
import 'package:moneypod/bloc/transaction/transaction_state.dart';

class MockBudgetBloc extends Mock implements BudgetBloc {
  @override
  Stream<BudgetState> get stream => Stream.value(BudgetInitial());

  @override
  BudgetState get state => BudgetInitial();
}

class MockTransactionBloc extends Mock implements TransactionBloc {
  @override
  Stream<TransactionState> get stream =>
      Stream.value(const TransactionLoaded([]));

  @override
  TransactionState get state => const TransactionLoaded([]);
}

void main() {
  late MockBudgetBloc mockBudgetBloc;
  late MockTransactionBloc mockTransactionBloc;

  setUp(() {
    mockBudgetBloc = MockBudgetBloc();
    mockTransactionBloc = MockTransactionBloc();
  });

  Widget createTestWidget() {
    return MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<BudgetBloc>.value(value: mockBudgetBloc),
          BlocProvider<TransactionBloc>.value(value: mockTransactionBloc),
        ],
        child: const BudgetAmountScreen(categoryName: 'Ăn uống'),
      ),
    );
  }

  group('BudgetAmountScreen', () {
    testWidgets('renders with category name', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('Ăn uống'), findsOneWidget);
      expect(find.text('Tạo ngân sách'), findsOneWidget);
    });

    testWidgets('has amount input field', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('shows complete button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('Hoàn tất'), findsOneWidget);
    });

    testWidgets('shows spending statistics section', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('Xu hướng 6 tháng'), findsOneWidget);
    });
  });

  group('ThousandsFormatter', () {
    test('formats numbers with dots', () {
      final formatter = ThousandsFormatter();
      final result = formatter.formatEditUpdate(
        const TextEditingValue(text: ''),
        const TextEditingValue(text: '1000000'),
      );
      expect(result.text, '1.000.000');
    });

    test('returns empty for empty input', () {
      final formatter = ThousandsFormatter();
      final result = formatter.formatEditUpdate(
        const TextEditingValue(text: '123'),
        const TextEditingValue(text: ''),
      );
      expect(result.text, '');
    });
  });
}
