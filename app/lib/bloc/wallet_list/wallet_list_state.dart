import 'package:equatable/equatable.dart';
import '../../models/wallet.dart';

enum WalletStatus { initial, loading, success, failure }

class WalletListState extends Equatable {
  final WalletStatus status;
  final List<Wallet> wallets;
  final String? errorMessage;

  const WalletListState({
    this.status = WalletStatus.initial,
    this.wallets = const [],
    this.errorMessage,
  });

  WalletListState copyWith({
    WalletStatus? status,
    List<Wallet>? wallets,
    String? errorMessage,
  }) {
    return WalletListState(
      status: status ?? this.status,
      wallets: wallets ?? this.wallets,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, wallets, errorMessage];
}
