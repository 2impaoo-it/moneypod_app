import 'package:flutter_test/flutter_test.dart';
import 'package:moneypod/bloc/wallet_list/wallet_list_state.dart';

void main() {
  group('WalletListScreen', () {
    test('WalletListState with default values', () {
      const state = WalletListState();
      expect(state.status, equals(WalletStatus.initial));
      expect(state.wallets, isEmpty);
      expect(state.errorMessage, isNull);
    });

    test('WalletListState copyWith works', () {
      const state = WalletListState();
      final newState = state.copyWith(status: WalletStatus.loading);
      expect(newState.status, equals(WalletStatus.loading));
    });

    test('WalletStatus enum values', () {
      expect(WalletStatus.initial, isNotNull);
      expect(WalletStatus.loading, isNotNull);
      expect(WalletStatus.success, isNotNull);
      expect(WalletStatus.failure, isNotNull);
    });

    test('WalletListState props for Equatable', () {
      const state1 = WalletListState();
      const state2 = WalletListState();
      expect(state1.props, equals(state2.props));
    });
  });
}
