import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/dashboard_repository.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardRepository _repository;

  DashboardBloc({DashboardRepository? repository})
    : _repository = repository ?? DashboardRepository(),
      super(DashboardInitial()) {
    on<DashboardLoadRequested>(_onLoadRequested);
    on<DashboardRefreshRequested>(_onRefreshRequested);
    on<DashboardReset>(_onReset);
  }

  void _onReset(DashboardReset event, Emitter<DashboardState> emit) {
    emit(DashboardInitial());
  }

  Future<void> _onLoadRequested(
    DashboardLoadRequested event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());
    try {
      final data = await _repository.getDashboardData();
      final stats = await _fetchMonthlyStats();
      emit(DashboardLoaded(data, categoryStats: stats));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }

  Future<void> _onRefreshRequested(
    DashboardRefreshRequested event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      final data = await _repository.getDashboardData();
      final stats = await _fetchMonthlyStats();
      emit(DashboardLoaded(data, categoryStats: stats));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }

  Future<Map<String, double>> _fetchMonthlyStats() async {
    try {
      final now = DateTime.now();
      final rawTransactions = await _repository.getTransactionsWithFilter(
        month: now.month,
        year: now.year,
        type: 'expense',
      );

      final Map<String, double> stats = {};
      for (var item in rawTransactions) {
        final category = item['category'] ?? 'Khác';
        double amount = 0.0;

        if (item['amount'] is num) {
          amount = (item['amount'] as num).toDouble();
        } else if (item['amount'] is String) {
          amount = double.tryParse(item['amount']) ?? 0.0;
        }

        // Use absolute value for stats (chart needs positive values)
        stats[category] = (stats[category] ?? 0) + amount.abs();
      }
      return stats;
    } catch (e) {
      print('Error calculating stats: $e');
      return {};
    }
  }
}
