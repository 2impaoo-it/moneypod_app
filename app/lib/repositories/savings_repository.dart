import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/savings_goal.dart';
import '../services/auth_service.dart';
import '../utils/dio_client.dart';
import '../config/app_config.dart';

/// Repository cho quản lý Savings Goals
class SavingsRepository {
  final AuthService _authService;
  late final Dio _dio;

  SavingsRepository({AuthService? authService, Dio? dio})
    : _authService = authService ?? AuthService() {
    _dio = dio ?? DioClient.getDio(null);
    if (dio == null) {
      _dio.options.baseUrl = AppConfig.baseUrl;
    }
  }

  /// Format DateTime cho server (RFC3339 với timezone)
  String _formatDateTimeForServer(DateTime dt) {
    // Tạo UTC DateTime để có timezone Z
    final utc = DateTime.utc(dt.year, dt.month, dt.day, 0, 0, 0);
    return utc.toIso8601String(); // Format: 2026-06-28T00:00:00.000Z
  }

  /// Lấy danh sách mục tiêu tiết kiệm
  Future<List<SavingsGoal>> getSavingsGoals() async {
    try {
      debugPrint('🔵 [SavingsRepo] Lấy danh sách mục tiêu tiết kiệm');

      final token = await _authService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Bạn cần đăng nhập để sử dụng tính năng này');
      }

      debugPrint('🌐 [SavingsRepo] Gửi GET đến: /savings');

      final response = await _dio.get(
        '/savings',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      debugPrint('📡 [SavingsRepo] Status Code: ${response.statusCode}');
      debugPrint('📦 [SavingsRepo] Response Body: ${response.data}');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];

        final goals = data.map((json) => SavingsGoal.fromJson(json)).toList();
        debugPrint('✅ [SavingsRepo] Lấy thành công ${goals.length} mục tiêu');
        return goals;
      } else {
        throw Exception(
          response.data['error'] ?? 'Không thể tải danh sách mục tiêu',
        );
      }
    } catch (e) {
      debugPrint('❌ [SavingsRepo] Lỗi: $e');
      rethrow;
    }
  }

  /// Tạo mục tiêu tiết kiệm mới
  ///
  /// Parameters:
  /// - [name]: Tên mục tiêu (bắt buộc)
  /// - [targetAmount]: Số tiền mục tiêu (bắt buộc)
  /// - [color]: Màu hiển thị (hex code, optional)
  /// - [icon]: Icon (optional)
  /// - [deadline]: Ngày deadline (optional)
  Future<void> createSavingsGoal({
    required String name,
    required double targetAmount,
    String? color,
    String? icon,
    DateTime? deadline,
  }) async {
    try {
      debugPrint('🔵 [SavingsRepo] Tạo mục tiêu: $name, target: $targetAmount');

      final token = await _authService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Bạn cần đăng nhập để sử dụng tính năng này');
      }

      final requestBody = {
        'name': name,
        'target_amount': targetAmount,
        if (color != null) 'color': color,
        if (icon != null) 'icon': icon,
        if (deadline != null) 'deadline': _formatDateTimeForServer(deadline),
      };
      debugPrint('📦 [SavingsRepo] Request body: $requestBody');

      final response = await _dio.post(
        '/savings',
        data: requestBody,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      debugPrint('📡 [SavingsRepo] Status: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        debugPrint('✅ [SavingsRepo] Tạo mục tiêu thành công');
      } else {
        throw Exception(response.data['error'] ?? 'Không thể tạo mục tiêu');
      }
    } catch (e) {
      debugPrint('❌ [SavingsRepo] Lỗi: $e');
      rethrow;
    }
  }

  /// Nạp tiền vào mục tiêu
  ///
  /// Parameters:
  /// - [goalId]: ID mục tiêu
  /// - [walletId]: ID ví lấy tiền
  /// - [amount]: Số tiền nạp
  /// - [note]: Ghi chú (optional)
  Future<Map<String, dynamic>> depositToGoal({
    required String goalId,
    required String walletId,
    required double amount,
    String? note,
  }) async {
    try {
      debugPrint(
        '🔵 [SavingsRepo] Nạp $amount vào goal $goalId từ wallet $walletId',
      );

      final token = await _authService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Bạn cần đăng nhập để sử dụng tính năng này');
      }

      final requestBody = {
        'wallet_id': walletId,
        'amount': amount,
        if (note != null) 'note': note,
      };

      final response = await _dio.post(
        '/savings/$goalId/deposit',
        data: requestBody,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      debugPrint('📡 [SavingsRepo] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint('✅ [SavingsRepo] Nạp tiền thành công');
        // Kiểm tra xem có hoàn thành mục tiêu không
        return {
          'success': true,
          'message': response.data['message'],
          'status': response.data['status'], // COMPLETED nếu đạt mục tiêu
        };
      } else {
        throw Exception(response.data['error'] ?? 'Không thể nạp tiền');
      }
    } catch (e) {
      debugPrint('❌ [SavingsRepo] Lỗi: $e');
      rethrow;
    }
  }

  /// Rút tiền từ mục tiêu về ví
  ///
  /// Parameters:
  /// - [goalId]: ID mục tiêu
  /// - [walletId]: ID ví nhận tiền
  /// - [amount]: Số tiền rút
  /// - [note]: Ghi chú (optional)
  Future<void> withdrawFromGoal({
    required String goalId,
    required String walletId,
    required double amount,
    String? note,
  }) async {
    try {
      debugPrint(
        '🔵 [SavingsRepo] Rút $amount từ goal $goalId về wallet $walletId',
      );

      final token = await _authService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Bạn cần đăng nhập để sử dụng tính năng này');
      }

      final requestBody = {
        'wallet_id': walletId,
        'amount': amount,
        if (note != null) 'note': note,
      };

      final response = await _dio.post(
        '/savings/$goalId/withdraw',
        data: requestBody,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      debugPrint('📡 [SavingsRepo] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint('✅ [SavingsRepo] Rút tiền thành công');
      } else {
        throw Exception(response.data['error'] ?? 'Không thể rút tiền');
      }
    } catch (e) {
      debugPrint('❌ [SavingsRepo] Lỗi: $e');
      rethrow;
    }
  }

  /// Cập nhật mục tiêu
  ///
  /// Parameters:
  /// - [goalId]: ID mục tiêu
  /// - Các trường cần cập nhật (optional)
  Future<void> updateSavingsGoal({
    required String goalId,
    String? name,
    String? color,
    String? icon,
    double? targetAmount,
    DateTime? deadline,
  }) async {
    try {
      debugPrint('🔵 [SavingsRepo] Cập nhật mục tiêu $goalId');

      final token = await _authService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Bạn cần đăng nhập để sử dụng tính năng này');
      }

      final requestBody = <String, dynamic>{};
      if (name != null) requestBody['name'] = name;
      if (color != null) requestBody['color'] = color;
      if (icon != null) requestBody['icon'] = icon;
      if (targetAmount != null) requestBody['target_amount'] = targetAmount;
      if (deadline != null) {
        requestBody['deadline'] = _formatDateTimeForServer(deadline);
      }

      final response = await _dio.put(
        '/savings/$goalId',
        data: requestBody,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      debugPrint('📡 [SavingsRepo] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint('✅ [SavingsRepo] Cập nhật mục tiêu thành công');
      } else {
        throw Exception(
          response.data['error'] ?? 'Không thể cập nhật mục tiêu',
        );
      }
    } catch (e) {
      debugPrint('❌ [SavingsRepo] Lỗi: $e');
      rethrow;
    }
  }

  /// Mark a savings goal as completed
  /// This is called when user withdraws all money from a 100% goal
  Future<void> markGoalCompleted(String goalId) async {
    try {
      debugPrint('🔵 [SavingsRepo] Đánh dấu hoàn thành mục tiêu $goalId');

      final token = await _authService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Bạn cần đăng nhập để sử dụng tính năng này');
      }

      final response = await _dio.put(
        '/savings/$goalId',
        data: {'status': 'COMPLETED'},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      debugPrint('📡 [SavingsRepo] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint('✅ [SavingsRepo] Đánh dấu hoàn thành thành công');
      } else {
        throw Exception(
          response.data['error'] ?? 'Không thể đánh dấu hoàn thành',
        );
      }
    } catch (e) {
      debugPrint('❌ [SavingsRepo] Lỗi: $e');
      rethrow;
    }
  }

  /// Xóa mục tiêu (phải rút hết tiền trước)
  Future<void> deleteSavingsGoal(String goalId) async {
    try {
      debugPrint('🔵 [SavingsRepo] Xóa mục tiêu $goalId');

      final token = await _authService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Bạn cần đăng nhập để sử dụng tính năng này');
      }

      final response = await _dio.delete(
        '/savings/$goalId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      debugPrint('📡 [SavingsRepo] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint('✅ [SavingsRepo] Xóa mục tiêu thành công');
      } else {
        throw Exception(response.data['error'] ?? 'Không thể xóa mục tiêu');
      }
    } catch (e) {
      debugPrint('❌ [SavingsRepo] Lỗi: $e');
      rethrow;
    }
  }

  /// Lấy lịch sử giao dịch của mục tiêu
  Future<List<SavingsTransaction>> getGoalTransactions(String goalId) async {
    try {
      debugPrint('🔵 [SavingsRepo] Lấy lịch sử giao dịch của goal $goalId');

      final token = await _authService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Bạn cần đăng nhập để sử dụng tính năng này');
      }

      final response = await _dio.get(
        '/savings/$goalId/transactions',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      debugPrint('📡 [SavingsRepo] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];

        final transactions = data
            .map((json) => SavingsTransaction.fromJson(json))
            .toList();
        debugPrint(
          '✅ [SavingsRepo] Lấy thành công ${transactions.length} giao dịch',
        );
        return transactions;
      } else {
        throw Exception(
          response.data['error'] ?? 'Không thể tải lịch sử giao dịch',
        );
      }
    } catch (e) {
      debugPrint('❌ [SavingsRepo] Lỗi: $e');
      rethrow;
    }
  }
}
