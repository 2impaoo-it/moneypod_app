import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/wallet.dart';
import '../services/auth_service.dart';
import '../utils/dio_client.dart';
import '../config/app_config.dart';

/// Repository cho quản lý ví
class WalletRepository {
  final AuthService _authService;
  late final Dio _dio;

  WalletRepository({AuthService? authService, Dio? dio})
    : _authService = authService ?? AuthService() {
    _dio = dio ?? DioClient.getDio(null);
    if (dio == null) {
      _dio.options.baseUrl = AppConfig.baseUrl;
    }
  }

  /// Tạo ví mới
  ///
  /// Parameters:
  /// - [name]: Tên ví (bắt buộc)
  /// - [balance]: Số dư ban đầu (mặc định 0)
  Future<void> createWallet({
    required String name,
    double balance = 0.0,
  }) async {
    try {
      debugPrint(
        '🔵 [WalletRepo] Bắt đầu tạo ví: name=$name, balance=$balance',
      );

      // Lấy token từ secure storage
      final token = await _authService.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('❌ [WalletRepo] Không có token');
        throw Exception('Bạn cần đăng nhập để sử dụng tính năng này');
      }

      debugPrint('✅ [WalletRepo] Đã lấy token: ${token.substring(0, 20)}...');

      // Tạo request body
      final requestBody = {'name': name, 'balance': balance};
      debugPrint('📦 [WalletRepo] Request body: $requestBody');

      // Gửi POST request
      debugPrint('🌐 [WalletRepo] Gửi POST đến: /wallets');

      final response = await _dio.post(
        '/wallets',
        data: requestBody,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      debugPrint('📡 [WalletRepo] Status code: ${response.statusCode}');
      debugPrint('📡 [WalletRepo] Response body: ${response.data}');

      // Kiểm tra status code
      if (response.statusCode != 200 && response.statusCode != 201) {
        debugPrint('❌ [WalletRepo] Lỗi từ server: ${response.data['error']}');
        throw Exception(response.data['error'] ?? 'Không thể tạo ví');
      }

      debugPrint('✅ [WalletRepo] Tạo ví thành công!');
      // Thành công
    } on DioException catch (e) {
      if (e.error is SocketException) {
        debugPrint('❌ [WalletRepo] Lỗi kết nối mạng');
        throw Exception(
          'Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.',
        );
      }
      debugPrint('❌ [WalletRepo] DioException: $e');
      throw Exception(e.response?.data['error'] ?? 'Lỗi khi tạo ví: $e');
    } catch (e) {
      debugPrint('❌ [WalletRepo] Exception: $e');
      rethrow;
    }
  }

  /// Lấy danh sách tất cả ví của user
  Future<List<Wallet>> getWallets() async {
    try {
      debugPrint('🔵 [WalletRepo] Lấy danh sách ví...');

      // Lấy token từ secure storage
      final token = await _authService.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('❌ [WalletRepo] Không có token');
        throw Exception('Bạn cần đăng nhập để sử dụng tính năng này');
      }

      debugPrint('✅ [WalletRepo] Đã lấy token');

      // Gửi GET request
      debugPrint('🌐 [WalletRepo] Gửi GET đến: /wallets');

      final response = await _dio.get(
        '/wallets',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      debugPrint('📡 [WalletRepo] Status code: ${response.statusCode}');
      debugPrint('📡 [WalletRepo] Response body: ${response.data}');

      // Kiểm tra status code
      if (response.statusCode != 200) {
        debugPrint('❌ [WalletRepo] Lỗi từ server: ${response.data['error']}');
        throw Exception(response.data['error'] ?? 'Không thể lấy danh sách ví');
      }

      // Parse response
      final List<dynamic> walletsJson = response.data['data'] ?? [];

      // Convert JSON to List<Wallet>
      final List<Wallet> wallets = walletsJson
          .map((json) => Wallet.fromJson(json as Map<String, dynamic>))
          .toList();

      debugPrint('✅ [WalletRepo] Lấy ${wallets.length} ví thành công!');
      return wallets;
    } on DioException catch (e) {
      if (e.error is SocketException) {
        debugPrint('❌ [WalletRepo] Lỗi kết nối mạng');
        throw Exception(
          'Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.',
        );
      }
      debugPrint('❌ [WalletRepo] DioException: $e');
      throw Exception(
        e.response?.data['error'] ?? 'Lỗi khi lấy danh sách ví: $e',
      );
    } catch (e) {
      debugPrint('❌ [WalletRepo] Exception: $e');
      rethrow;
    }
  }

  /// Cập nhật thông tin ví
  Future<void> updateWallet({
    required String id,
    required String name,
    String? currency,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('Chưa đăng nhập');

      final data = <String, dynamic>{'name': name};
      if (currency != null) {
        data['currency'] = currency;
      }

      final response = await _dio.put(
        '/wallets/$id',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode != 200) {
        throw Exception(response.data['error'] ?? 'Không thể cập nhật ví');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Lỗi khi cập nhật ví: $e');
    } catch (e) {
      throw Exception('Lỗi khi cập nhật ví: $e');
    }
  }

  /// Xóa ví
  Future<void> deleteWallet(String id) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('Chưa đăng nhập');

      final response = await _dio.delete(
        '/wallets/$id',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode != 200) {
        throw Exception(response.data['error'] ?? 'Không thể xóa ví');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Lỗi khi xóa ví: $e');
    } catch (e) {
      throw Exception('Lỗi khi xóa ví: $e');
    }
  }

  /// Chuyển tiền giữa các ví
  Future<void> transferBetweenWallets({
    required String fromWalletId,
    required String toWalletId,
    required double amount,
    String? note,
  }) async {
    try {
      debugPrint('🔵 [WalletRepo] Bắt đầu chuyển tiền...');

      final token = await _authService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Bạn cần đăng nhập để sử dụng tính năng này');
      }

      final requestBody = {
        'from_wallet_id': fromWalletId,
        'to_wallet_id': toWalletId,
        'amount': amount,
        if (note != null && note.isNotEmpty) 'note': note,
      };

      debugPrint('📦 [WalletRepo] Request body: $requestBody');

      final response = await _dio.post(
        '/wallets/transfer',
        data: requestBody,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      debugPrint('📡 [WalletRepo] Status code: ${response.statusCode}');

      if (response.statusCode != 200) {
        throw Exception(response.data['error'] ?? 'Không thể chuyển tiền');
      }

      debugPrint('✅ [WalletRepo] Chuyển tiền thành công!');
    } on DioException catch (e) {
      if (e.error is SocketException) {
        throw Exception(
          'Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.',
        );
      }
      debugPrint('❌ [WalletRepo] DioException: $e');
      throw Exception(e.response?.data['error'] ?? 'Lỗi khi chuyển tiền');
    } catch (e) {
      debugPrint('❌ [WalletRepo] Exception: $e');
      rethrow;
    }
  }
}
