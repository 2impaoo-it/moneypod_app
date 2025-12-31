import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/wallet.dart';
import '../services/auth_service.dart';

/// Repository cho quản lý ví
class WalletRepository {
  final AuthService _authService = AuthService();

  // URL server backend
  static const String _baseUrl =
      'https://pseudoeconomical-loise-interpolable.ngrok-free.dev/api/v1';

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
      print('🔵 [WalletRepo] Bắt đầu tạo ví: name=$name, balance=$balance');

      // Lấy token từ secure storage
      final token = await _authService.getToken();
      if (token == null || token.isEmpty) {
        print('❌ [WalletRepo] Không có token');
        throw Exception('Bạn cần đăng nhập để sử dụng tính năng này');
      }

      print('✅ [WalletRepo] Đã lấy token: ${token.substring(0, 20)}...');

      // Tạo request body
      final requestBody = {'name': name, 'balance': balance};
      print('📦 [WalletRepo] Request body: $requestBody');

      // Gửi POST request
      final url = '$_baseUrl/wallets';
      print('🌐 [WalletRepo] Gửi POST đến: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
        body: json.encode(requestBody),
      );

      print('📡 [WalletRepo] Status code: ${response.statusCode}');
      print('📡 [WalletRepo] Response body: ${response.body}');

      // Kiểm tra status code
      if (response.statusCode != 200 && response.statusCode != 201) {
        final errorData = json.decode(response.body);
        print('❌ [WalletRepo] Lỗi từ server: ${errorData['error']}');
        throw Exception(errorData['error'] ?? 'Không thể tạo ví');
      }

      print('✅ [WalletRepo] Tạo ví thành công!');
      // Thành công
    } on SocketException {
      print('❌ [WalletRepo] Lỗi kết nối mạng');
      throw Exception(
        'Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.',
      );
    } catch (e) {
      print('❌ [WalletRepo] Exception: $e');
      if (e.toString().contains('Exception')) {
        rethrow;
      }
      throw Exception('Lỗi khi tạo ví: $e');
    }
  }

  /// Lấy danh sách tất cả ví của user
  Future<List<Wallet>> getWallets() async {
    try {
      print('🔵 [WalletRepo] Lấy danh sách ví...');

      // Lấy token từ secure storage
      final token = await _authService.getToken();
      if (token == null || token.isEmpty) {
        print('❌ [WalletRepo] Không có token');
        throw Exception('Bạn cần đăng nhập để sử dụng tính năng này');
      }

      print('✅ [WalletRepo] Đã lấy token');

      // Gửi GET request
      final url = '$_baseUrl/wallets';
      print('🌐 [WalletRepo] Gửi GET đến: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📡 [WalletRepo] Status code: ${response.statusCode}');
      print('📡 [WalletRepo] Response body: ${response.body}');

      // Kiểm tra status code
      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        print('❌ [WalletRepo] Lỗi từ server: ${errorData['error']}');
        throw Exception(errorData['error'] ?? 'Không thể lấy danh sách ví');
      }

      // Parse response
      final Map<String, dynamic> responseData = json.decode(response.body);
      final List<dynamic> walletsJson = responseData['data'] ?? [];

      // Convert JSON to List<Wallet>
      final List<Wallet> wallets = walletsJson
          .map((json) => Wallet.fromJson(json as Map<String, dynamic>))
          .toList();

      print('✅ [WalletRepo] Lấy ${wallets.length} ví thành công!');
      return wallets;
    } on SocketException {
      print('❌ [WalletRepo] Lỗi kết nối mạng');
      throw Exception(
        'Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.',
      );
    } catch (e) {
      print('❌ [WalletRepo] Exception: $e');
      if (e.toString().contains('Exception')) {
        rethrow;
      }
      throw Exception('Lỗi khi lấy danh sách ví: $e');
    }
  }

  /// Cập nhật thông tin ví
  Future<void> updateWallet({
    required String id,
    required String name,
    required double balance,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('Chưa đăng nhập');

      final url = '$_baseUrl/wallets/$id';
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'name': name, 'balance': balance}),
      );

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Không thể cập nhật ví');
      }
    } catch (e) {
      throw Exception('Lỗi khi cập nhật ví: $e');
    }
  }

  /// Xóa ví
  Future<void> deleteWallet(String id) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('Chưa đăng nhập');

      final url = '$_baseUrl/wallets/$id';
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Không thể xóa ví');
      }
    } catch (e) {
      throw Exception('Lỗi khi xóa ví: $e');
    }
  }
}
