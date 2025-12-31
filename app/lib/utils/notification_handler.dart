import 'package:flutter/material.dart';
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
    final walletId = data['wallet_id'];
    if (walletId != null) {
      // Navigate to wallet detail or wallet list
      Navigator.pushNamed(context, '/wallets');
    } else {
      // If no wallet_id, just go to wallet list
      Navigator.pushNamed(context, '/wallets');
    }
  }

  static void _handleTransaction(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    final transactionId = data['transaction_id'];
    if (transactionId != null) {
      // Navigate to transaction detail if screen exists
      // For now, just go to transaction list
      Navigator.pushNamed(context, '/transactions');
    } else {
      Navigator.pushNamed(context, '/transactions');
    }
  }

  static void _handleGroupExpense(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    final groupId = data['group_id'];
    if (groupId != null) {
      // Navigate to group detail
      Navigator.pushNamed(context, '/group-detail', arguments: groupId);
    } else {
      // If no group_id, go to groups list
      Navigator.pushNamed(context, '/groups');
    }
  }

  static void _handleSavings(BuildContext context, Map<String, dynamic> data) {
    final savingsId = data['savings_id'];
    if (savingsId != null) {
      // Navigate to savings detail
      Navigator.pushNamed(context, '/savings-detail', arguments: savingsId);
    } else {
      // If no savings_id, go to savings list
      Navigator.pushNamed(context, '/savings');
    }
  }

  static void _handleBudget(BuildContext context, Map<String, dynamic> data) {
    final budgetId = data['budget_id'];
    if (budgetId != null) {
      // Navigate to budget detail if screen exists
      Navigator.pushNamed(context, '/budgets');
    } else {
      Navigator.pushNamed(context, '/budgets');
    }
  }

  static void _handleDailySummary(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    // Navigate to transaction list or dashboard
    Navigator.pushNamed(context, '/transactions');
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

    // Navigate based on type
    switch (type) {
      case 'low_balance':
        Navigator.pushNamed(context, '/wallets');
        break;
      case 'transaction_created':
      case 'expense_updated':
      case 'expense_deleted':
        Navigator.pushNamed(context, '/transactions');
        break;
      case 'group_expense':
      case 'group_member_added':
      case 'group_member_removed':
      case 'group_deleted':
        final groupId = data['group_id'];
        if (groupId != null) {
          Navigator.pushNamed(context, '/group-detail', arguments: groupId);
        } else {
          Navigator.pushNamed(context, '/groups');
        }
        break;
      case 'savings_goal_reached':
      case 'savings_progress':
      case 'savings_reminder':
        final savingsId = data['savings_id'];
        if (savingsId != null) {
          Navigator.pushNamed(context, '/savings-detail', arguments: savingsId);
        } else {
          Navigator.pushNamed(context, '/savings');
        }
        break;
      default:
        debugPrint('Unknown FCM notification type: $type');
        break;
    }
  }
}
