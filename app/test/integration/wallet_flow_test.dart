import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moneypod/bloc/settings/settings_cubit.dart';
import 'package:moneypod/bloc/wallet_list/wallet_list_bloc.dart';
import 'package:moneypod/bloc/wallet_list/wallet_list_event.dart';
import 'package:moneypod/bloc/wallet_list/wallet_list_state.dart';
import 'package:moneypod/models/wallet.dart';
import 'package:moneypod/screens/wallet_list_screen.dart';

class MockWalletListBloc extends MockBloc<WalletListEvent, WalletListState>
    implements WalletListBloc {}

class MockSettingsCubit extends MockCubit<bool> implements SettingsCubit {}

void main() {
  late MockWalletListBloc mockWalletListBloc;
  late MockSettingsCubit mockSettingsCubit;

  setUp(() {
    mockWalletListBloc = MockWalletListBloc();
    mockSettingsCubit = MockSettingsCubit();
    when(() => mockSettingsCubit.state).thenReturn(true);
  });

  Future<void> pumpWalletListScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<WalletListBloc>.value(value: mockWalletListBloc),
            BlocProvider<SettingsCubit>.value(value: mockSettingsCubit),
          ],
          child: const WalletListView(), // Use the now public view
        ),
      ),
    );
  }

  group('Wallet Flow Integration', () {
    testWidgets('Displays loading state', (tester) async {
      when(
        () => mockWalletListBloc.state,
      ).thenReturn(const WalletListState(status: WalletStatus.loading));

      await pumpWalletListScreen(tester);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Displays loaded wallets', (tester) async {
      final wallets = [
        Wallet(
          id: '1',
          userId: 'user1',
          name: 'Ví tiền mặt',
          balance: 500000,
          currency: 'VND',
          createdAt: DateTime.now(),
        ),
        Wallet(
          id: '2',
          userId: 'user1',
          name: 'Ví tiết kiệm',
          balance: 2000000,
          currency: 'VND',
          createdAt: DateTime.now(),
        ),
      ];

      when(() => mockWalletListBloc.state).thenReturn(
        WalletListState(status: WalletStatus.success, wallets: wallets),
      );

      await pumpWalletListScreen(tester);
      await tester.pumpAndSettle();

      expect(find.text('Ví tiền mặt'), findsOneWidget);
      expect(find.text('Ví tiết kiệm'), findsOneWidget);
      expect(find.textContaining('500.000'), findsOneWidget);
    });

    testWidgets('Empty state shows create prompt', (tester) async {
      when(() => mockWalletListBloc.state).thenReturn(
        const WalletListState(status: WalletStatus.success, wallets: []),
      );

      await pumpWalletListScreen(tester);
      await tester.pumpAndSettle();

      expect(find.text('Chưa có ví nào'), findsOneWidget);
    });
  });
}
