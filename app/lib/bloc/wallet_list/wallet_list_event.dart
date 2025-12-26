import 'package:equatable/equatable.dart';

/// Events cho WalletList
abstract class WalletListEvent extends Equatable {
  const WalletListEvent();

  @override
  List<Object?> get props => [];
}

/// Event: Load danh sách ví
class LoadWalletList extends WalletListEvent {
  const LoadWalletList();
}

/// Event: Refresh danh sách ví
class RefreshWalletList extends WalletListEvent {
  const RefreshWalletList();
}
