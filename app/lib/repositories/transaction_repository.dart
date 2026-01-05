import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/transaction.dart' as model;
import '../services/auth_service.dart';
import '../utils/dio_client.dart';
import '../config/app_config.dart';

/// Repository cho quản lý giao dịch
class TransactionRepository {
  final AuthService _authService;
  late final Dio _dio;

  TransactionRepository({AuthService? authService, Dio? dio})
    : _authService = authService ?? AuthService() {
    _dio = dio ?? DioClient.getDio(null);
    if (dio == null) {
      _dio.options.baseUrl = AppConfig.baseUrl;
    }
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
      debugPrint(
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

      debugPrint('📦 [TransactionRepo] Request body: $requestBody');

      // Gửi POST request
      final response = await _dio.post(
        '/transactions',
        data: requestBody,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      debugPrint('📡 [TransactionRepo] Status: ${response.statusCode}');
      debugPrint('📡 [TransactionRepo] Response: ${response.data}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(response.data['error'] ?? 'Không thể tạo giao dịch');
      }

      debugPrint('✅ [TransactionRepo] Tạo giao dịch thành công!');
    } on DioException catch (e) {
      if (e.error is SocketException) {
        throw Exception(
          'Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.',
        );
      }
      debugPrint('❌ [TransactionRepo] DioException: $e');
      throw Exception(e.response?.data['error'] ?? 'Không thể tạo giao dịch');
    } catch (e) {
      debugPrint('❌ [TransactionRepo] Exception: $e');
      rethrow;
    }
  }

  /// Lấy danh sách giao dịch của user
  Future<List<model.Transaction>> getTransactions({
    String? walletId,
    int? month,
    int? year,
    int? limit,
  }) async {
    try {
      debugPrint(
        '🔵 [TransactionRepo] Lấy danh sách giao dịch... walletId=$walletId, month=$month, year=$year, limit=$limit',
      );

      final token = await _authService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Bạn cần đăng nhập để sử dụng tính năng này');
      }

      final queryParams = <String, dynamic>{};
      if (walletId != null && walletId.isNotEmpty) {
        queryParams['wallet_id'] = walletId;
      }
      if (month != null) queryParams['month'] = month;
      if (year != null) queryParams['year'] = year;
      if (limit != null) queryParams['page_size'] = limit;

      final response = await _dio.get(
        '/transactions',
        queryParameters: queryParams,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      debugPrint('📡 [TransactionRepo] Status: ${response.statusCode}');

      if (response.statusCode != 200) {
        throw Exception(
          response.data['error'] ?? 'Không thể lấy danh sách giao dịch',
        );
      }

      final List<dynamic> transactionsJson = response.data['data'] ?? [];

      // Debug: In ra JSON để kiểm tra
      if (transactionsJson.isNotEmpty) {
        debugPrint(
          '📝 [TransactionRepo] Sample JSON: ${transactionsJson.first}',
        );
      }

      // Convert JSON to List<Transaction> - sử dụng Transaction.fromJson()
      final List<model.Transaction> transactions = transactionsJson
          .map(
            (json) => model.Transaction.fromJson(json as Map<String, dynamic>),
          )
          .toList();

      debugPrint(
        '✅ [TransactionRepo] Lấy ${transactions.length} giao dịch thành công!',
      );
      if (transactions.isNotEmpty) {
        debugPrint(
          '👤 [TransactionRepo] User: ${transactions.first.userName}, Avatar: ${transactions.first.userAvatar}',
        );
      }
      return transactions;
    } on DioException catch (e) {
      if (e.error is SocketException) {
        throw Exception(
          'Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.',
        );
      }
      debugPrint('❌ [TransactionRepo] DioException: $e');
      throw Exception(
        e.response?.data['error'] ?? 'Không thể lấy danh sách giao dịch',
      );
    } catch (e) {
      debugPrint('❌ [TransactionRepo] Exception: $e');
      rethrow;
    }
  }

  /// Cập nhật giao dịch
  ///
  /// Parameters:
  /// - [transactionId]: ID của giao dịch cần cập nhật
  /// - [amount]: Số tiền mới (optional)
  /// - [category]: Thể loại mới (optional)
  /// - [type]: Loại giao dịch mới "income" hoặc "expense" (optional)
  /// - [note]: Ghi chú mới (optional)
  Future<void> updateTransaction({
    required String transactionId,
    double? amount,
    String? category,
    String? type,
    String? note,
  }) async {
    try {
      debugPrint('🔵 [TransactionRepo] Cập nhật giao dịch: id=$transactionId');

      final token = await _authService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Bạn cần đăng nhập để sử dụng tính năng này');
      }

      // Build request body - chỉ gửi các field được cập nhật
      final requestBody = <String, dynamic>{};
      if (amount != null) requestBody['amount'] = amount;
      if (category != null) requestBody['category'] = category;
      if (type != null) requestBody['type'] = type;
      if (note != null) requestBody['note'] = note;

      debugPrint('📦 [TransactionRepo] Request body: $requestBody');

      final response = await _dio.put(
        '/transactions/$transactionId',
        data: requestBody,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      debugPrint('📡 [TransactionRepo] Status: ${response.statusCode}');

      if (response.statusCode != 200) {
        throw Exception(
          response.data['error'] ?? 'Không thể cập nhật giao dịch',
        );
      }

      debugPrint('✅ [TransactionRepo] Cập nhật giao dịch thành công!');
    } on DioException catch (e) {
      if (e.error is SocketException) {
        throw Exception(
          'Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.',
        );
      }
      debugPrint('❌ [TransactionRepo] DioException: $e');
      throw Exception(
        e.response?.data['error'] ?? 'Không thể cập nhật giao dịch',
      );
    } catch (e) {
      debugPrint('❌ [TransactionRepo] Exception: $e');
      rethrow;
    }
  }

  /// Xóa giao dịch
  ///
  /// Parameters:
  /// - [transactionId]: ID của giao dịch cần xóa
  Future<void> deleteTransaction(String transactionId) async {
    try {
      debugPrint('🔵 [TransactionRepo] Xóa giao dịch: id=$transactionId');

      final token = await _authService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Bạn cần đăng nhập để sử dụng tính năng này');
      }

      final response = await _dio.delete(
        '/transactions/$transactionId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      debugPrint('📡 [TransactionRepo] Status: ${response.statusCode}');

      if (response.statusCode != 200) {
        throw Exception(response.data['error'] ?? 'Không thể xóa giao dịch');
      }

      debugPrint('✅ [TransactionRepo] Xóa giao dịch thành công!');
    } on DioException catch (e) {
      if (e.error is SocketException) {
        throw Exception(
          'Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.',
        );
      }
      debugPrint('❌ [TransactionRepo] DioException: $e');
      throw Exception(e.response?.data['error'] ?? 'Không thể xóa giao dịch');
    } catch (e) {
      debugPrint('❌ [TransactionRepo] Exception: $e');
      rethrow;
    }
  }
}
