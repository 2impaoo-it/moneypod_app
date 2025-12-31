import 'package:equatable/equatable.dart';
import '../../models/notification.dart';

abstract class NotificationEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Load danh sách notifications
class NotificationLoadRequested extends NotificationEvent {
  final String token;

  NotificationLoadRequested(this.token);

  @override
  List<Object?> get props => [token];
}

/// Load unread count
class NotificationLoadUnreadCount extends NotificationEvent {
  final String token;

  NotificationLoadUnreadCount(this.token);

  @override
  List<Object?> get props => [token];
}

/// Đánh dấu một notification đã đọc
class NotificationMarkAsRead extends NotificationEvent {
  final String token;
  final String notificationId;

  NotificationMarkAsRead(this.token, this.notificationId);

  @override
  List<Object?> get props => [token, notificationId];
}

/// Đánh dấu tất cả đã đọc
class NotificationMarkAllAsRead extends NotificationEvent {
  final String token;

  NotificationMarkAllAsRead(this.token);

  @override
  List<Object?> get props => [token];
}

/// Xóa một notification
class NotificationDelete extends NotificationEvent {
  final String token;
  final String notificationId;

  NotificationDelete(this.token, this.notificationId);

  @override
  List<Object?> get props => [token, notificationId];
}

/// Xóa tất cả notifications
class NotificationDeleteAll extends NotificationEvent {
  final String token;

  NotificationDeleteAll(this.token);

  @override
  List<Object?> get props => [token];
}

/// Load settings
class NotificationLoadSettings extends NotificationEvent {
  final String token;

  NotificationLoadSettings(this.token);

  @override
  List<Object?> get props => [token];
}

/// Update settings
class NotificationUpdateSettings extends NotificationEvent {
  final String token;
  final NotificationSettings settings;

  NotificationUpdateSettings(this.token, this.settings);

  @override
  List<Object?> get props => [token, settings];
}

/// Refresh (reload cả list và unread count)
class NotificationRefresh extends NotificationEvent {
  final String token;

  NotificationRefresh(this.token);

  @override
  List<Object?> get props => [token];
}
