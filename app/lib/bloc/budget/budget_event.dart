import 'package:equatable/equatable.dart';

abstract class BudgetEvent extends Equatable {
  const BudgetEvent();

  @override
  List<Object> get props => [];
}

class BudgetLoadRequested extends BudgetEvent {
  final int month;
  final int year;

  const BudgetLoadRequested({required this.month, required this.year});

  @override
  List<Object> get props => [month, year];
}

class BudgetCreateRequested extends BudgetEvent {
  final String category;
  final double amount;
  final int month;
  final int year;

  const BudgetCreateRequested({
    required this.category,
    required this.amount,
    required this.month,
    required this.year,
  });

  @override
  List<Object> get props => [category, amount, month, year];
}

class BudgetUpdateRequested extends BudgetEvent {
  final String id;
  final double? amount;
  final String? category;
  // To refresh list:
  final int month;
  final int year;

  const BudgetUpdateRequested({
    required this.id,
    this.amount,
    this.category,
    required this.month,
    required this.year,
  });

  @override
  List<Object> get props => [id, amount ?? '', category ?? '', month, year];
}

class BudgetDeleteRequested extends BudgetEvent {
  final String id;
  // To refresh list:
  final int month;
  final int year;

  const BudgetDeleteRequested({
    required this.id,
    required this.month,
    required this.year,
  });

  @override
  List<Object> get props => [id, month, year];
}
