import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_state.dart';
import '../bloc/notification/notification_bloc.dart';
import '../bloc/notification/notification_event.dart';
import '../bloc/notification/notification_state.dart';
import '../models/notification.dart';
import '../repositories/notification_repository.dart';
import 'notification_settings_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Setup Vietnamese timeago
    timeago.setLocaleMessages('vi', timeago.ViMessages());

    return BlocProvider(
      create: (context) {
        final authState = context.read<AuthBloc>().state;
        final token = authState is AuthAuthenticated
            ? authState.user.token
            : null;
        return NotificationBloc(repository: NotificationRepository())
          ..add(NotificationLoadRequested(token ?? ''));
      },
      child: const _NotificationsScreenView(),
    );
  }
}

class _NotificationsScreenView extends StatelessWidget {
  const _NotificationsScreenView();

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final token = authState is AuthAuthenticated ? authState.user.token : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          // Settings icon
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationSettingsScreen(),
                ),
              );
            },
          ),
          // Mark all as read
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'mark_all_read' && token != null) {
                context.read<NotificationBloc>().add(
                  NotificationMarkAllAsRead(token),
                );
              } else if (value == 'delete_all' && token != null) {
                _showDeleteAllDialog(context, token);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mark_all_read',
                child: Row(
                  children: [
                    Icon(Icons.done_all, size: 20),
                    SizedBox(width: 8),
                    Text('Đánh dấu tất cả đã đọc'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Xóa tất cả', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: BlocConsumer<NotificationBloc, NotificationState>(
        listener: (context, state) {
          if (state is NotificationActionSuccess) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          } else if (state is NotificationError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is NotificationLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is NotificationError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (token != null) {
                        context.read<NotificationBloc>().add(
                          NotificationLoadRequested(token),
                        );
                      }
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          if (state is NotificationLoaded) {
            if (state.notifications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_none,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Chưa có thông báo nào',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                if (token != null) {
                  context.read<NotificationBloc>().add(
                    NotificationRefresh(token),
                  );
                }
              },
              child: ListView.separated(
                padding: const EdgeInsets.all(8),
                itemCount: state.notifications.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final notification = state.notifications[index];
                  return _NotificationItem(
                    notification: notification,
                    token: token ?? '',
                  );
                },
              ),
            );
          }

          return const Center(child: Text('Không có dữ liệu'));
        },
      ),
    );
  }

  void _showDeleteAllDialog(BuildContext context, String token) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa tất cả thông báo?'),
        content: const Text('Bạn có chắc muốn xóa tất cả thông báo không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<NotificationBloc>().add(
                NotificationDeleteAll(token),
              );
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final AppNotification notification;
  final String token;

  const _NotificationItem({required this.notification, required this.token});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Xóa thông báo?'),
            content: const Text('Bạn có chắc muốn xóa thông báo này?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Xóa', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        context.read<NotificationBloc>().add(
          NotificationDelete(token, notification.id),
        );
      },
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: notification.isRead
              ? Colors.grey[300]
              : Colors.blue[100],
          child: Text(notification.icon, style: const TextStyle(fontSize: 24)),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead
                ? FontWeight.normal
                : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(notification.body),
            const SizedBox(height: 4),
            Text(
              timeago.format(notification.createdAt, locale: 'vi'),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: !notification.isRead
            ? const Icon(Icons.circle, size: 12, color: Colors.blue)
            : null,
        onTap: () {
          if (!notification.isRead) {
            context.read<NotificationBloc>().add(
              NotificationMarkAsRead(token, notification.id),
            );
          }
          // TODO: Navigate based on notification type and data
          _handleNotificationTap(context, notification);
        },
      ),
    );
  }

  void _handleNotificationTap(
    BuildContext context,
    AppNotification notification,
  ) {
    // Handle navigation based on notification type
    // TODO: Implement navigation logic
    print('Tapped notification: ${notification.type} - ${notification.data}');
  }
}
