import 'package:equatable/equatable.dart';
import '../../models/wallet.dart';

/// States cho WalletList
abstract class WalletListState extends Equatable {
  const WalletListState();

  @override
  List<Object?> get props => [];
}

/// State: Đang load
class WalletListLoading extends WalletListState {
  const WalletListLoading();
}

/// State: Load thành công
class WalletListLoaded extends WalletListState {
  final List<Wallet> wallets;

  const WalletListLoaded({required this.wallets});

  @override
  List<Object?> get props => [wallets];
}

/// State: Lỗi
class WalletListError extends WalletListState {
  final String message;

  const WalletListError({required this.message});

  @override
  List<Object?> get props => [message];
}
