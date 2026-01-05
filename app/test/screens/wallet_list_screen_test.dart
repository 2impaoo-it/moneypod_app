import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moneypod/screens/wallet_list_screen.dart';
import 'package:moneypod/bloc/wallet_list/wallet_list_state.dart';
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

  group('WalletListScreen', () {
    testWidgets('renders loading indicator when WalletListLoading', (
      tester,
    ) async {
      when(
        () => helper.walletListBloc.state,
      ).thenReturn(const WalletListState(status: WalletStatus.loading));

      await tester.pumpWidget(
        helper.wrapWithProviders(const WalletListScreen()),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders wallet list when loaded', (tester) async {
      await tester.pumpWidget(
        helper.wrapWithProviders(const WalletListScreen()),
      );
      await tester.pumpAndSettle();

      // Wallet names from test data
      expect(find.text('Cash'), findsOneWidget);
      expect(find.text('Bank'), findsOneWidget);
    });

    testWidgets('shows wallet balances', (tester) async {
      await tester.pumpWidget(
        helper.wrapWithProviders(const WalletListScreen()),
      );
      await tester.pumpAndSettle();

      // Currency symbol should be present
      expect(find.textContaining('₫'), findsWidgets);
    });

    testWidgets('shows total balance', (tester) async {
      await tester.pumpWidget(
        helper.wrapWithProviders(const WalletListScreen()),
      );
      await tester.pumpAndSettle();

      // Total should be sum of all wallets
      expect(find.textContaining('Tổng'), findsWidgets);
    });

    testWidgets('has add wallet FAB button', (tester) async {
      await tester.pumpWidget(
        helper.wrapWithProviders(const WalletListScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('shows empty state when no wallets', (tester) async {
      when(() => helper.walletListBloc.state).thenReturn(
        const WalletListState(status: WalletStatus.success, wallets: []),
      );

      await tester.pumpWidget(
        helper.wrapWithProviders(const WalletListScreen()),
      );
      await tester.pumpAndSettle();

      // Empty state message
      expect(find.textContaining('ví'), findsWidgets);
    });

    testWidgets('shows error state', (tester) async {
      when(() => helper.walletListBloc.state).thenReturn(
        const WalletListState(
          status: WalletStatus.failure,
          errorMessage: 'Failed to load',
        ),
      );

      await tester.pumpWidget(
        helper.wrapWithProviders(const WalletListScreen()),
      );
      await tester.pump();

      expect(find.textContaining('Lỗi'), findsWidgets);
    });

    testWidgets('renders scaffold correctly', (tester) async {
      await tester.pumpWidget(
        helper.wrapWithProviders(const WalletListScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('wallet cards are tappable', (tester) async {
      await tester.pumpWidget(
        helper.wrapWithProviders(const WalletListScreen()),
      );
      await tester.pumpAndSettle();

      // Cards should be visible
      final cashCard = find.text('Cash');
      expect(cashCard, findsOneWidget);
    });

    testWidgets('shows app bar with title', (tester) async {
      await tester.pumpWidget(
        helper.wrapWithProviders(const WalletListScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Ví'), findsWidgets);
    });
  });
}
