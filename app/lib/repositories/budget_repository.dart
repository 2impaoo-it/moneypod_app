import 'package:dio/dio.dart';
import '../models/budget.dart';
import '../utils/dio_client.dart';
import '../services/auth_service.dart';
import '../config/app_config.dart';

class BudgetRepository {
  final AuthService _authService = AuthService();
  late final Dio _dio;

  BudgetRepository() {
    _dio = DioClient.getDio(null);
    _dio.options.baseUrl = AppConfig.baseUrl;
  }

  // Helper to get headers with token
  Future<Options> _getOptions() async {
    final token = await _authService.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Bạn cần đăng nhập để sử dụng tính năng này');
    }
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  // Get budgets for a specific month/year
  Future<List<Budget>> getBudgets(int month, int year) async {
    try {
      final options = await _getOptions();
      final response = await _dio.get(
        '/budgets',
        queryParameters: {'month': month, 'year': year},
        options: options,
      );

      final List<dynamic> data = response.data['data'];
      return data.map((json) => Budget.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load budgets: $e');
    }
  }

  // Create a new budget
  Future<Budget> createBudget({
    required String category,
    required double amount,
    required int month,
    required int year,
  }) async {
    try {
      final options = await _getOptions();
      final response = await _dio.post(
        '/budgets',
        data: {
          'category': category,
          'amount': amount,
          'month': month,
          'year': year,
        },
        options: options,
      );

      print('DEBUG: response.data type: ${response.data.runtimeType}');
      print('DEBUG: response.data: ${response.data}');

      return Budget.fromJson(response.data['data']);
    } catch (e) {
      print('DEBUG: Error in createBudget: $e');
      if (e is DioException && e.response?.data != null) {
        throw Exception(e.response?.data['error'] ?? 'Failed to create budget');
      }
      throw Exception('Failed to create budget: $e');
    }
  }

  // Update a budget
  Future<void> updateBudget({
    required String id,
    double? amount,
    String? category,
  }) async {
    try {
      final options = await _getOptions();
      await _dio.put(
        '/budgets/$id',
        data: {
          if (amount != null) 'amount': amount,
          if (category != null) 'category': category,
        },
        options: options,
      );
    } catch (e) {
      throw Exception('Failed to update budget: $e');
    }
  }

  // Delete a budget
  Future<void> deleteBudget(String id) async {
    try {
      final options = await _getOptions();
      await _dio.delete('/budgets/$id', options: options);
    } catch (e) {
      throw Exception('Failed to delete budget: $e');
    }
  }
}
