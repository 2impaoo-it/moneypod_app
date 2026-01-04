import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../utils/dio_client.dart';
import '../config/app_config.dart';

/// Service để lấy insight thông minh từ Gemini AI
class InsightService {
  final AuthService _authService = AuthService();
  late final Dio _dio;

  // Cache key format: insight_YYYY_MM
  static const String _cacheKeyPrefix = 'insight_';

  InsightService() {
    _dio = DioClient.getDio(null);
    _dio.options.baseUrl = AppConfig.baseUrl;
  }

  /// Lấy insight thông minh cho tháng trước
  /// - Kiểm tra cache trước
  /// - Nếu không có cache hoặc hết tháng mới -> gọi API
  Future<String> getMonthlyInsight() async {
    try {
      final now = DateTime.now();
      // Lấy tháng trước
      final lastMonth = DateTime(now.year, now.month - 1, 1);
      final cacheKey = '$_cacheKeyPrefix${lastMonth.year}_${lastMonth.month}';

      // 1. Kiểm tra cache
      final cachedInsight = await _getCachedInsight(cacheKey);
      if (cachedInsight != null && cachedInsight.isNotEmpty) {
        debugPrint('✅ [InsightService] Sử dụng insight từ cache');
        return cachedInsight;
      }

      // 2. Không có cache -> gọi API
      debugPrint('🔵 [InsightService] Gọi API để lấy insight mới...');

      final token = await _authService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Bạn cần đăng nhập để sử dụng tính năng này');
      }

      // Gọi API backend (backend sẽ gọi Gemini)
      final response = await _dio.get(
        '/insights/monthly',
        queryParameters: {'month': lastMonth.month, 'year': lastMonth.year},
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          // Thêm timeout riêng cho insight
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 5),
        ),
      );

      if (response.statusCode == 200) {
        final insight =
            response.data['insight'] as String? ??
            'Chưa có đủ dữ liệu để phân tích.';

        // 3. Lưu vào cache
        await _cacheInsight(cacheKey, insight);

        debugPrint('✅ [InsightService] Đã lấy và cache insight mới');
        return insight;
      } else if (response.statusCode == 503) {
        // Service unavailable
        return response.data['insight'] as String? ??
            'Tính năng Insight đang được cập nhật.';
      } else {
        throw Exception('Không thể lấy insight từ server');
      }
    } on DioException catch (e) {
      debugPrint(
        '❌ [InsightService] DioException: ${e.response?.statusCode} - ${e.message}',
      );

      // Xử lý các loại lỗi khác nhau
      if (e.response?.statusCode == 404) {
        // Endpoint chưa tồn tại
        return 'Tính năng insight đang được cập nhật.';
      } else if (e.response?.statusCode == 500) {
        // Server error - không trigger dialog lỗi
        return 'Insight tạm thời không khả dụng.';
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return 'Insight đang được tạo, vui lòng chờ...';
      }

      // Lỗi khác
      return 'Không thể tải insight lúc này.';
    } catch (e) {
      debugPrint('❌ [InsightService] Error: $e');
      return 'Insight tạm thời không khả dụng.';
    }
  }

  /// Lấy insight từ cache
  Future<String?> _getCachedInsight(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } catch (e) {
      debugPrint('❌ [InsightService] Lỗi đọc cache: $e');
      return null;
    }
  }

  /// Lưu insight vào cache
  Future<void> _cacheInsight(String key, String insight) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, insight);
    } catch (e) {
      debugPrint('❌ [InsightService] Lỗi lưu cache: $e');
    }
  }

  /// Xóa cache của các tháng cũ (tùy chọn - để dọn dẹp)
  Future<void> clearOldCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      // Lấy tháng trước
      final lastMonth = DateTime(now.year, now.month - 1, 1);
      final currentCacheKey =
          '$_cacheKeyPrefix${lastMonth.year}_${lastMonth.month}';

      // Lấy tất cả keys
      final keys = prefs.getKeys();

      // Xóa các key insight cũ (không phải tháng trước)
      for (var key in keys) {
        if (key.startsWith(_cacheKeyPrefix) && key != currentCacheKey) {
          await prefs.remove(key);
          debugPrint('🗑️ [InsightService] Đã xóa cache cũ: $key');
        }
      }
    } catch (e) {
      debugPrint('❌ [InsightService] Lỗi xóa cache: $e');
    }
  }
}
