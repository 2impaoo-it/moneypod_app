import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/budget_repository.dart';
import 'budget_event.dart';
import 'budget_state.dart';

class BudgetBloc extends Bloc<BudgetEvent, BudgetState> {
  final BudgetRepository _repository = BudgetRepository();

  BudgetBloc() : super(BudgetInitial()) {
    on<BudgetLoadRequested>(_onLoadRequested);
    on<BudgetCreateRequested>(_onCreateRequested);
    on<BudgetUpdateRequested>(_onUpdateRequested);
    on<BudgetDeleteRequested>(_onDeleteRequested);
  }

  Future<void> _onLoadRequested(
    BudgetLoadRequested event,
    Emitter<BudgetState> emit,
  ) async {
    emit(BudgetLoading());
    try {
      final budgets = await _repository.getBudgets(event.month, event.year);
      emit(
        BudgetLoaded(budgets: budgets, month: event.month, year: event.year),
      );
    } catch (e) {
      emit(BudgetError(e.toString()));
    }
  }

  Future<void> _onCreateRequested(
    BudgetCreateRequested event,
    Emitter<BudgetState> emit,
  ) async {
    try {
      emit(BudgetLoading());
      await _repository.createBudget(
        category: event.category,
        amount: event.amount,
        month: event.month,
        year: event.year,
      );

      // Reload list
      final budgets = await _repository.getBudgets(event.month, event.year);
      emit(
        BudgetLoaded(budgets: budgets, month: event.month, year: event.year),
      );
      emit(const BudgetOperationSuccess("Tạo ngân sách thành công!"));
      // Emit loaded again to show list
      emit(
        BudgetLoaded(budgets: budgets, month: event.month, year: event.year),
      );
    } catch (e) {
      emit(BudgetError(e.toString()));
      // Emit loaded state back if we have previous data?
      // Ideally we should reload or handle error better, but for now simple error state is fine.
      // Actually, after error, the UI might need to revert to Loaded.
      // Let's reload to be safe and restore state
      try {
        final budgets = await _repository.getBudgets(event.month, event.year);
        emit(
          BudgetLoaded(budgets: budgets, month: event.month, year: event.year),
        );
      } catch (_) {}
    }
  }

  Future<void> _onUpdateRequested(
    BudgetUpdateRequested event,
    Emitter<BudgetState> emit,
  ) async {
    try {
      emit(BudgetLoading());
      await _repository.updateBudget(
        id: event.id,
        amount: event.amount,
        category: event.category,
      );

      final budgets = await _repository.getBudgets(event.month, event.year);
      emit(
        BudgetLoaded(budgets: budgets, month: event.month, year: event.year),
      );
      emit(const BudgetOperationSuccess("Cập nhật ngân sách thành công!"));
      emit(
        BudgetLoaded(budgets: budgets, month: event.month, year: event.year),
      );
    } catch (e) {
      emit(BudgetError(e.toString()));
      try {
        final budgets = await _repository.getBudgets(event.month, event.year);
        emit(
          BudgetLoaded(budgets: budgets, month: event.month, year: event.year),
        );
      } catch (_) {}
    }
  }

  Future<void> _onDeleteRequested(
    BudgetDeleteRequested event,
    Emitter<BudgetState> emit,
  ) async {
    try {
      emit(BudgetLoading());
      await _repository.deleteBudget(event.id);

      final budgets = await _repository.getBudgets(event.month, event.year);
      emit(
        BudgetLoaded(budgets: budgets, month: event.month, year: event.year),
      );
      emit(const BudgetOperationSuccess("Xóa ngân sách thành công!"));
      emit(
        BudgetLoaded(budgets: budgets, month: event.month, year: event.year),
      );
    } catch (e) {
      emit(BudgetError(e.toString()));
      try {
        final budgets = await _repository.getBudgets(event.month, event.year);
        emit(
          BudgetLoaded(budgets: budgets, month: event.month, year: event.year),
        );
      } catch (_) {}
    }
  }
}
