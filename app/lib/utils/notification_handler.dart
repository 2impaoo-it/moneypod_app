import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/notification.dart';

class NotificationHandler {
  /// Handle navigation when user taps on a notification
  static void handleNotificationTap(
    BuildContext context,
    AppNotification notification,
  ) {
    if (!context.mounted) return;

    final data = notification.data;
    if (data == null) return;

    // Mark as read (you can add BLoC event here)
    // context.read<NotificationBloc>().add(MarkAsRead(notification.id));

    switch (notification.type) {
      case 'low_balance':
        _handleLowBalance(context, data);
        break;
      case 'transaction_created':
      case 'expense_updated':
      case 'expense_deleted':
        _handleTransaction(context, data);
        break;
      case 'debt_reminder':
        _handleDebtReminder(context, data);
        break;
      case 'group_expense':
      case 'group_member_added':
      case 'group_member_removed':
      case 'group_deleted':
        _handleGroupExpense(context, data);
        break;
      case 'savings_goal_reached':
      case 'savings_progress':
      case 'savings_reminder':
        _handleSavings(context, data);
        break;
      case 'budget_exceeded':
        _handleBudget(context, data);
        break;
      case 'daily_summary':
        _handleDailySummary(context, data);
        break;
      case 'maintenance':
      case 'system_announcement':
      case 'security_alert':
      case 'app_update':
        // System notifications - just show info or do nothing
        _handleSystemNotification(context, notification);
        break;
      default:
        debugPrint('Unknown notification type: ${notification.type}');
        break;
    }
  }

  static void _handleLowBalance(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    // Navigate to wallet list
    context.push('/wallet-list');
  }

  static void _handleTransaction(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    // Navigate to transaction list
    context.go('/transactions');
  }

  static void _handleDebtReminder(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    // Navigate to debt payment screen
    final debtId = data['debt_id']?.toString();
    final creditorName = data['creditor_name']?.toString() ?? 'Unknown';
    final creditorAvatar = data['creditor_avatar']?.toString() ?? '';
    final amount = (data['amount'] as num?)?.toInt() ?? 0;
    final description = data['description']?.toString() ?? 'Chi phí nhóm';
    final groupName = data['group_name']?.toString() ?? 'Nhóm';

    if (debtId != null && debtId.isNotEmpty) {
      // Use GoRouter push for consistency
      context.push(
        '/full-screen/debt/pay',
        extra: {
          'debtId': debtId,
          'creditorName': creditorName,
          'creditorAvatar': creditorAvatar,
          'amount': amount,
          'description': description,
          'groupName': groupName,
        },
      );
    } else {
      // Fallback to groups screen
      context.go('/groups');
    }
  }

  static void _handleGroupExpense(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    final groupId = data['group_id'];
    if (groupId != null) {
      // Navigate to group detail (ShellRoute -> use go)
      context.go('/groups/$groupId');
    } else {
      // If no group_id, go to groups list
      context.go('/groups');
    }
  }

  static void _handleSavings(BuildContext context, Map<String, dynamic> data) {
    final savingsId = data['savings_id'];
    if (savingsId != null) {
      // Navigate to savings detail (ShellRoute -> use go)
      context.go('/savings/$savingsId');
    } else {
      // If no savings_id, go to dashboard (savings tab)
      context.go('/savings'); // Changed to go to savings tab
    }
  }

  static void _handleBudget(BuildContext context, Map<String, dynamic> data) {
    // Navigate to dashboard or budget screen
    context.go('/');
  }

  static void _handleDailySummary(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    // Navigate to transaction list
    context.go('/transactions');
  }

  static void _handleSystemNotification(
    BuildContext context,
    AppNotification notification,
  ) {
    // For system notifications, show a dialog with the message
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getSystemNotificationIcon(notification.type),
              color: _getSystemNotificationColor(notification.type),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(notification.title)),
          ],
        ),
        content: Text(notification.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  static IconData _getSystemNotificationIcon(String type) {
    switch (type) {
      case 'maintenance':
        return Icons.construction;
      case 'security_alert':
        return Icons.security;
      case 'app_update':
        return Icons.system_update;
      default:
        return Icons.info_outline;
    }
  }

  static Color _getSystemNotificationColor(String type) {
    switch (type) {
      case 'maintenance':
        return Colors.orange;
      case 'security_alert':
        return Colors.red;
      case 'app_update':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  /// Handle notification from FCM (push notification)
  static void handleFCMNotificationTap(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    if (!context.mounted) return;

    final type = data['type'];
    if (type == null) return;

    // Navigate based on type using GoRouter
    switch (type) {
      case 'low_balance':
        context.push('/wallet-list');
        break;
      case 'transaction_created':
      case 'expense_updated':
      case 'expense_deleted':
        context.go('/transactions');
        break;
      case 'debt_reminder':
      case 'group_expense':
      case 'group_member_added':
      case 'group_member_removed':
      case 'group_deleted':
        final groupId = data['group_id'];
        if (groupId != null) {
          context.go('/groups/$groupId');
        } else {
          context.go('/groups');
        }
        break;
      case 'savings_goal_reached':
      case 'savings_progress':
      case 'savings_reminder':
        final savingsId = data['savings_id'];
        if (savingsId != null) {
          context.go('/savings/$savingsId');
        } else {
          context.go('/savings');
        }
        break;
      default:
        debugPrint('Unknown FCM notification type: $type');
        break;
    }
  }
}
