import 'package:equatable/equatable.dart';

class AppNotification extends Equatable {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    required this.isRead,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    userId,
    type,
    title,
    body,
    data,
    isRead,
    createdAt,
  ];

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      data: json['data'] != null
          ? Map<String, dynamic>.from(json['data'])
          : null,
      isRead: json['is_read'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'title': title,
      'body': body,
      'data': data,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  AppNotification copyWith({
    String? id,
    String? userId,
    String? type,
    String? title,
    String? body,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Helper để hiển thị icon theo type
  String get icon {
    switch (type) {
      case 'group_invite':
        return '👥';
      case 'group_join':
        return '✅';
      case 'group_expense':
        return '💸';
      case 'group_settle':
        return '💰';
      case 'group_expense_update':
        return '✏️';
      case 'group_expense_delete':
        return '🗑️';
      case 'savings_goal_reached':
        return '🎯';
      case 'savings_milestone':
        return '📈';
      case 'low_balance_alert':
        return '⚠️';
      case 'new_device_login':
        return '🔐';
      case 'maintenance':
        return '🔧';
      case 'debt_reminder':
        return '⏰';
      case 'savings_reminder':
        return '🐷';
      default:
        return '🔔';
    }
  }
}

class NotificationSettings extends Equatable {
  final String userId;
  final bool groupInvite;
  final bool groupJoin;
  final bool groupExpense;
  final bool groupSettle;
  final bool groupExpenseUpdate;
  final bool groupExpenseDelete;
  final bool savingsGoalReached;
  final bool savingsMilestone;
  final bool lowBalanceAlert;
  final bool newDeviceLogin;
  final bool maintenance;
  final bool debtReminder;
  final bool savingsReminder;

  const NotificationSettings({
    required this.userId,
    this.groupInvite = true,
    this.groupJoin = true,
    this.groupExpense = true,
    this.groupSettle = true,
    this.groupExpenseUpdate = true,
    this.groupExpenseDelete = true,
    this.savingsGoalReached = true,
    this.savingsMilestone = true,
    this.lowBalanceAlert = true,
    this.newDeviceLogin = true,
    this.maintenance = true,
    this.debtReminder = true,
    this.savingsReminder = true,
  });

  @override
  List<Object?> get props => [
    userId,
    groupInvite,
    groupJoin,
    groupExpense,
    groupSettle,
    groupExpenseUpdate,
    groupExpenseDelete,
    savingsGoalReached,
    savingsMilestone,
    lowBalanceAlert,
    newDeviceLogin,
    maintenance,
    debtReminder,
    savingsReminder,
  ];

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      userId: json['user_id'] ?? '',
      groupInvite: json['group_invite'] ?? true,
      groupJoin: json['group_join'] ?? true,
      groupExpense: json['group_expense'] ?? true,
      groupSettle: json['group_settle'] ?? true,
      groupExpenseUpdate: json['group_expense_update'] ?? true,
      groupExpenseDelete: json['group_expense_delete'] ?? true,
      savingsGoalReached: json['savings_goal_reached'] ?? true,
      savingsMilestone: json['savings_milestone'] ?? true,
      lowBalanceAlert: json['low_balance_alert'] ?? true,
      newDeviceLogin: json['new_device_login'] ?? true,
      maintenance: json['maintenance'] ?? true,
      debtReminder: json['debt_reminder'] ?? true,
      savingsReminder: json['savings_reminder'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'group_invite': groupInvite,
      'group_join': groupJoin,
      'group_expense': groupExpense,
      'group_settle': groupSettle,
      'group_expense_update': groupExpenseUpdate,
      'group_expense_delete': groupExpenseDelete,
      'savings_goal_reached': savingsGoalReached,
      'savings_milestone': savingsMilestone,
      'low_balance_alert': lowBalanceAlert,
      'new_device_login': newDeviceLogin,
      'maintenance': maintenance,
      'debt_reminder': debtReminder,
      'savings_reminder': savingsReminder,
    };
  }

  NotificationSettings copyWith({
    String? userId,
    bool? groupInvite,
    bool? groupJoin,
    bool? groupExpense,
    bool? groupSettle,
    bool? groupExpenseUpdate,
    bool? groupExpenseDelete,
    bool? savingsGoalReached,
    bool? savingsMilestone,
    bool? lowBalanceAlert,
    bool? newDeviceLogin,
    bool? maintenance,
    bool? debtReminder,
    bool? savingsReminder,
  }) {
    return NotificationSettings(
      userId: userId ?? this.userId,
      groupInvite: groupInvite ?? this.groupInvite,
      groupJoin: groupJoin ?? this.groupJoin,
      groupExpense: groupExpense ?? this.groupExpense,
      groupSettle: groupSettle ?? this.groupSettle,
      groupExpenseUpdate: groupExpenseUpdate ?? this.groupExpenseUpdate,
      groupExpenseDelete: groupExpenseDelete ?? this.groupExpenseDelete,
      savingsGoalReached: savingsGoalReached ?? this.savingsGoalReached,
      savingsMilestone: savingsMilestone ?? this.savingsMilestone,
      lowBalanceAlert: lowBalanceAlert ?? this.lowBalanceAlert,
      newDeviceLogin: newDeviceLogin ?? this.newDeviceLogin,
      maintenance: maintenance ?? this.maintenance,
      debtReminder: debtReminder ?? this.debtReminder,
      savingsReminder: savingsReminder ?? this.savingsReminder,
    );
  }
}
