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

/// Event: Xóa ví
class DeleteWalletRequested extends WalletListEvent {
  final String id;
  const DeleteWalletRequested(this.id);

  @override
  List<Object?> get props => [id];
}

/// Event: Cập nhật ví
class UpdateWalletRequested extends WalletListEvent {
  final String id;
  final String name;
  final double balance;

  const UpdateWalletRequested({
    required this.id,
    required this.name,
    required this.balance,
  });

  @override
  List<Object?> get props => [id, name, balance];
}
