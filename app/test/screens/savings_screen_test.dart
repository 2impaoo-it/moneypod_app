import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moneypod/screens/savings_screen.dart';
import 'package:moneypod/bloc/savings/savings_state.dart';
import '../mocks/test_helper.dart';

void main() {
  late TestHelper helper;

  setUpAll(() {
    TestHelper.registerFallbacks();
  });

  setUp(() {
    helper = TestHelper();
    helper.setUp();
  });

  group('SavingsScreen', () {
    testWidgets('renders loading indicator when SavingsLoading', (
      tester,
    ) async {
      when(() => helper.savingsBloc.state).thenReturn(SavingsLoading());

      await tester.pumpWidget(helper.wrapWithProviders(const SavingsScreen()));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders savings goals when loaded', (tester) async {
      await tester.pumpWidget(helper.wrapWithProviders(const SavingsScreen()));
      await tester.pumpAndSettle();

      // Savings goal name from test data
      expect(find.text('Vacation'), findsOneWidget);
    });

    testWidgets('shows progress indicator for goals', (tester) async {
      await tester.pumpWidget(helper.wrapWithProviders(const SavingsScreen()));
      await tester.pumpAndSettle();

      // Progress bar should exist
      expect(find.byType(LinearProgressIndicator), findsWidgets);
    });

    testWidgets('shows target and current amounts', (tester) async {
      await tester.pumpWidget(helper.wrapWithProviders(const SavingsScreen()));
      await tester.pumpAndSettle();

      // Currency symbol
      expect(find.textContaining('₫'), findsWidgets);
    });

    testWidgets('shows empty state when no savings goals', (tester) async {
      when(() => helper.savingsBloc.state).thenReturn(SavingsLoaded([]));

      await tester.pumpWidget(helper.wrapWithProviders(const SavingsScreen()));
      await tester.pumpAndSettle();

      // Empty state message
      expect(find.textContaining('mục tiêu'), findsWidgets);
    });

    testWidgets('has add goal FAB button', (tester) async {
      await tester.pumpWidget(helper.wrapWithProviders(const SavingsScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('shows error state', (tester) async {
      when(
        () => helper.savingsBloc.state,
      ).thenReturn(SavingsError('Failed to load'));

      await tester.pumpWidget(helper.wrapWithProviders(const SavingsScreen()));
      await tester.pump();

      expect(find.textContaining('Lỗi'), findsWidgets);
    });

    testWidgets('goal completion status is shown', (tester) async {
      await tester.pumpWidget(helper.wrapWithProviders(const SavingsScreen()));
      await tester.pumpAndSettle();

      // Status text or percentage
      expect(find.textContaining('%'), findsWidgets);
    });

    testWidgets('renders scaffold correctly', (tester) async {
      await tester.pumpWidget(helper.wrapWithProviders(const SavingsScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('shows app bar with title', (tester) async {
      await tester.pumpWidget(helper.wrapWithProviders(const SavingsScreen()));
      await tester.pumpAndSettle();

      expect(find.textContaining('Tiết kiệm'), findsWidgets);
    });
  });
}
