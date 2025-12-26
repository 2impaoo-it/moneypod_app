import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/wallet_repository.dart';
import 'wallet_list_event.dart';
import 'wallet_list_state.dart';

/// BLoC quản lý danh sách ví
class WalletListBloc extends Bloc<WalletListEvent, WalletListState> {
  final WalletRepository walletRepository;

  WalletListBloc({required this.walletRepository})
    : super(const WalletListLoading()) {
    on<LoadWalletList>(_onLoadWalletList);
    on<RefreshWalletList>(_onRefreshWalletList);
  }

  /// Xử lý event: Load danh sách ví
  Future<void> _onLoadWalletList(
    LoadWalletList event,
    Emitter<WalletListState> emit,
  ) async {
    try {
      emit(const WalletListLoading());

      final wallets = await walletRepository.getWallets();

      emit(WalletListLoaded(wallets: wallets));
    } catch (e) {
      emit(WalletListError(message: e.toString()));
    }
  }

  /// Xử lý event: Refresh danh sách ví
  Future<void> _onRefreshWalletList(
    RefreshWalletList event,
    Emitter<WalletListState> emit,
  ) async {
    try {
      // Không hiển thị loading khi refresh
      final wallets = await walletRepository.getWallets();

      emit(WalletListLoaded(wallets: wallets));
    } catch (e) {
      emit(WalletListError(message: e.toString()));
    }
  }
}
