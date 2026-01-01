import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/wallet_repository.dart';
import 'wallet_list_event.dart';
import 'wallet_list_state.dart';

class WalletListBloc extends Bloc<WalletListEvent, WalletListState> {
  final WalletRepository walletRepository;

  WalletListBloc({required this.walletRepository})
    : super(const WalletListState()) {
    on<LoadWalletList>(_onLoadWalletList);
    on<RefreshWalletList>(_onRefreshWalletList);
    on<DeleteWalletRequested>(_onDeleteWallet);
    on<UpdateWalletRequested>(_onUpdateWallet);
  }

  Future<void> _onLoadWalletList(
    LoadWalletList event,
    Emitter<WalletListState> emit,
  ) async {
    emit(state.copyWith(status: WalletStatus.loading));
    try {
      final wallets = await walletRepository.getWallets();
      emit(state.copyWith(status: WalletStatus.success, wallets: wallets));
    } catch (e) {
      emit(
        state.copyWith(
          status: WalletStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onRefreshWalletList(
    RefreshWalletList event,
    Emitter<WalletListState> emit,
  ) async {
    // Keep current data, potentially show a different indicator if needed
    // For now we just reload and update
    try {
      final wallets = await walletRepository.getWallets();
      emit(state.copyWith(status: WalletStatus.success, wallets: wallets));
    } catch (e) {
      // On refresh error, we might want to keep the old data but show an error
      emit(
        state.copyWith(
          status: WalletStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onDeleteWallet(
    DeleteWalletRequested event,
    Emitter<WalletListState> emit,
  ) async {
    emit(state.copyWith(status: WalletStatus.loading));
    try {
      await walletRepository.deleteWallet(event.id);
      // Reload list after delete
      final wallets = await walletRepository.getWallets();
      emit(state.copyWith(status: WalletStatus.success, wallets: wallets));
    } catch (e) {
      emit(
        state.copyWith(
          status: WalletStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onUpdateWallet(
    UpdateWalletRequested event,
    Emitter<WalletListState> emit,
  ) async {
    emit(state.copyWith(status: WalletStatus.loading));
    try {
      await walletRepository.updateWallet(
        id: event.id,
        name: event.name,
        currency: event.currency,
      );
      // Reload list after update
      final wallets = await walletRepository.getWallets();
      emit(state.copyWith(status: WalletStatus.success, wallets: wallets));
    } catch (e) {
      emit(
        state.copyWith(
          status: WalletStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
