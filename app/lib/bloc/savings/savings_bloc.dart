import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/savings_repository.dart';
import 'savings_event.dart';
import 'savings_state.dart';

class SavingsBloc extends Bloc<SavingsEvent, SavingsState> {
  final SavingsRepository _repository;

  SavingsBloc(this._repository) : super(SavingsInitial()) {
    on<LoadSavingsGoals>(_onLoadSavingsGoals);
    on<CreateSavingsGoal>(_onCreateSavingsGoal);
    on<DepositToGoal>(_onDepositToGoal);
    on<WithdrawFromGoal>(_onWithdrawFromGoal);
    on<UpdateSavingsGoal>(_onUpdateSavingsGoal);
    on<DeleteSavingsGoal>(_onDeleteSavingsGoal);
    on<LoadGoalTransactions>(_onLoadGoalTransactions);
    on<ResetSavings>(_onResetSavings);
  }

  void _onResetSavings(ResetSavings event, Emitter<SavingsState> emit) {
    emit(SavingsInitial());
  }

  /// Load danh sách mục tiêu
  Future<void> _onLoadSavingsGoals(
    LoadSavingsGoals event,
    Emitter<SavingsState> emit,
  ) async {
    try {
      emit(SavingsLoading());
      final goals = await _repository.getSavingsGoals();
      emit(SavingsLoaded(goals));
    } catch (e) {
      emit(SavingsError(e.toString()));
    }
  }

  /// Tạo mục tiêu mới
  Future<void> _onCreateSavingsGoal(
    CreateSavingsGoal event,
    Emitter<SavingsState> emit,
  ) async {
    try {
      emit(SavingsLoading());
      await _repository.createSavingsGoal(
        name: event.name,
        targetAmount: event.targetAmount,
        color: event.color,
        icon: event.icon,
        deadline: event.deadline,
      );

      // Reload danh sách sau khi tạo
      final goals = await _repository.getSavingsGoals();
      emit(
        SavingsActionSuccess(message: 'Tạo mục tiêu thành công!', goals: goals),
      );
    } catch (e) {
      emit(SavingsError(e.toString()));
    }
  }

  /// Nạp tiền vào mục tiêu
  Future<void> _onDepositToGoal(
    DepositToGoal event,
    Emitter<SavingsState> emit,
  ) async {
    try {
      emit(SavingsLoading());
      final result = await _repository.depositToGoal(
        goalId: event.goalId,
        walletId: event.walletId,
        amount: event.amount,
        note: event.note,
      );

      // Reload danh sách sau khi nạp
      final goals = await _repository.getSavingsGoals();

      // Kiểm tra xem có hoàn thành mục tiêu không
      if (result['status'] == 'COMPLETED') {
        emit(
          SavingsGoalCompleted(
            message:
                result['message'] ??
                '🎉 Chúc mừng! Bạn đã hoàn thành mục tiêu!',
            goals: goals,
          ),
        );
      } else {
        emit(
          SavingsActionSuccess(message: 'Nạp tiền thành công!', goals: goals),
        );
      }
    } catch (e) {
      emit(SavingsError(e.toString()));
    }
  }

  /// Rút tiền từ mục tiêu
  Future<void> _onWithdrawFromGoal(
    WithdrawFromGoal event,
    Emitter<SavingsState> emit,
  ) async {
    try {
      emit(SavingsLoading());
      await _repository.withdrawFromGoal(
        goalId: event.goalId,
        walletId: event.walletId,
        amount: event.amount,
        note: event.note,
      );

      // Reload danh sách sau khi rút
      final goals = await _repository.getSavingsGoals();
      emit(SavingsActionSuccess(message: 'Rút tiền thành công!', goals: goals));
    } catch (e) {
      emit(SavingsError(e.toString()));
    }
  }

  /// Cập nhật mục tiêu
  Future<void> _onUpdateSavingsGoal(
    UpdateSavingsGoal event,
    Emitter<SavingsState> emit,
  ) async {
    try {
      emit(SavingsLoading());
      await _repository.updateSavingsGoal(
        goalId: event.goalId,
        name: event.name,
        color: event.color,
        icon: event.icon,
        targetAmount: event.targetAmount,
        deadline: event.deadline,
      );

      // Reload danh sách sau khi cập nhật
      final goals = await _repository.getSavingsGoals();
      emit(
        SavingsActionSuccess(
          message: 'Cập nhật mục tiêu thành công!',
          goals: goals,
        ),
      );
    } catch (e) {
      emit(SavingsError(e.toString()));
    }
  }

  /// Xóa mục tiêu
  Future<void> _onDeleteSavingsGoal(
    DeleteSavingsGoal event,
    Emitter<SavingsState> emit,
  ) async {
    try {
      emit(SavingsLoading());
      await _repository.deleteSavingsGoal(event.goalId);

      // Reload danh sách sau khi xóa
      // final goals = await _repository.getSavingsGoals(); // Không cần lấy lại danh sách vì sẽ pop
      emit(SavingsDeleteSuccess(message: 'Xóa mục tiêu thành công!'));
    } catch (e) {
      emit(SavingsError(e.toString()));
    }
  }

  /// Load lịch sử giao dịch
  Future<void> _onLoadGoalTransactions(
    LoadGoalTransactions event,
    Emitter<SavingsState> emit,
  ) async {
    try {
      emit(SavingsLoading());
      final transactions = await _repository.getGoalTransactions(event.goalId);
      emit(SavingsTransactionsLoaded(transactions));
    } catch (e) {
      emit(SavingsError(e.toString()));
    }
  }
}
