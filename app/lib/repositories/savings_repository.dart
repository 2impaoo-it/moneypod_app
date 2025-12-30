import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/savings_goal.dart';
import '../services/auth_service.dart';

/// Repository cho quản lý Savings Goals
class SavingsRepository {
  final AuthService _authService = AuthService();

  // URL server backend
  static const String _baseUrl =
      'https://pseudoeconomical-loise-interpolable.ngrok-free.dev/api/v1';

  /// Format DateTime cho server (RFC3339 với timezone)
  String _formatDateTimeForServer(DateTime dt) {
    // Tạo UTC DateTime để có timezone Z
    final utc = DateTime.utc(dt.year, dt.month, dt.day, 0, 0, 0);
    return utc.toIso8601String(); // Format: 2026-06-28T00:00:00.000Z
  }

  /// Lấy danh sách mục tiêu tiết kiệm
  Future<List<SavingsGoal>> getSavingsGoals() async {
    try {
      print('🔵 [SavingsRepo] Lấy danh sách mục tiêu tiết kiệm');

      final token = await _authService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Bạn cần đăng nhập để sử dụng tính năng này');
      }

      final url = '$_baseUrl/savings';
      print('🌐 [SavingsRepo] Gửi GET đến: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      print('📡 [SavingsRepo] Status Code: ${response.statusCode}');
      print('📦 [SavingsRepo] Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final List<dynamic> data = jsonData['data'] ?? [];

        final goals = data.map((json) => SavingsGoal.fromJson(json)).toList();
        print('✅ [SavingsRepo] Lấy thành công ${goals.length} mục tiêu');
        return goals;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
          errorData['error'] ?? 'Không thể tải danh sách mục tiêu',
        );
      }
    } catch (e) {
      print('❌ [SavingsRepo] Lỗi: $e');
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
      print('🔵 [SavingsRepo] Tạo mục tiêu: $name, target: $targetAmount');

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
      print('📦 [SavingsRepo] Request body: $requestBody');

      final url = '$_baseUrl/savings';
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode(requestBody),
      );

      print('📡 [SavingsRepo] Status: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('✅ [SavingsRepo] Tạo mục tiêu thành công');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Không thể tạo mục tiêu');
      }
    } catch (e) {
      print('❌ [SavingsRepo] Lỗi: $e');
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
      print(
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

      final url = '$_baseUrl/savings/$goalId/deposit';
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode(requestBody),
      );

      print('📡 [SavingsRepo] Status: ${response.statusCode}');
      final jsonData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        print('✅ [SavingsRepo] Nạp tiền thành công');
        // Kiểm tra xem có hoàn thành mục tiêu không
        return {
          'success': true,
          'message': jsonData['message'],
          'status': jsonData['status'], // COMPLETED nếu đạt mục tiêu
        };
      } else {
        throw Exception(jsonData['error'] ?? 'Không thể nạp tiền');
      }
    } catch (e) {
      print('❌ [SavingsRepo] Lỗi: $e');
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
      print('🔵 [SavingsRepo] Rút $amount từ goal $goalId về wallet $walletId');

      final token = await _authService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Bạn cần đăng nhập để sử dụng tính năng này');
      }

      final requestBody = {
        'wallet_id': walletId,
        'amount': amount,
        if (note != null) 'note': note,
      };

      final url = '$_baseUrl/savings/$goalId/withdraw';
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode(requestBody),
      );

      print('📡 [SavingsRepo] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ [SavingsRepo] Rút tiền thành công');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Không thể rút tiền');
      }
    } catch (e) {
      print('❌ [SavingsRepo] Lỗi: $e');
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
      print('🔵 [SavingsRepo] Cập nhật mục tiêu $goalId');

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

      final url = '$_baseUrl/savings/$goalId';
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode(requestBody),
      );

      print('📡 [SavingsRepo] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ [SavingsRepo] Cập nhật mục tiêu thành công');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Không thể cập nhật mục tiêu');
      }
    } catch (e) {
      print('❌ [SavingsRepo] Lỗi: $e');
      rethrow;
    }
  }

  /// Xóa mục tiêu (phải rút hết tiền trước)
  Future<void> deleteSavingsGoal(String goalId) async {
    try {
      print('🔵 [SavingsRepo] Xóa mục tiêu $goalId');

      final token = await _authService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Bạn cần đăng nhập để sử dụng tính năng này');
      }

      final url = '$_baseUrl/savings/$goalId';
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      print('📡 [SavingsRepo] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ [SavingsRepo] Xóa mục tiêu thành công');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Không thể xóa mục tiêu');
      }
    } catch (e) {
      print('❌ [SavingsRepo] Lỗi: $e');
      rethrow;
    }
  }

  /// Lấy lịch sử giao dịch của mục tiêu
  Future<List<SavingsTransaction>> getGoalTransactions(String goalId) async {
    try {
      print('🔵 [SavingsRepo] Lấy lịch sử giao dịch của goal $goalId');

      final token = await _authService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Bạn cần đăng nhập để sử dụng tính năng này');
      }

      final url = '$_baseUrl/savings/$goalId/transactions';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      print('📡 [SavingsRepo] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final List<dynamic> data = jsonData['data'] ?? [];

        final transactions = data
            .map((json) => SavingsTransaction.fromJson(json))
            .toList();
        print(
          '✅ [SavingsRepo] Lấy thành công ${transactions.length} giao dịch',
        );
        return transactions;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
          errorData['error'] ?? 'Không thể tải lịch sử giao dịch',
        );
      }
    } catch (e) {
      print('❌ [SavingsRepo] Lỗi: $e');
      rethrow;
    }
  }
}
