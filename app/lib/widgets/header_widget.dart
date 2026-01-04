import 'package:moneypod/main.dart';
import 'package:moneypod/models/profile.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/notification/notification_bloc.dart';
import '../bloc/notification/notification_event.dart';
import '../bloc/notification/notification_state.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_state.dart';
import 'notification_badge.dart';

class HeaderWidget extends StatefulWidget {
  const HeaderWidget({super.key, required this.profile});
  final Profile profile;

  @override
  State<HeaderWidget> createState() => _HeaderWidgetState();
}

class _HeaderWidgetState extends State<HeaderWidget> {
  bool _hasLoadedUnreadCount = false;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = widget.profile.avatarUrl;
    final initials = (widget.profile.fullName ?? '')
        .trim()
        .split(' ')
        .where((s) => s.isNotEmpty)
        .map((s) => s[0])
        .join()
        .toUpperCase();

    return GestureDetector(
      onTap: () {
        debugPrint('Avatar tapped - navigating to /profile');
        try {
          // Sử dụng push thay vì go để giữ lại lịch sử navigation,
          // cho phép user back về màn hình trước đó (Dashboard)
          context.push('/profile');
        } catch (e) {
          debugPrint('Navigation error: $e');
        }
      },
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                ? NetworkImage(avatarUrl)
                : null,
            child: (avatarUrl == null || avatarUrl.isEmpty)
                ? Text(
                    initials.isEmpty ? '?' : initials,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Xin chào,",
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              Text(
                widget.profile.fullName ?? 'Người dùng',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Spacer(),
          BlocBuilder<NotificationBloc, NotificationState>(
            builder: (context, state) {
              int unreadCount = 0;
              if (state is NotificationLoaded) {
                unreadCount = state.unreadCount;
              }

              // Load unread count only once when widget builds for the first time
              if (!_hasLoadedUnreadCount && state is! NotificationLoaded) {
                final authState = context.read<AuthBloc>().state;
                if (authState is AuthAuthenticated &&
                    authState.user.token != null) {
                  // Schedule the event to be added after build completes
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && !_hasLoadedUnreadCount) {
                      context.read<NotificationBloc>().add(
                        NotificationLoadUnreadCount(authState.user.token!),
                      );
                      _hasLoadedUnreadCount = true;
                    }
                  });
                }
              }

              return IconButton(
                onPressed: () {
                  context.push('/notifications');
                },
                icon: NotificationBadge(
                  count: unreadCount,
                  child: const Icon(
                    LucideIcons.bell,
                    color: AppColors.textPrimary,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
