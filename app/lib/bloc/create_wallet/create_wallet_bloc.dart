import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/wallet_repository.dart';
import 'create_wallet_event.dart';
import 'create_wallet_state.dart';

/// BLoC xử lý logic tạo ví mới
class CreateWalletBloc extends Bloc<CreateWalletEvent, CreateWalletState> {
  final WalletRepository walletRepository;

  CreateWalletBloc({required this.walletRepository})
    : super(const CreateWalletState()) {
    // Xử lý khi người dùng nhập tên ví
    on<WalletNameChanged>(_onNameChanged);

    // Xử lý khi người dùng nhập số dư
    on<WalletBalanceChanged>(_onBalanceChanged);

    // Xử lý khi người dùng submit form
    on<CreateWalletSubmitted>(_onSubmitted);

    // Xử lý reset form
    on<ResetCreateWallet>(_onReset);
  }

  /// Handler cho event thay đổi tên ví
  void _onNameChanged(
    WalletNameChanged event,
    Emitter<CreateWalletState> emit,
  ) {
    emit(
      state.copyWith(
        name: event.name,
        status: CreateWalletStatus.initial,
        errorMessage: null,
      ),
    );
  }

  /// Handler cho event thay đổi số dư
  void _onBalanceChanged(
    WalletBalanceChanged event,
    Emitter<CreateWalletState> emit,
  ) {
    emit(
      state.copyWith(
        balance: event.balance,
        status: CreateWalletStatus.initial,
        errorMessage: null,
      ),
    );
  }

  /// Handler cho event submit form
  /// Chỉ gửi request lên server, để server xử lý validation
  Future<void> _onSubmitted(
    CreateWalletSubmitted event,
    Emitter<CreateWalletState> emit,
  ) async {
    // Emit trạng thái loading
    emit(state.copyWith(status: CreateWalletStatus.loading));

    try {
      // Gọi repository để tạo ví - server sẽ xử lý validation
      await walletRepository.createWallet(
        name: state.name.trim(),
        balance: state.balance,
      );

      // Thành công
      emit(state.copyWith(status: CreateWalletStatus.success));
    } catch (e) {
      // Thất bại - hiển thị lỗi từ server
      emit(
        state.copyWith(
          status: CreateWalletStatus.failure,
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  /// Handler cho event reset
  void _onReset(ResetCreateWallet event, Emitter<CreateWalletState> emit) {
    emit(const CreateWalletState());
  }
}
