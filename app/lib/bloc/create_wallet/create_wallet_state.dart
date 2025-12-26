import 'package:equatable/equatable.dart';

/// Trạng thái của quá trình tạo ví
enum CreateWalletStatus {
  initial, // Trạng thái ban đầu
  loading, // Đang xử lý
  success, // Tạo thành công
  failure, // Tạo thất bại
}

/// State chứa thông tin form tạo ví
class CreateWalletState extends Equatable {
  final String name;
  final double balance;
  final CreateWalletStatus status;
  final String? errorMessage;

  const CreateWalletState({
    this.name = '',
    this.balance = 0.0,
    this.status = CreateWalletStatus.initial,
    this.errorMessage,
  });

  /// Copy state với các giá trị mới
  CreateWalletState copyWith({
    String? name,
    double? balance,
    CreateWalletStatus? status,
    String? errorMessage,
  }) {
    return CreateWalletState(
      name: name ?? this.name,
      balance: balance ?? this.balance,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Kiểm tra form có hợp lệ không
  bool get isFormValid {
    return name.trim().isNotEmpty && balance >= 0;
  }

  @override
  List<Object?> get props => [name, balance, status, errorMessage];
}
