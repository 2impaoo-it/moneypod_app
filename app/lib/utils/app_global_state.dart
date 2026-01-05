import 'package:flutter/foundation.dart';

/// Global state để quản lý các trạng thái toàn ứng dụng
class AppGlobalState {
  AppGlobalState._();

  /// Khi true, FAB trong MainWrapper sẽ bị ẩn
  /// Được set bởi các màn hình full-screen như DebtPaymentScreen
  static final ValueNotifier<bool> hideMainFAB = ValueNotifier(false);
}
