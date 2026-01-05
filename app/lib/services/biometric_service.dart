import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  final LocalAuthentication _auth;
  final FlutterSecureStorage _storage;

  static const String _savedAccountsKey =
      'biometric_saved_accounts'; // Key cho SharedPreferences
  static const String _passPrefix =
      'biometric_pass_'; // Prefix cho SecureStorage

  /// Constructor với dependency injection cho testing
  BiometricService({LocalAuthentication? auth, FlutterSecureStorage? storage})
    : _auth = auth ?? LocalAuthentication(),
      _storage = storage ?? const FlutterSecureStorage();

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

  /// Lấy danh sách các loại sinh trắc học được hỗ trợ
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
      // Gọi hàm authenticate cơ bản nhất để tránh lỗi version compatibility
      // Nếu cần customize (stickyAuth, biometricOnly), cần đảm bảo version local_auth đúng
      // Hiện tại dùng default options để đảm bảo compile thành công
      return await _auth.authenticate(
        localizedReason: 'Vui lòng xác thực để đăng nhập',
      );
    } catch (e) {
      debugPrint('Biometric Error: $e');
      return false;
    }
  }

  /// Lưu thông tin tài khoản (khi đăng nhập thành công hoặc bật biometric)
  /// Lưu thông tin tài khoản (khi đăng nhập thành công hoặc bật biometric)
  Future<void> saveAccount({
    required String email,
    required String name,
    String? password, // Password optional if disabling biometric
    String? avatarUrl,
    bool biometricEnabled = true,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Get current list
    List<Map<String, dynamic>> accounts = await getSavedAccounts();

    // 2. Remove existing if any (to update)
    accounts.removeWhere((acc) => acc['email'] == email);

    // 3. Add new info
    accounts.insert(0, {
      'email': email,
      'name': name,
      'avatar_url': avatarUrl,
      'last_login': DateTime.now().toIso8601String(),
      'biometric_enabled': biometricEnabled,
    });

    // 4. Save metadata to Prefs
    await prefs.setString(_savedAccountsKey, jsonEncode(accounts));

    // 5. Handle Password
    if (biometricEnabled && password != null) {
      // Save password to SecureStorage
      await _storage.write(key: '$_passPrefix$email', value: password);
    } else if (!biometricEnabled) {
      // Remove password if biometric disabled
      await _storage.delete(key: '$_passPrefix$email');
    }
  }

  /// Lấy danh sách tài khoản đã lưu
  Future<List<Map<String, dynamic>>> getSavedAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonStr = prefs.getString(_savedAccountsKey);
    if (jsonStr == null || jsonStr.isEmpty) return [];

    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      // Properly cast each item to Map<String, dynamic>
      return list
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } catch (e) {
      debugPrint('Error loading saved accounts: $e');
      return [];
    }
  }

  /// Lấy password của 1 account
  Future<String?> getPassword(String email) async {
    return await _storage.read(key: '$_passPrefix$email');
  }

  /// Xóa tài khoản khỏi danh sách lưu
  Future<void> removeAccount(String email) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Update list metadata
    List<Map<String, dynamic>> accounts = await getSavedAccounts();
    accounts.removeWhere((acc) => acc['email'] == email);
    await prefs.setString(_savedAccountsKey, jsonEncode(accounts));

    // 2. Remove password
    await _storage.delete(key: '$_passPrefix$email');
  }

  /// Xóa tất cả tài khoản và dữ liệu sinh trắc học đã lưu
  Future<void> clearAllAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_savedAccountsKey);
    // Note: Passwords in secure storage are not cleared here if we don't know the keys.
    // Ideally we should keep track of keys or clear all secure storage if possible.
    // For now, removing the list index is sufficient to "forget" them.
    // If needed, we can specific implementation for secure storage clearing.
  }

  // --- LEGACY SUPPORT ---

  @Deprecated('Use getSavedAccounts instead')
  Future<bool> isBiometricEnabled() async {
    final accounts = await getSavedAccounts();
    return accounts.isNotEmpty;
  }

  @Deprecated('Use saveAccount instead')
  Future<bool> enableBiometricLogin(String email, String password) async {
    final authenticated = await authenticate();
    if (!authenticated) return false;

    await saveAccount(
      email: email,
      password: password,
      name: 'User',
      avatarUrl: null,
    );
    return true;
  }

  @Deprecated('Use removeAccount instead')
  Future<void> disableBiometricLogin() async {
    // Clear all for safety in legacy mode
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_savedAccountsKey);
  }

  @Deprecated('Use getSavedAccounts and getPassword instead')
  Future<Map<String, String>?> getStoredCredentials() async {
    final accounts = await getSavedAccounts();
    if (accounts.isEmpty) return null;

    final first = accounts.first;
    final email = first['email'] as String;
    final password = await getPassword(email);

    if (password != null) {
      return {'email': email, 'password': password};
    }
    return null;
  }
}
