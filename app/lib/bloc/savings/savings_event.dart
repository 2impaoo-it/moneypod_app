import 'package:equatable/equatable.dart';
import '../../models/savings_goal.dart';

/// Savings Events
abstract class SavingsEvent extends Equatable {
  const SavingsEvent();

  @override
  List<Object?> get props => [];
}

/// Load danh sách mục tiêu
class LoadSavingsGoals extends SavingsEvent {}

/// Tạo mục tiêu mới
class CreateSavingsGoal extends SavingsEvent {
  final String name;
  final double targetAmount;
  final String? color;
  final String? icon;
  final DateTime? deadline;

  const CreateSavingsGoal({
    required this.name,
    required this.targetAmount,
    this.color,
    this.icon,
    this.deadline,
  });

  @override
  List<Object?> get props => [name, targetAmount, color, icon, deadline];
}

/// Nạp tiền vào mục tiêu
class DepositToGoal extends SavingsEvent {
  final String goalId;
  final String walletId;
  final double amount;

  const DepositToGoal({
    required this.goalId,
    required this.walletId,
    required this.amount,
  });

  @override
  List<Object> get props => [goalId, walletId, amount];
}

/// Rút tiền từ mục tiêu
class WithdrawFromGoal extends SavingsEvent {
  final String goalId;
  final String walletId;
  final double amount;

  const WithdrawFromGoal({
    required this.goalId,
    required this.walletId,
    required this.amount,
  });

  @override
  List<Object> get props => [goalId, walletId, amount];
}

/// Cập nhật mục tiêu
class UpdateSavingsGoal extends SavingsEvent {
  final String goalId;
  final String? name;
  final String? color;
  final String? icon;
  final double? targetAmount;
  final DateTime? deadline;

  const UpdateSavingsGoal({
    required this.goalId,
    this.name,
    this.color,
    this.icon,
    this.targetAmount,
    this.deadline,
  });

  @override
  List<Object?> get props => [goalId, name, color, icon, targetAmount, deadline];
}

/// Xóa mục tiêu
class DeleteSavingsGoal extends SavingsEvent {
  final String goalId;

  const DeleteSavingsGoal(this.goalId);

  @override
  List<Object> get props => [goalId];
}

/// Load lịch sử giao dịch
class LoadGoalTransactions extends SavingsEvent {
  final String goalId;

  const LoadGoalTransactions(this.goalId);

  @override
  List<Object> get props => [goalId];
}
