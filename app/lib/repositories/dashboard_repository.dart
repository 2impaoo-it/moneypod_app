import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/dashboard_data.dart';
import '../services/auth_service.dart';
import '../utils/dio_client.dart';
import '../config/app_config.dart';

/// Repository để lấy dữ liệu dashboard
class DashboardRepository {
  final AuthService _authService;
  late final Dio _dio;

  DashboardRepository({AuthService? authService, Dio? dio})
    : _authService = authService ?? AuthService() {
    _dio = dio ?? DioClient.getDio(null);
    if (dio == null) {
      _dio.options.baseUrl = AppConfig.baseUrl;
    }
  }

  /// Lấy tất cả dữ liệu dashboard (user, wallets, transactions)
  Future<DashboardData> getDashboardData() async {
    try {
      debugPrint('🔵 [DashboardRepo] Lấy dashboard data...');

      // Lấy token từ secure storage
      final token = await _authService.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('❌ [DashboardRepo] Không có token');
        throw Exception('Bạn cần đăng nhập để sử dụng tính năng này');
      }

      debugPrint('✅ [DashboardRepo] Đã lấy token');

      // Gửi GET request
      debugPrint('🌐 [DashboardRepo] Gửi GET đến: /dashboard');

      final response = await _dio.get(
        '/dashboard',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      debugPrint('📡 [DashboardRepo] Status code: ${response.statusCode}');
      debugPrint('📡 [DashboardRepo] Response body: ${response.data}');

      // Kiểm tra status code
      if (response.statusCode != 200) {
        debugPrint(
          '❌ [DashboardRepo] Lỗi từ server: ${response.data['error']}',
        );
        throw Exception(
          response.data['error'] ?? 'Không thể lấy dữ liệu dashboard',
        );
      }

      final dashboardData = DashboardData.fromJson(response.data['data']);

      debugPrint('✅ [DashboardRepo] Lấy dashboard data thành công!');
      return dashboardData;
    } on DioException catch (e) {
      if (e.error is SocketException) {
        debugPrint('❌ [DashboardRepo] Lỗi kết nối mạng');
        throw Exception(
          'Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.',
        );
      }
      debugPrint('❌ [DashboardRepo] DioException: $e');
      throw Exception(
        e.response?.data['error'] ?? 'Lỗi khi lấy dashboard data: $e',
      );
    } catch (e) {
      debugPrint('❌ [DashboardRepo] Exception: $e');
      rethrow;
    }
  }

  /// Lấy danh sách giao dịch theo bộ lọc (tháng, năm, category...)
  Future<List<dynamic>> getTransactionsWithFilter({
    int? month,
    int? year,
    String? category,
    String? type,
    int page = 1,
    int pageSize = 100,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) return [];

      final queryParams = {
        'page': page,
        'page_size': pageSize,
        if (month != null) 'month': month,
        if (year != null) 'year': year,
        if (category != null) 'category': category,
        if (type != null) 'type': type,
      };

      final response = await _dio.get(
        '/transactions',
        queryParameters: queryParams,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        return response.data['data'] ?? [];
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching filtered transactions: $e');
      return [];
    }
  }
}
