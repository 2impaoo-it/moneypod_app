import 'package:equatable/equatable.dart';
import '../../models/savings_goal.dart';

/// Savings States
abstract class SavingsState extends Equatable {
  const SavingsState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class SavingsInitial extends SavingsState {}

/// Loading state
class SavingsLoading extends SavingsState {}

/// Loaded state - Danh sách mục tiêu
class SavingsLoaded extends SavingsState {
  final List<SavingsGoal> goals;

  const SavingsLoaded(this.goals);

  @override
  List<Object> get props => [goals];
}

/// Success state - Hành động thành công (tạo, cập nhật, xóa)
class SavingsActionSuccess extends SavingsState {
  final String message;
  final List<SavingsGoal> goals;

  const SavingsActionSuccess({
    required this.message,
    required this.goals,
  });

  @override
  List<Object> get props => [message, goals];
}

/// Goal completed state - Đạt mục tiêu
class SavingsGoalCompleted extends SavingsState {
  final String message;
  final List<SavingsGoal> goals;

  const SavingsGoalCompleted({
    required this.message,
    required this.goals,
  });

  @override
  List<Object> get props => [message, goals];
}

/// Error state
class SavingsError extends SavingsState {
  final String message;

  const SavingsError(this.message);

  @override
  List<Object> get props => [message];
}

/// Transactions loaded state
class SavingsTransactionsLoaded extends SavingsState {
  final List<SavingsTransaction> transactions;

  const SavingsTransactionsLoaded(this.transactions);

  @override
  List<Object> get props => [transactions];
}
