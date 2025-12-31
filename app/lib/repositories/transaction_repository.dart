import 'dart:io';
import 'package:dio/dio.dart';
import '../models/transaction.dart' as model;
import '../services/auth_service.dart';
import '../utils/dio_client.dart';

/// Repository cho quản lý giao dịch
class TransactionRepository {
  final AuthService _authService = AuthService();
  static const String _baseUrl =
      'https://pseudoeconomical-loise-interpolable.ngrok-free.dev/api/v1';
  late final Dio _dio;

  TransactionRepository() {
    _dio = DioClient.getDio(null);
    _dio.options.baseUrl = _baseUrl;
  }

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
      final response = await _dio.post(
        '/transactions',
        data: requestBody,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      print('📡 [TransactionRepo] Status: ${response.statusCode}');
      print('📡 [TransactionRepo] Response: ${response.data}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(response.data['error'] ?? 'Không thể tạo giao dịch');
      }

      print('✅ [TransactionRepo] Tạo giao dịch thành công!');
    } on DioException catch (e) {
      if (e.error is SocketException) {
        throw Exception(
          'Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.',
        );
      }
      print('❌ [TransactionRepo] DioException: $e');
      throw Exception(e.response?.data['error'] ?? 'Không thể tạo giao dịch');
    } catch (e) {
      print('❌ [TransactionRepo] Exception: $e');
      rethrow;
    }
  }

  /// Lấy danh sách giao dịch của user
  Future<List<model.Transaction>> getTransactions({String? walletId}) async {
    try {
      print(
        '🔵 [TransactionRepo] Lấy danh sách giao dịch... walletId=$walletId',
      );

      final token = await _authService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Bạn cần đăng nhập để sử dụng tính năng này');
      }

      final queryParams = <String, dynamic>{};
      if (walletId != null && walletId.isNotEmpty) {
        queryParams['wallet_id'] = walletId;
      }

      final response = await _dio.get(
        '/transactions',
        queryParameters: queryParams,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      print('📡 [TransactionRepo] Status: ${response.statusCode}');

      if (response.statusCode != 200) {
        throw Exception(
          response.data['error'] ?? 'Không thể lấy danh sách giao dịch',
        );
      }

      final List<dynamic> transactionsJson = response.data['data'] ?? [];

      // Convert JSON to List<Transaction>
      final List<model.Transaction> transactions = transactionsJson
          .map((json) => _transactionFromJson(json as Map<String, dynamic>))
          .toList();

      print(
        '✅ [TransactionRepo] Lấy ${transactions.length} giao dịch thành công!',
      );
      return transactions;
    } on DioException catch (e) {
      if (e.error is SocketException) {
        throw Exception(
          'Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.',
        );
      }
      print('❌ [TransactionRepo] DioException: $e');
      throw Exception(
        e.response?.data['error'] ?? 'Không thể lấy danh sách giao dịch',
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
