import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/notification.dart';

class NotificationRepository {
  static const String _baseUrl =
      'https://pseudoeconomical-loise-interpolable.ngrok-free.dev/api/v1';

  // ==================== NOTIFICATIONS ====================

  /// Lấy danh sách thông báo
  Future<List<AppNotification>> getNotifications(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/notifications'),
        headers: {
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final notifications = data['data'] as List? ?? [];
        return notifications
            .map((json) => AppNotification.fromJson(json))
            .toList();
      } else {
        print('Failed to load notifications: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching notifications: $e');
      rethrow;
    }
  }

  /// Lấy số lượng thông báo chưa đọc
  Future<int> getUnreadCount(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/notifications/unread-count'),
        headers: {
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data']['count'] ?? 0;
      } else {
        print('Failed to load unread count: ${response.statusCode}');
        return 0;
      }
    } catch (e) {
      print('Error fetching unread count: $e');
      return 0;
    }
  }

  /// Đánh dấu thông báo là đã đọc
  Future<bool> markAsRead(String token, String notificationId) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/notifications/$notificationId/read'),
        headers: {
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error marking notification as read: $e');
      return false;
    }
  }

  /// Đánh dấu tất cả thông báo là đã đọc
  Future<bool> markAllAsRead(String token) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/notifications/read-all'),
        headers: {
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error marking all notifications as read: $e');
      return false;
    }
  }

  /// Xóa một thông báo
  Future<bool> deleteNotification(String token, String notificationId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/notifications/$notificationId'),
        headers: {
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting notification: $e');
      return false;
    }
  }

  /// Xóa tất cả thông báo
  Future<bool> deleteAllNotifications(String token) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/notifications'),
        headers: {
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting all notifications: $e');
      return false;
    }
  }

  // ==================== NOTIFICATION SETTINGS ====================

  /// Lấy cài đặt thông báo
  Future<NotificationSettings?> getSettings(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/notifications/settings'),
        headers: {
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return NotificationSettings.fromJson(data['data']);
      } else {
        print('Failed to load notification settings: ${response.statusCode}');
        return null;
      }
    } catch (e) {
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
      final response = await http.put(
        Uri.parse('$_baseUrl/notifications/settings'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: json.encode(settings.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return NotificationSettings.fromJson(data['data']);
      } else {
        print('Failed to update notification settings: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error updating notification settings: $e');
      rethrow;
    }
  }
}
