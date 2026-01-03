import 'package:equatable/equatable.dart';
import '../../models/budget.dart';

abstract class BudgetState extends Equatable {
  const BudgetState();

  @override
  List<Object> get props => [];
}

class BudgetInitial extends BudgetState {}

class BudgetLoading extends BudgetState {}

class BudgetLoaded extends BudgetState {
  final List<Budget> budgets;
  final int month;
  final int year;

  const BudgetLoaded({
    required this.budgets,
    required this.month,
    required this.year,
  });

  @override
  List<Object> get props => [budgets, month, year];
}

class BudgetError extends BudgetState {
  final String message;

  const BudgetError(this.message);

  @override
  List<Object> get props => [message];
}

class BudgetOperationSuccess extends BudgetState {
  final String message;

  const BudgetOperationSuccess(this.message);

  @override
  List<Object> get props => [message];
}
