import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/notification_repository.dart';
import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository repository;

  NotificationBloc({required this.repository}) : super(NotificationInitial()) {
    on<NotificationLoadRequested>(_onLoadRequested);
    on<NotificationLoadUnreadCount>(_onLoadUnreadCount);
    on<NotificationMarkAsRead>(_onMarkAsRead);
    on<NotificationMarkAllAsRead>(_onMarkAllAsRead);
    on<NotificationDelete>(_onDelete);
    on<NotificationDeleteAll>(_onDeleteAll);
    on<NotificationLoadSettings>(_onLoadSettings);
    on<NotificationUpdateSettings>(_onUpdateSettings);
    on<NotificationRefresh>(_onRefresh);
  }

  Future<void> _onLoadRequested(
    NotificationLoadRequested event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationLoading());
    try {
      final notifications = await repository.getNotifications(event.token);
      final unreadCount = await repository.getUnreadCount(event.token);
      emit(
        NotificationLoaded(
          notifications: notifications,
          unreadCount: unreadCount,
        ),
      );
    } catch (e) {
      emit(NotificationError('Lỗi tải thông báo: $e'));
    }
  }

  Future<void> _onLoadUnreadCount(
    NotificationLoadUnreadCount event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      final unreadCount = await repository.getUnreadCount(event.token);
      if (state is NotificationLoaded) {
        final currentState = state as NotificationLoaded;
        emit(
          NotificationLoaded(
            notifications: currentState.notifications,
            unreadCount: unreadCount,
          ),
        );
      }
    } catch (e) {
      print('Error loading unread count: $e');
    }
  }

  Future<void> _onMarkAsRead(
    NotificationMarkAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      final success = await repository.markAsRead(
        event.token,
        event.notificationId,
      );
      if (success && state is NotificationLoaded) {
        // Refresh list
        add(NotificationLoadRequested(event.token));
      }
    } catch (e) {
      emit(NotificationError('Lỗi đánh dấu đã đọc: $e'));
    }
  }

  Future<void> _onMarkAllAsRead(
    NotificationMarkAllAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      final success = await repository.markAllAsRead(event.token);
      if (success) {
        add(NotificationLoadRequested(event.token));
        emit(NotificationActionSuccess('Đã đánh dấu tất cả là đã đọc'));
      }
    } catch (e) {
      emit(NotificationError('Lỗi đánh dấu tất cả: $e'));
    }
  }

  Future<void> _onDelete(
    NotificationDelete event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      final success = await repository.deleteNotification(
        event.token,
        event.notificationId,
      );
      if (success) {
        add(NotificationLoadRequested(event.token));
        emit(NotificationActionSuccess('Đã xóa thông báo'));
      }
    } catch (e) {
      emit(NotificationError('Lỗi xóa thông báo: $e'));
    }
  }

  Future<void> _onDeleteAll(
    NotificationDeleteAll event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      final success = await repository.deleteAllNotifications(event.token);
      if (success) {
        emit(NotificationLoaded(notifications: [], unreadCount: 0));
        emit(NotificationActionSuccess('Đã xóa tất cả thông báo'));
      }
    } catch (e) {
      emit(NotificationError('Lỗi xóa tất cả: $e'));
    }
  }

  Future<void> _onLoadSettings(
    NotificationLoadSettings event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationLoading());
    try {
      final settings = await repository.getSettings(event.token);
      if (settings != null) {
        emit(NotificationSettingsLoaded(settings));
      } else {
        emit(NotificationError('Không thể tải cài đặt'));
      }
    } catch (e) {
      emit(NotificationError('Lỗi tải cài đặt: $e'));
    }
  }

  Future<void> _onUpdateSettings(
    NotificationUpdateSettings event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationLoading());
    try {
      final settings = await repository.updateSettings(
        event.token,
        event.settings,
      );
      if (settings != null) {
        emit(NotificationSettingsUpdated(settings));
        emit(NotificationActionSuccess('Đã cập nhật cài đặt'));
      } else {
        emit(NotificationError('Không thể cập nhật cài đặt'));
      }
    } catch (e) {
      emit(NotificationError('Lỗi cập nhật cài đặt: $e'));
    }
  }

  Future<void> _onRefresh(
    NotificationRefresh event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      final notifications = await repository.getNotifications(event.token);
      final unreadCount = await repository.getUnreadCount(event.token);
      emit(
        NotificationLoaded(
          notifications: notifications,
          unreadCount: unreadCount,
        ),
      );
    } catch (e) {
      emit(NotificationError('Lỗi làm mới: $e'));
    }
  }
}
