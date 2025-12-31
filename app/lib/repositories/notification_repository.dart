import 'package:dio/dio.dart';
import '../models/notification.dart';
import '../utils/dio_client.dart';

class NotificationRepository {
  static const String _baseUrl =
      'https://pseudoeconomical-loise-interpolable.ngrok-free.dev/api/v1';
  late final Dio _dio;

  NotificationRepository() {
    _dio = DioClient.getDio(null);
    _dio.options.baseUrl = _baseUrl;
  }

  // ==================== NOTIFICATIONS ====================

  /// Lấy danh sách thông báo
  Future<List<AppNotification>> getNotifications(String token) async {
    try {
      final response = await _dio.get(
        '/notifications',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final notifications = response.data['data'] as List? ?? [];
        return notifications
            .map((json) => AppNotification.fromJson(json))
            .toList();
      } else {
        print('Failed to load notifications: ${response.statusCode}');
        return [];
      }
    } on DioException catch (e) {
      print('Error fetching notifications: $e');
      rethrow;
    }
  }

  /// Lấy số lượng thông báo chưa đọc
  Future<int> getUnreadCount(String token) async {
    try {
      final response = await _dio.get(
        '/notifications/unread-count',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        if (data != null && data is Map) {
          return data['count'] ?? 0;
        }
        return 0;
      } else {
        print('Failed to load unread count: ${response.statusCode}');
        return 0;
      }
    } on DioException catch (e) {
      print('DioException fetching unread count: ${e.message}');
      // Không throw lại exception, chỉ return 0
      return 0;
    } catch (e) {
      print('Unexpected error fetching unread count: $e');
      // Không throw lại exception, chỉ return 0
      return 0;
    }
  }

  /// Đánh dấu thông báo là đã đọc
  Future<bool> markAsRead(String token, String notificationId) async {
    try {
      final response = await _dio.put(
        '/notifications/$notificationId/read',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      return response.statusCode == 200;
    } on DioException catch (e) {
      print('Error marking notification as read: $e');
      return false;
    }
  }

  /// Đánh dấu tất cả thông báo là đã đọc
  Future<bool> markAllAsRead(String token) async {
    try {
      final response = await _dio.put(
        '/notifications/read-all',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      return response.statusCode == 200;
    } on DioException catch (e) {
      print('Error marking all notifications as read: $e');
      return false;
    }
  }

  /// Xóa một thông báo
  Future<bool> deleteNotification(String token, String notificationId) async {
    try {
      final response = await _dio.delete(
        '/notifications/$notificationId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      return response.statusCode == 200 ||
          response.statusCode == 204 ||
          response.statusCode == 201;
    } on DioException catch (e) {
      print('Error deleting notification: $e');
      return false;
    }
  }

  /// Xóa tất cả thông báo
  Future<bool> deleteAllNotifications(String token) async {
    try {
      final response = await _dio.delete(
        '/notifications/all',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      return response.statusCode == 200 ||
          response.statusCode == 204 ||
          response.statusCode == 201;
    } on DioException catch (e) {
      print('Error deleting all notifications: $e');
      return false;
    }
  }

  // ==================== NOTIFICATION SETTINGS ====================

  /// Lấy cài đặt thông báo
  Future<NotificationSettings?> getSettings(String token) async {
    try {
      final response = await _dio.get(
        '/notifications/settings',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        return NotificationSettings.fromJson(response.data['data']);
      } else {
        print('Failed to load notification settings: ${response.statusCode}');
        return null;
      }
    } on DioException catch (e) {
      print('Error fetching notification settings: $e');
      rethrow;
    }
  }

  /// Cập nhật cài đặt thông báo
  Future<NotificationSettings?> updateSettings(
    String token,
    NotificationSettings settings,
  ) async {
    try {
      final response = await _dio.put(
        '/notifications/settings',
        data: settings.toJson(),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        return NotificationSettings.fromJson(response.data['data']);
      } else {
        print('Failed to update notification settings: ${response.statusCode}');
        return null;
      }
    } on DioException catch (e) {
      print('Error updating notification settings: $e');
      rethrow;
    }
  }
}
