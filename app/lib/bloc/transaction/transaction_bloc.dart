import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/transaction.dart';
import 'transaction_event.dart';
import 'transaction_state.dart';

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  TransactionBloc() : super(TransactionInitial()) {
    on<TransactionLoadRequested>(_onLoadRequested);
    on<TransactionAddRequested>(_onAddRequested);
    on<TransactionUpdateRequested>(_onUpdateRequested);
    on<TransactionDeleteRequested>(_onDeleteRequested);
  }

  // Mock data cho việc demo
  final List<Transaction> _transactions = [
    Transaction(
      id: '1',
      title: 'Cà phê Highland',
      category: 'Ăn uống',
      amount: 55000,
      date: DateTime.now(),
      isExpense: true,
      hashtag: '#caphe',
    ),
    Transaction(
      id: '2',
      title: 'Grab đi làm',
      category: 'Di chuyển',
      amount: 32000,
      date: DateTime.now(),
      isExpense: true,
      hashtag: '#xebus',
    ),
    Transaction(
      id: '3',
      title: 'Lương tháng 1',
      category: 'Lương',
      amount: 25000000,
      date: DateTime.now().subtract(const Duration(days: 1)),
      isExpense: false,
      hashtag: '#luong',
    ),
    Transaction(
      id: '4',
      title: 'Mua áo Uniqlo',
      category: 'Mua sắm',
      amount: 499000,
      date: DateTime.now().subtract(const Duration(days: 2)),
      isExpense: true,
    ),
    Transaction(
      id: '5',
      title: 'Netflix Premium',
      category: 'Giải trí',
      amount: 260000,
      date: DateTime.now().subtract(const Duration(days: 3)),
      isExpense: true,
    ),
  ];

  Future<void> _onLoadRequested(
    TransactionLoadRequested event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());

    // Giả lập API call
    await Future.delayed(const Duration(milliseconds: 500));

    // TODO: Thay thế bằng API call thực
    emit(TransactionLoaded(List.from(_transactions)));
  }

  Future<void> _onAddRequested(
    TransactionAddRequested event,
    Emitter<TransactionState> emit,
  ) async {
    if (state is TransactionLoaded) {
      // Thêm transaction mới
      _transactions.add(event.transaction);

      emit(TransactionOperationSuccess('Đã thêm giao dịch'));
      emit(TransactionLoaded(List.from(_transactions)));
    }
  }

  Future<void> _onUpdateRequested(
    TransactionUpdateRequested event,
    Emitter<TransactionState> emit,
  ) async {
    if (state is TransactionLoaded) {
      final index = _transactions.indexWhere(
        (t) => t.id == event.transaction.id,
      );
      if (index != -1) {
        _transactions[index] = event.transaction;
        emit(TransactionOperationSuccess('Đã cập nhật giao dịch'));
        emit(TransactionLoaded(List.from(_transactions)));
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
      _transactions.removeWhere((t) => t.id == event.transactionId);
      emit(TransactionOperationSuccess('Đã xóa giao dịch'));
      emit(TransactionLoaded(List.from(_transactions)));
    }
  }
}
