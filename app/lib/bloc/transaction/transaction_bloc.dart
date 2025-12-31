import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/transaction.dart';
import '../../repositories/transaction_repository.dart';
import 'transaction_event.dart';
import 'transaction_state.dart';

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final TransactionRepository _repository = TransactionRepository();

  TransactionBloc() : super(TransactionInitial()) {
    on<TransactionLoadRequested>(_onLoadRequested);
    on<TransactionAddRequested>(_onAddRequested);
    on<TransactionUpdateRequested>(_onUpdateRequested);
    on<TransactionDeleteRequested>(_onDeleteRequested);
  }

  Future<void> _onLoadRequested(
    TransactionLoadRequested event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());
    try {
      final transactions = await _repository.getTransactions(
        walletId: event.walletId,
      );
      emit(TransactionLoaded(transactions));
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  Future<void> _onAddRequested(
    TransactionAddRequested event,
    Emitter<TransactionState> emit,
  ) async {
    if (state is TransactionLoaded) {
      final current = (state as TransactionLoaded).transactions;
      final updated = List<Transaction>.from(current)..add(event.transaction);
      emit(TransactionOperationSuccess('Đã thêm giao dịch'));
      emit(TransactionLoaded(updated));
    }
  }

  Future<void> _onUpdateRequested(
    TransactionUpdateRequested event,
    Emitter<TransactionState> emit,
  ) async {
    if (state is TransactionLoaded) {
      final current = (state as TransactionLoaded).transactions;
      final index = current.indexWhere((t) => t.id == event.transaction.id);
      if (index != -1) {
        final updated = List<Transaction>.from(current);
        updated[index] = event.transaction;
        emit(TransactionOperationSuccess('Đã cập nhật giao dịch'));
        emit(TransactionLoaded(updated));
      } else {
        emit(const TransactionError('Không tìm thấy giao dịch'));
      }
    }
  }

  Future<void> _onDeleteRequested(
    TransactionDeleteRequested event,
    Emitter<TransactionState> emit,
  ) async {
    if (state is TransactionLoaded) {
      final current = (state as TransactionLoaded).transactions;
      final updated = List<Transaction>.from(current)
        ..removeWhere((t) => t.id == event.transactionId);
      emit(TransactionOperationSuccess('Đã xóa giao dịch'));
      emit(TransactionLoaded(updated));
    }
  }
}
