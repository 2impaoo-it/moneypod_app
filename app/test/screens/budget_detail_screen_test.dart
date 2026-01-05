import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moneypod/screens/budget/budget_detail_screen.dart';
import 'package:moneypod/bloc/budget/budget_bloc.dart';
import 'package:moneypod/bloc/budget/budget_state.dart';
import 'package:moneypod/bloc/transaction/transaction_bloc.dart';
import 'package:moneypod/bloc/transaction/transaction_state.dart';
import 'package:moneypod/models/budget.dart';

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
  late Budget testBudget;

  setUp(() {
    mockBudgetBloc = MockBudgetBloc();
    mockTransactionBloc = MockTransactionBloc();
    testBudget = Budget(
      id: '1',
      category: 'Ăn uống',
      amount: 5000000,
      spent: 2000000,
      month: DateTime.now().month,
      year: DateTime.now().year,
    );
  });

  Widget createTestWidget() {
    return MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<BudgetBloc>.value(value: mockBudgetBloc),
          BlocProvider<TransactionBloc>.value(value: mockTransactionBloc),
        ],
        child: BudgetDetailScreen(budget: testBudget),
      ),
    );
  }

  group('BudgetDetailScreen', () {
    testWidgets('renders budget category', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('Ăn uống'), findsWidgets);
    });

    testWidgets('shows Ngân sách title in AppBar', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('Ngân sách'), findsOneWidget);
    });

    testWidgets('shows transaction detail section', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('Chi tiết giao dịch'), findsOneWidget);
    });

    testWidgets('shows days left text', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.textContaining('Còn'), findsWidgets);
    });

    testWidgets('has popup menu for edit/delete', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(PopupMenuButton<String>), findsOneWidget);
    });
  });

  group('HalfCirclePainter', () {
    test('shouldRepaint returns true', () {
      final painter = HalfCirclePainter(
        spent: 1000,
        total: 5000,
        color: Colors.green,
      );
      expect(painter.shouldRepaint(painter), isTrue);
    });
  });
}
