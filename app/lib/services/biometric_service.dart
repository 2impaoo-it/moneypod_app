import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _userEmailKey = 'biometric_user_email';
  static const String _userPasswordKey = 'biometric_user_password';

  /// Kiểm tra xem thiết bị có hỗ trợ sinh trắc học không
  Future<bool> isBiometricAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Kiểm tra xem người dùng đã bật tính năng này chưa
  Future<bool> isBiometricEnabled() async {
    final enabled = await _storage.read(key: _biometricEnabledKey);
    return enabled == 'true';
  }

  /// Lấy danh sách các loại sinh trắc học được hỗ trợ (Vân tay, Khuôn mặt,...)
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException catch (_) {
      return <BiometricType>[];
    }
  }

  /// Thực hiện xác thực sinh trắc học
  Future<bool> authenticate() async {
    try {
      // Sử dụng API cơ bản nhất để đảm bảo tương thích
      return await _auth.authenticate(
        localizedReason: 'Vui lòng xác thực để tiếp tục',
      );
    } on PlatformException catch (e) {
      print('Biometric Error: $e');
      return false;
    }
  }

  /// Bật tính năng đăng nhập bằng sinh trắc học
  /// Cần truyền email và password để lưu vào SecureStorage
  Future<bool> enableBiometricLogin(String email, String password) async {
    // 1. Xác thực trước khi bật
    final authenticated = await authenticate();
    if (!authenticated) return false;

    // 2. Lưu thông tin an toàn
    await _storage.write(key: _biometricEnabledKey, value: 'true');
    await _storage.write(key: _userEmailKey, value: email);
    await _storage.write(key: _userPasswordKey, value: password);
    return true;
  }

  /// Tắt tính năng đăng nhập bằng sinh trắc học
  Future<void> disableBiometricLogin() async {
    await _storage.delete(key: _biometricEnabledKey);
    await _storage.delete(key: _userEmailKey);
    await _storage.delete(key: _userPasswordKey);
  }

  /// Lấy thông tin đăng nhập đã lưu (nếu đã bật và xác thực thành công)
  Future<Map<String, String>?> getStoredCredentials() async {
    final enabled = await isBiometricEnabled();
    if (!enabled) return null;

    final email = await _storage.read(key: _userEmailKey);
    final password = await _storage.read(key: _userPasswordKey);

    if (email != null && password != null) {
      return {'email': email, 'password': password};
    }
    return null;
  }
}
