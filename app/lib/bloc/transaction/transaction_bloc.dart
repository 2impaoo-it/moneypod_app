import 'package:flutter_bloc/flutter_bloc.dart';
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

      // Debug log
      print('🔍 [TransactionBloc] Loaded ${transactions.length} transactions');
      if (transactions.isNotEmpty) {
        print('🔍 [TransactionBloc] First transaction:');
        print('   - User: ${transactions.first.userName}');
        print('   - Avatar: ${transactions.first.userAvatar}');
        print('   - Proof: ${transactions.first.proofImage}');
      }

      emit(TransactionLoaded(transactions));
    } catch (e) {
      print('❌ [TransactionBloc] Error: $e');
      emit(TransactionError(e.toString()));
    }
  }

  Future<void> _onAddRequested(
    TransactionAddRequested event,
    Emitter<TransactionState> emit,
  ) async {
    try {
      emit(TransactionLoading());

      // Gọi API để tạo transaction trên server
      await _repository.createTransaction(
        walletId: event.transaction.walletId ?? '',
        amount: event.transaction.amount,
        category: event.transaction.category,
        type: event.transaction.isExpense ? 'expense' : 'income',
        note: event.transaction.title,
      );

      // Reload danh sách từ server để đảm bảo đồng bộ
      final transactions = await _repository.getTransactions();
      emit(TransactionLoaded(transactions));
      emit(TransactionOperationSuccess('Đã thêm giao dịch'));
    } catch (e) {
      emit(TransactionError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onUpdateRequested(
    TransactionUpdateRequested event,
    Emitter<TransactionState> emit,
  ) async {
    try {
      emit(TransactionLoading());

      // Gọi API để update transaction trên server
      await _repository.updateTransaction(
        transactionId: event.transaction.id,
        amount: event.transaction.amount,
        category: event.transaction.category,
        type: event.transaction.isExpense ? 'expense' : 'income',
        note: event.transaction.title,
      );

      // Reload danh sách từ server
      final transactions = await _repository.getTransactions();
      emit(TransactionLoaded(transactions));
      emit(TransactionOperationSuccess('Đã cập nhật giao dịch'));
    } catch (e) {
      emit(TransactionError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onDeleteRequested(
    TransactionDeleteRequested event,
    Emitter<TransactionState> emit,
  ) async {
    try {
      emit(TransactionLoading());

      // Gọi API để xóa transaction trên server
      await _repository.deleteTransaction(event.transactionId);

      // Reload danh sách từ server
      final transactions = await _repository.getTransactions();
      emit(TransactionLoaded(transactions));
      emit(TransactionOperationSuccess('Đã xóa giao dịch'));
    } catch (e) {
      emit(TransactionError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
