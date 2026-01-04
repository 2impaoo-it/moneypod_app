import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moneypod/screens/transactions_screen.dart';
import 'package:moneypod/bloc/transaction/transaction_bloc.dart';
import 'package:moneypod/bloc/transaction/transaction_event.dart';
import 'package:moneypod/bloc/transaction/transaction_state.dart';
import 'package:moneypod/models/transaction.dart';
import 'package:moneypod/widgets/transaction_item.dart';

// Mocks
class MockTransactionBloc extends Mock implements TransactionBloc {
  @override
  Stream<TransactionState> get stream => const Stream<TransactionState>.empty();
}

// Fakes
class FakeTransactionEvent extends Fake implements TransactionEvent {}

class FakeTransactionState extends Fake implements TransactionState {}

void main() {
  late MockTransactionBloc mockTransactionBloc;

  setUpAll(() {
    registerFallbackValue(FakeTransactionEvent());
    registerFallbackValue(FakeTransactionState());
    registerFallbackValue(TransactionLoadRequested());
  });

  setUp(() {
    mockTransactionBloc = MockTransactionBloc();
    when(() => mockTransactionBloc.state).thenReturn(TransactionInitial());
    when(() => mockTransactionBloc.add(any())).thenReturn(null);
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: BlocProvider<TransactionBloc>.value(
        value: mockTransactionBloc,
        child: const TransactionsScreen(),
      ),
    );
  }

  final mockTransactions = [
    Transaction(
      id: 't1',
      amount: 50000,
      isExpense: true,
      category: 'Ăn uống',
      date: DateTime.now(),
      title: 'Phở',
      walletId: 'w1',
    ),
    Transaction(
      id: 't2',
      amount: 1000000, // 1 triệu
      isExpense: false,
      category: 'Lương',
      date: DateTime.now().subtract(const Duration(days: 1)),
      title: 'Thưởng',
      walletId: 'w1',
    ),
  ];

  testWidgets('renders header and filter chips', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    expect(find.text('Giao dịch'), findsOneWidget);
    expect(find.text('Tất cả'), findsOneWidget);
    expect(find.text('Ăn uống'), findsOneWidget); // Filter chip
  });

  testWidgets('shows loading indicator when TransactionLoading', (
    tester,
  ) async {
    when(() => mockTransactionBloc.state).thenReturn(TransactionLoading());

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows list of transactions when TransactionLoaded', (
    tester,
  ) async {
    // Set size to avoid overflow (same as dashboard)
    tester.view.physicalSize = const Size(2000, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);

    when(
      () => mockTransactionBloc.state,
    ).thenReturn(TransactionLoaded(mockTransactions));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.byType(TransactionItem), findsNWidgets(2));

    // Check Status via Icons (more robust than text in some envs)
    // 'Ăn uống' maps to LucideIcons.utensils
    expect(find.byIcon(LucideIcons.utensils), findsOneWidget);
    // 'Lương' maps to LucideIcons.wallet
    expect(find.byIcon(LucideIcons.wallet), findsOneWidget);

    // Check amounts (partial match for formatting)
    // 50000 -> 50.000
    expect(find.textContaining('50.000'), findsOneWidget);
    // 1000000 -> 1.000.000
    expect(find.textContaining('1.000.000'), findsOneWidget);

    // Check date headers (logic in screen groups by date)
    // "Hôm nay" should be visible
    expect(find.text('Hôm nay'), findsOneWidget);
    // "Hôm qua" should be visible
    expect(find.text('Hôm qua'), findsOneWidget);
  });

  testWidgets('shows empty message when no transactions', (tester) async {
    when(
      () => mockTransactionBloc.state,
    ).thenReturn(const TransactionLoaded([]));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Không có giao dịch.'), findsOneWidget);
  });

  testWidgets('triggers load event on init', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    verify(
      () => mockTransactionBloc.add(any(that: isA<TransactionLoadRequested>())),
    ).called(1);
  });

  testWidgets('triggers load event when filter changed', (tester) async {
    when(
      () => mockTransactionBloc.state,
    ).thenReturn(const TransactionLoaded([]));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    // Scroll filter list if needed (it is in SingleChildScrollView)
    // Tap on "Ăn uống"
    await tester.tap(find.text('Ăn uống'));
    await tester.pump();

    // Should call add event again (init 1 + tap 1 = 2)
    verify(
      () => mockTransactionBloc.add(any(that: isA<TransactionLoadRequested>())),
    ).called(2);
  });
}
