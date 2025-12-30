import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/transaction.dart' as model;
import '../services/auth_service.dart';

/// Repository cho quản lý giao dịch
class TransactionRepository {
  final AuthService _authService = AuthService();
  static const String _baseUrl =
      'https://pseudoeconomical-loise-interpolable.ngrok-free.dev/api/v1';

  /// Tạo giao dịch mới
  ///
  /// Parameters:
  /// - [walletId]: ID của ví (bắt buộc)
  /// - [amount]: Số tiền (bắt buộc)
  /// - [category]: Thể loại (Ăn uống, Di chuyển, etc.)
  /// - [type]: "income" hoặc "expense"
  /// - [note]: Ghi chú
  Future<void> createTransaction({
    required String walletId,
    required double amount,
    required String category,
    required String type, // "income" or "expense"
    String? note,
  }) async {
    try {
      print(
        '🔵 [TransactionRepo] Tạo giao dịch: wallet=$walletId, amount=$amount, type=$type',
      );

      // Lấy token
      final token = await _authService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Bạn cần đăng nhập để sử dụng tính năng này');
      }

      // Request body
      final requestBody = {
        'wallet_id': walletId,
        'amount': amount,
        'category': category,
        'type': type,
        'note': note ?? '',
      };

      print('📦 [TransactionRepo] Request body: $requestBody');

      // Gửi POST request
      final response = await http.post(
        Uri.parse('$_baseUrl/transactions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
        body: json.encode(requestBody),
      );

      print('📡 [TransactionRepo] Status: ${response.statusCode}');
      print('📡 [TransactionRepo] Response: ${response.body}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Không thể tạo giao dịch');
      }

      print('✅ [TransactionRepo] Tạo giao dịch thành công!');
    } on SocketException {
      throw Exception(
        'Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.',
      );
    } catch (e) {
      print('❌ [TransactionRepo] Exception: $e');
      rethrow;
    }
  }

  /// Lấy danh sách giao dịch của user
  Future<List<model.Transaction>> getTransactions() async {
    try {
      print('🔵 [TransactionRepo] Lấy danh sách giao dịch...');

      final token = await _authService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Bạn cần đăng nhập để sử dụng tính năng này');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/transactions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📡 [TransactionRepo] Status: ${response.statusCode}');

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(
          errorData['error'] ?? 'Không thể lấy danh sách giao dịch',
        );
      }

      final Map<String, dynamic> responseData = json.decode(response.body);
      final List<dynamic> transactionsJson = responseData['data'] ?? [];

      // Convert JSON to List<Transaction>
      final List<model.Transaction> transactions = transactionsJson
          .map((json) => _transactionFromJson(json as Map<String, dynamic>))
          .toList();

      print(
        '✅ [TransactionRepo] Lấy ${transactions.length} giao dịch thành công!',
      );
      return transactions;
    } on SocketException {
      throw Exception(
        'Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.',
      );
    } catch (e) {
      print('❌ [TransactionRepo] Exception: $e');
      rethrow;
    }
  }

  /// Helper: Convert JSON từ server sang Transaction model
  model.Transaction _transactionFromJson(Map<String, dynamic> json) {
    return model.Transaction(
      id: json['ID']?.toString() ?? '',
      title: json['note'] ?? '', // Dùng note làm title
      category: json['category'] ?? 'Khác',
      amount: _parseDouble(json['amount'] ?? 0),
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      isExpense: json['type'] == 'expense',
      hashtag: json['category'],
    );
  }

  /// Helper: Parse double từ dynamic
  static double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
