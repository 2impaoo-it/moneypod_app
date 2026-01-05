import 'package:equatable/equatable.dart';
import '../../models/transaction.dart';

// Transaction Events
abstract class TransactionEvent extends Equatable {
  const TransactionEvent();

  @override
  List<Object?> get props => [];
}

class TransactionLoadRequested extends TransactionEvent {
  final String? walletId;
  const TransactionLoadRequested({this.walletId});

  @override
  List<Object?> get props => [walletId];
}

class TransactionAddRequested extends TransactionEvent {
  final Transaction transaction;

  const TransactionAddRequested(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

class TransactionUpdateRequested extends TransactionEvent {
  final Transaction transaction;

  const TransactionUpdateRequested(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

class TransactionDeleteRequested extends TransactionEvent {
  final String transactionId;

  const TransactionDeleteRequested(this.transactionId);

  @override
  List<Object?> get props => [transactionId];
}
