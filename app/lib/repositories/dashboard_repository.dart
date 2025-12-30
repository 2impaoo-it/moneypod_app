import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/dashboard_data.dart';
import '../services/auth_service.dart';

/// Repository để lấy dữ liệu dashboard
class DashboardRepository {
  final AuthService _authService = AuthService();

  // URL server backend
  static const String _baseUrl =
      'https://pseudoeconomical-loise-interpolable.ngrok-free.dev/api/v1';

  /// Lấy tất cả dữ liệu dashboard (user, wallets, transactions)
  Future<DashboardData> getDashboardData() async {
    try {
      print('🔵 [DashboardRepo] Lấy dashboard data...');

      // Lấy token từ secure storage
      final token = await _authService.getToken();
      if (token == null || token.isEmpty) {
        print('❌ [DashboardRepo] Không có token');
        throw Exception('Bạn cần đăng nhập để sử dụng tính năng này');
      }

      print('✅ [DashboardRepo] Đã lấy token');

      // Gửi GET request
      final url = '$_baseUrl/dashboard';
      print('🌐 [DashboardRepo] Gửi GET đến: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      print('📡 [DashboardRepo] Status code: ${response.statusCode}');
      print('📡 [DashboardRepo] Response body: ${response.body}');

      // Kiểm tra status code
      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        print('❌ [DashboardRepo] Lỗi từ server: ${errorData['error']}');
        throw Exception(
          errorData['error'] ?? 'Không thể lấy dữ liệu dashboard',
        );
      }

      final responseData = json.decode(response.body);
      final dashboardData = DashboardData.fromJson(responseData['data']);

      print('✅ [DashboardRepo] Lấy dashboard data thành công!');
      return dashboardData;
    } on SocketException {
      print('❌ [DashboardRepo] Lỗi kết nối mạng');
      throw Exception(
        'Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.',
      );
    } catch (e) {
      print('❌ [DashboardRepo] Exception: $e');
      if (e.toString().contains('Exception')) {
        rethrow;
      }
      throw Exception('Lỗi khi lấy dashboard data: $e');
    }
  }
}
