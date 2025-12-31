import 'package:equatable/equatable.dart';
import '../../models/notification.dart';

abstract class NotificationState extends Equatable {
  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {}

class NotificationLoading extends NotificationState {}

class NotificationLoaded extends NotificationState {
  final List<AppNotification> notifications;
  final int unreadCount;

  NotificationLoaded({required this.notifications, required this.unreadCount});

  @override
  List<Object?> get props => [notifications, unreadCount];
}

class NotificationError extends NotificationState {
  final String message;

  NotificationError(this.message);

  @override
  List<Object?> get props => [message];
}

class NotificationSettingsLoaded extends NotificationState {
  final NotificationSettings settings;

  NotificationSettingsLoaded(this.settings);

  @override
  List<Object?> get props => [settings];
}

class NotificationSettingsUpdated extends NotificationState {
  final NotificationSettings settings;

  NotificationSettingsUpdated(this.settings);

  @override
  List<Object?> get props => [settings];
}

class NotificationActionSuccess extends NotificationState {
  final String message;

  NotificationActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}
