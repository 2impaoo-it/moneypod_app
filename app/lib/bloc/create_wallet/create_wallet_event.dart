import 'package:equatable/equatable.dart';

/// Events cho việc tạo ví mới
abstract class CreateWalletEvent extends Equatable {
  const CreateWalletEvent();

  @override
  List<Object?> get props => [];
}

/// Event khi người dùng thay đổi tên ví
class WalletNameChanged extends CreateWalletEvent {
  final String name;

  const WalletNameChanged(this.name);

  @override
  List<Object?> get props => [name];
}

/// Event khi người dùng thay đổi số dư
class WalletBalanceChanged extends CreateWalletEvent {
  final double balance;

  const WalletBalanceChanged(this.balance);

  @override
  List<Object?> get props => [balance];
}

/// Event khi người dùng submit form tạo ví
class CreateWalletSubmitted extends CreateWalletEvent {
  const CreateWalletSubmitted();
}

/// Event để reset form về trạng thái ban đầu
class ResetCreateWallet extends CreateWalletEvent {
  const ResetCreateWallet();
}
