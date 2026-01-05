import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Quản lý Session Timeout (Auto Logout sau khi out app)
///
/// Nguyên lý:
/// - Khi App bị ẩn (paused) → Lưu thời gian vào storage
/// - Khi App mở lại (resumed) → Kiểm tra thời gian, nếu > timeout → Logout
class SessionManager {
  static const String _keyLastPaused = 'last_paused_time';

  // Thời gian timeout tính bằng GIÂY (để dễ test)
  // Production: 600 giây = 10 phút
  // Testing: 30 giây
  static const int timeoutSeconds =
      600; // 30 giây để test, đổi về 600 cho production

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  /// Gọi khi App bị ẩn (Paused) - Lưu thời gian hiện tại
  static Future<void> saveLastActiveTime() async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch.toString();
      await _storage.write(key: _keyLastPaused, value: now);
      debugPrint('📱 [SessionManager] ====== APP PAUSED ======');
      debugPrint('📱 [SessionManager] Saved time: ${DateTime.now()}');
      debugPrint('📱 [SessionManager] Timeout after: $timeoutSeconds seconds');
    } catch (e) {
      debugPrint('❌ [SessionManager] Error saving pause time: $e');
    }
  }

  /// Gọi khi App mở lại (Resumed hoặc Start)
  /// Trả về true nếu CẦN ĐĂNG NHẬP LẠI (đã hết hạn session)
  static Future<bool> checkSessionExpired() async {
    try {
      debugPrint('📱 [SessionManager] ====== CHECKING SESSION ======');

      // Kiểm tra xem có token không (nếu chưa login thì không cần check)
      final token = await _storage.read(key: 'auth_token');
      debugPrint(
        '📱 [SessionManager] Token exists: ${token != null && token.isNotEmpty}',
      );

      if (token == null || token.isEmpty) {
        debugPrint('📱 [SessionManager] No token found - Skip timeout check');
        return false; // Chưa login, không cần check timeout
      }

      // Lấy thời gian lần cuối app bị pause
      final lastPausedStr = await _storage.read(key: _keyLastPaused);
      debugPrint('📱 [SessionManager] Last paused time raw: $lastPausedStr');

      if (lastPausedStr == null) {
        debugPrint(
          '📱 [SessionManager] No pause time found - First time or just logged in',
        );
        return false; // Chưa lưu thời gian bao giờ
      }

      final lastPaused = int.tryParse(lastPausedStr);
      if (lastPaused == null) {
        await _storage.delete(key: _keyLastPaused);
        return false;
      }

      final lastDate = DateTime.fromMillisecondsSinceEpoch(lastPaused);
      final now = DateTime.now();
      final diff = now.difference(lastDate);

      debugPrint('📱 [SessionManager] Last pause: $lastDate');
      debugPrint('📱 [SessionManager] Now: $now');
      debugPrint(
        '📱 [SessionManager] Diff: ${diff.inSeconds} seconds (${diff.inMinutes} minutes)',
      );
      debugPrint(
        '📱 [SessionManager] Timeout threshold: $timeoutSeconds seconds',
      );

      if (diff.inSeconds >= timeoutSeconds) {
        // Đã quá timeout → Xóa Token và báo hết hạn
        debugPrint('⏰ [SessionManager] ====== SESSION EXPIRED! ======');
        debugPrint(
          '⏰ [SessionManager] ${diff.inSeconds} >= $timeoutSeconds seconds',
        );
        await clearSession();
        return true;
      }

      // Chưa quá timeout → Xóa mốc thời gian cũ để user dùng tiếp
      await _storage.delete(key: _keyLastPaused);
      debugPrint(
        '✅ [SessionManager] Session still valid (${diff.inSeconds}s < ${timeoutSeconds}s)',
      );
      return false;
    } catch (e) {
      debugPrint('❌ [SessionManager] Error checking session: $e');
      return false;
    }
  }

  /// Xóa toàn bộ session data khi logout hoặc hết hạn
  static Future<void> clearSession() async {
    try {
      await _storage.delete(key: 'auth_token');
      await _storage.delete(key: _keyLastPaused);
      debugPrint('🚪 [SessionManager] Session cleared - User logged out');
    } catch (e) {
      debugPrint('❌ [SessionManager] Error clearing session: $e');
    }
  }

  /// Reset thời gian pause (gọi khi user có hoạt động)
  static Future<void> resetPauseTime() async {
    try {
      await _storage.delete(key: _keyLastPaused);
    } catch (e) {
      debugPrint('❌ [SessionManager] Error resetting pause time: $e');
    }
  }

  /// Kiểm tra user đã đăng nhập chưa
  static Future<bool> isLoggedIn() async {
    try {
      final token = await _storage.read(key: 'auth_token');
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
