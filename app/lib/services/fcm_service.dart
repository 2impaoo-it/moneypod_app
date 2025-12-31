import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

/// Service để xử lý Firebase Cloud Messaging
class FCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static const String _fcmTokenKey = 'fcm_token';

  /// Initialize FCM và request permissions
  Future<void> initialize() async {
    try {
      // Request permission (iOS)
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ FCM: User đã cho phép thông báo');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        debugPrint('⚠️ FCM: User cho phép thông báo tạm thời');
      } else {
        debugPrint('❌ FCM: User từ chối thông báo');
        return;
      }

      // Get FCM token
      String? token = await _messaging.getToken();
      if (token != null) {
        debugPrint('🔑 FCM Token: $token');
        await _saveFCMToken(token);
      }

      // Listen token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        debugPrint('🔄 FCM Token refreshed: $newToken');
        _saveFCMToken(newToken);
      });

      // Setup message handlers
      _setupMessageHandlers();
    } catch (e) {
      debugPrint('❌ FCM initialization error: $e');
    }
  }

  /// Lưu FCM token vào SharedPreferences
  Future<void> _saveFCMToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_fcmTokenKey, token);
      debugPrint('💾 Đã lưu FCM token');

      // 🔥 GỬI TOKEN LÊN SERVER
      await _updateFCMTokenToServer(token);
    } catch (e) {
      debugPrint('❌ Lỗi lưu FCM token: $e');
    }
  }

  /// Gửi FCM token lên server
  Future<void> _updateFCMTokenToServer(String token) async {
    try {
      final authService = AuthService();
      final result = await authService.updateFCMToken(token);

      if (result['success'] == true) {
        debugPrint('✅ Đã cập nhật FCM token lên server');
      } else {
        debugPrint('⚠️ Không cập nhật được FCM token: ${result['message']}');
      }
    } catch (e) {
      debugPrint('❌ Lỗi gửi FCM token lên server: $e');
    }
  }

  /// Lấy FCM token đã lưu
  Future<String?> getSavedFCMToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_fcmTokenKey);
    } catch (e) {
      debugPrint('❌ Lỗi lấy FCM token: $e');
      return null;
    }
  }

  /// Get current FCM token
  Future<String?> getCurrentToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      debugPrint('❌ Lỗi lấy FCM token hiện tại: $e');
      return null;
    }
  }

  /// Setup các handlers cho notifications
  void _setupMessageHandlers() {
    // Foreground messages (khi app đang mở)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📩 Nhận notification khi app đang mở:');
      debugPrint('   Title: ${message.notification?.title}');
      debugPrint('   Body: ${message.notification?.body}');
      debugPrint('   Data: ${message.data}');

      // 🔥 Hiển thị notification ngay cả khi app đang mở
      // Để hiển thị native notification, cần dùng flutter_local_notifications
      // Tạm thời log ra, user sẽ thấy trong notification list
      debugPrint(
        '✅ Notification đã được lưu vào DB, kiểm tra trong Notification List',
      );
    });

    // Background messages (khi user tap vào notification)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('🔔 User tap vào notification:');
      debugPrint('   Data: ${message.data}');

      // TODO: Navigate dựa vào message.data
      _handleNotificationTap(message);
    });

    // Check xem app có được mở từ terminated state không
    _checkInitialMessage();
  }

  /// Kiểm tra nếu app được mở từ notification khi terminated
  Future<void> _checkInitialMessage() async {
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();

    if (initialMessage != null) {
      debugPrint('🚀 App được mở từ notification (terminated state)');
      debugPrint('   Data: ${initialMessage.data}');

      // TODO: Navigate dựa vào initialMessage.data
      _handleNotificationTap(initialMessage);
    }
  }

  /// Xử lý khi user tap vào notification
  void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    final type = data['type'];

    debugPrint('🔗 Notification type: $type');

    // Use NotificationHandler to navigate
    // Note: This requires navigatorKey to be available
    // Import: import '../utils/notification_handler.dart';
    // Usage:
    // final context = navigatorKey.currentContext;
    // if (context != null) {
    //   NotificationHandler.handleFCMNotificationTap(context, data);
    // }

    // For now, just log the data
    debugPrint('📱 FCM Data: $data');
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('✅ Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('❌ Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('❌ Error unsubscribing from topic: $e');
    }
  }

  /// Delete FCM token (khi logout)
  Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_fcmTokenKey);
      debugPrint('🗑️ Đã xóa FCM token');
    } catch (e) {
      debugPrint('❌ Lỗi xóa FCM token: $e');
    }
  }
}

/// Background message handler (phải là top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('🔔 Background message received:');
  debugPrint('   Title: ${message.notification?.title}');
  debugPrint('   Body: ${message.notification?.body}');
  debugPrint('   Data: ${message.data}');
}
