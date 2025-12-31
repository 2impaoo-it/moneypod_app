import 'package:equatable/equatable.dart';
import 'dart:convert';

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
    // Parse data field - có thể là String (JSON string) hoặc Map
    Map<String, dynamic>? parsedData;
    if (json['data'] != null) {
      if (json['data'] is String) {
        // Nếu là String thì parse JSON
        try {
          parsedData = jsonDecode(json['data']) as Map<String, dynamic>;
        } catch (e) {
          parsedData = null;
        }
      } else if (json['data'] is Map) {
        // Nếu đã là Map thì dùng luôn
        parsedData = Map<String, dynamic>.from(json['data']);
      }
    }

    return AppNotification(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      data: parsedData,
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
      // Group notifications
      case 'group_expense':
        return '💸';
      case 'group_member_added':
        return '➕';
      case 'group_member_removed':
        return '➖';
      case 'group_deleted':
        return '🗑️';
      case 'expense_updated':
        return '✏️';
      case 'expense_deleted':
        return '🗑️';
      // Transaction notifications
      case 'transaction_created':
        return '💰';
      case 'low_balance':
        return '⚠️';
      case 'budget_exceeded':
        return '📊';
      case 'daily_summary':
        return '📋';
      // Savings notifications
      case 'savings_goal_reached':
        return '🎯';
      case 'savings_reminder':
        return '🐷';
      case 'savings_progress':
        return '📈';
      // System notifications
      case 'system_announcement':
        return '📢';
      case 'security_alert':
        return '🔐';
      case 'app_update':
        return '🔄';
      case 'maintenance':
        return '🔧';
      default:
        return '🔔';
    }
  }
}

class NotificationSettings extends Equatable {
  final String userId;

  // Group notifications
  final bool groupExpense;
  final bool groupMemberAdded;
  final bool groupMemberRemoved;
  final bool groupDeleted;
  final bool expenseUpdated;
  final bool expenseDeleted;

  // Transaction notifications
  final bool transactionCreated;
  final bool lowBalance;
  final bool budgetExceeded;
  final bool dailySummary;

  // Savings notifications
  final bool savingsGoalReached;
  final bool savingsReminder;
  final bool savingsProgress;

  // System notifications
  final bool systemAnnouncement;
  final bool securityAlert;
  final bool appUpdate;
  final bool maintenance;

  const NotificationSettings({
    required this.userId,
    // Group notifications
    this.groupExpense = true,
    this.groupMemberAdded = true,
    this.groupMemberRemoved = true,
    this.groupDeleted = true,
    this.expenseUpdated = true,
    this.expenseDeleted = true,
    // Transaction notifications
    this.transactionCreated = true,
    this.lowBalance = true,
    this.budgetExceeded = true,
    this.dailySummary = false,
    // Savings notifications
    this.savingsGoalReached = true,
    this.savingsReminder = true,
    this.savingsProgress = true,
    // System notifications
    this.systemAnnouncement = true,
    this.securityAlert = true,
    this.appUpdate = true,
    this.maintenance = true,
  });

  @override
  List<Object?> get props => [
    userId,
    groupExpense,
    groupMemberAdded,
    groupMemberRemoved,
    groupDeleted,
    expenseUpdated,
    expenseDeleted,
    transactionCreated,
    lowBalance,
    budgetExceeded,
    dailySummary,
    savingsGoalReached,
    savingsReminder,
    savingsProgress,
    systemAnnouncement,
    securityAlert,
    appUpdate,
    maintenance,
  ];

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      userId: json['user_id'] ?? '',
      // Group notifications
      groupExpense: json['group_expense'] ?? true,
      groupMemberAdded: json['group_member_added'] ?? true,
      groupMemberRemoved: json['group_member_removed'] ?? true,
      groupDeleted: json['group_deleted'] ?? true,
      expenseUpdated: json['expense_updated'] ?? true,
      expenseDeleted: json['expense_deleted'] ?? true,
      // Transaction notifications
      transactionCreated: json['transaction_created'] ?? true,
      lowBalance: json['low_balance'] ?? true,
      budgetExceeded: json['budget_exceeded'] ?? true,
      dailySummary: json['daily_summary'] ?? false,
      // Savings notifications
      savingsGoalReached: json['savings_goal_reached'] ?? true,
      savingsReminder: json['savings_reminder'] ?? true,
      savingsProgress: json['savings_progress'] ?? true,
      // System notifications
      systemAnnouncement: json['system_announcement'] ?? true,
      securityAlert: json['security_alert'] ?? true,
      appUpdate: json['app_update'] ?? true,
      maintenance: json['maintenance'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      // Group notifications
      'group_expense': groupExpense,
      'group_member_added': groupMemberAdded,
      'group_member_removed': groupMemberRemoved,
      'group_deleted': groupDeleted,
      'expense_updated': expenseUpdated,
      'expense_deleted': expenseDeleted,
      // Transaction notifications
      'transaction_created': transactionCreated,
      'low_balance': lowBalance,
      'budget_exceeded': budgetExceeded,
      'daily_summary': dailySummary,
      // Savings notifications
      'savings_goal_reached': savingsGoalReached,
      'savings_reminder': savingsReminder,
      'savings_progress': savingsProgress,
      // System notifications
      'system_announcement': systemAnnouncement,
      'security_alert': securityAlert,
      'app_update': appUpdate,
      'maintenance': maintenance,
    };
  }

  NotificationSettings copyWith({
    String? userId,
    // Group notifications
    bool? groupExpense,
    bool? groupMemberAdded,
    bool? groupMemberRemoved,
    bool? groupDeleted,
    bool? expenseUpdated,
    bool? expenseDeleted,
    // Transaction notifications
    bool? transactionCreated,
    bool? lowBalance,
    bool? budgetExceeded,
    bool? dailySummary,
    // Savings notifications
    bool? savingsGoalReached,
    bool? savingsReminder,
    bool? savingsProgress,
    // System notifications
    bool? systemAnnouncement,
    bool? securityAlert,
    bool? appUpdate,
    bool? maintenance,
  }) {
    return NotificationSettings(
      userId: userId ?? this.userId,
      // Group notifications
      groupExpense: groupExpense ?? this.groupExpense,
      groupMemberAdded: groupMemberAdded ?? this.groupMemberAdded,
      groupMemberRemoved: groupMemberRemoved ?? this.groupMemberRemoved,
      groupDeleted: groupDeleted ?? this.groupDeleted,
      expenseUpdated: expenseUpdated ?? this.expenseUpdated,
      expenseDeleted: expenseDeleted ?? this.expenseDeleted,
      // Transaction notifications
      transactionCreated: transactionCreated ?? this.transactionCreated,
      lowBalance: lowBalance ?? this.lowBalance,
      budgetExceeded: budgetExceeded ?? this.budgetExceeded,
      dailySummary: dailySummary ?? this.dailySummary,
      // Savings notifications
      savingsGoalReached: savingsGoalReached ?? this.savingsGoalReached,
      savingsReminder: savingsReminder ?? this.savingsReminder,
      savingsProgress: savingsProgress ?? this.savingsProgress,
      // System notifications
      systemAnnouncement: systemAnnouncement ?? this.systemAnnouncement,
      securityAlert: securityAlert ?? this.securityAlert,
      appUpdate: appUpdate ?? this.appUpdate,
      maintenance: maintenance ?? this.maintenance,
    );
  }
}
