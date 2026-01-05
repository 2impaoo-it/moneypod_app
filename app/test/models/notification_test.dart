import 'package:flutter_test/flutter_test.dart';
import 'package:moneypod/models/notification.dart';

void main() {
  group('AppNotification Model', () {
    final now = DateTime.now();

    group('fromJson', () {
      test('parses complete JSON correctly', () {
        final json = {
          'id': '123',
          'user_id': 'user1',
          'type': 'group_expense',
          'title': 'New Expense',
          'body': 'John added an expense',
          'data': {'amount': 50000},
          'is_read': false,
          'created_at': now.toIso8601String(),
        };

        final notification = AppNotification.fromJson(json);

        expect(notification.id, '123');
        expect(notification.userId, 'user1');
        expect(notification.type, 'group_expense');
        expect(notification.title, 'New Expense');
        expect(notification.body, 'John added an expense');
        expect(notification.data?['amount'], 50000);
        expect(notification.isRead, false);
      });

      test('handles data as JSON string', () {
        final json = {
          'id': '1',
          'user_id': 'user1',
          'type': 'test',
          'title': 'Test',
          'body': 'Body',
          'data': '{"key": "value"}',
          'is_read': true,
          'created_at': now.toIso8601String(),
        };

        final notification = AppNotification.fromJson(json);
        expect(notification.data?['key'], 'value');
      });

      test('handles invalid JSON string in data', () {
        final json = {
          'id': '1',
          'user_id': 'user1',
          'type': 'test',
          'title': 'Test',
          'body': 'Body',
          'data': 'invalid json',
          'is_read': true,
          'created_at': now.toIso8601String(),
        };

        final notification = AppNotification.fromJson(json);
        expect(notification.data, isNull);
      });

      test('handles null data', () {
        final json = {
          'id': '1',
          'user_id': 'user1',
          'type': 'test',
          'title': 'Test',
          'body': 'Body',
          'data': null,
          'is_read': false,
          'created_at': now.toIso8601String(),
        };

        final notification = AppNotification.fromJson(json);
        expect(notification.data, isNull);
      });

      test('handles missing fields with defaults', () {
        final json = <String, dynamic>{};

        final notification = AppNotification.fromJson(json);

        expect(notification.id, '');
        expect(notification.userId, '');
        expect(notification.type, '');
        expect(notification.title, '');
        expect(notification.body, '');
        expect(notification.isRead, false);
      });
    });

    group('toJson', () {
      test('serializes all fields correctly', () {
        final notification = AppNotification(
          id: '123',
          userId: 'user1',
          type: 'budget_exceeded',
          title: 'Budget Alert',
          body: 'You exceeded your budget',
          data: {'category': 'Food'},
          isRead: true,
          createdAt: now,
        );

        final json = notification.toJson();

        expect(json['id'], '123');
        expect(json['user_id'], 'user1');
        expect(json['type'], 'budget_exceeded');
        expect(json['title'], 'Budget Alert');
        expect(json['body'], 'You exceeded your budget');
        expect(json['data']['category'], 'Food');
        expect(json['is_read'], true);
        expect(json['created_at'], now.toIso8601String());
      });
    });

    group('copyWith', () {
      test('copies all fields when provided', () {
        final original = AppNotification(
          id: '1',
          userId: 'user1',
          type: 'old_type',
          title: 'Old',
          body: 'Old body',
          isRead: false,
          createdAt: now,
        );

        final copied = original.copyWith(
          type: 'new_type',
          title: 'New',
          isRead: true,
        );

        expect(copied.id, '1'); // unchanged
        expect(copied.type, 'new_type');
        expect(copied.title, 'New');
        expect(copied.isRead, true);
      });
    });

    group('icon getter', () {
      test('returns correct icons for different types', () {
        final testCases = {
          'group_expense': '💸',
          'group_member_added': '➕',
          'group_member_removed': '➖',
          'group_deleted': '🗑️',
          'expense_updated': '✏️',
          'expense_deleted': '🗑️',
          'transaction_created': '💰',
          'low_balance': '⚠️',
          'budget_exceeded': '📊',
          'daily_summary': '📋',
          'savings_goal_reached': '🎯',
          'savings_reminder': '🐷',
          'savings_progress': '📈',
          'system_announcement': '📢',
          'security_alert': '🔐',
          'app_update': '🔄',
          'maintenance': '🔧',
          'unknown_type': '🔔', // default
        };

        testCases.forEach((type, expectedIcon) {
          final notification = AppNotification(
            id: '1',
            userId: 'user1',
            type: type,
            title: 'T',
            body: 'B',
            isRead: false,
            createdAt: now,
          );
          expect(notification.icon, expectedIcon, reason: 'Type: $type');
        });
      });
    });

    group('Equatable', () {
      test('two notifications with same props are equal', () {
        final n1 = AppNotification(
          id: '1',
          userId: 'u1',
          type: 't',
          title: 'T',
          body: 'B',
          isRead: false,
          createdAt: now,
        );
        final n2 = AppNotification(
          id: '1',
          userId: 'u1',
          type: 't',
          title: 'T',
          body: 'B',
          isRead: false,
          createdAt: now,
        );

        expect(n1, equals(n2));
      });
    });
  });

  group('NotificationSettings Model', () {
    group('fromJson', () {
      test('parses complete JSON correctly', () {
        final json = {
          'user_id': 'user123',
          'group_expense': false,
          'group_member_added': true,
          'low_balance': true,
          'daily_summary': true,
        };

        final settings = NotificationSettings.fromJson(json);

        expect(settings.userId, 'user123');
        expect(settings.groupExpense, false);
        expect(settings.groupMemberAdded, true);
        expect(settings.lowBalance, true);
        expect(settings.dailySummary, true); // overridden from default false
      });

      test('uses default values for missing fields', () {
        final json = {'user_id': 'user1'};

        final settings = NotificationSettings.fromJson(json);

        expect(settings.groupExpense, true); // default
        expect(settings.dailySummary, false); // default false
        expect(settings.systemAnnouncement, true); // default
      });
    });

    group('toJson', () {
      test('serializes all fields correctly', () {
        const settings = NotificationSettings(
          userId: 'user123',
          groupExpense: false,
          dailySummary: true,
        );

        final json = settings.toJson();

        expect(json['user_id'], 'user123');
        expect(json['group_expense'], false);
        expect(json['daily_summary'], true);
        expect(json['low_balance'], true); // default
      });
    });

    group('copyWith', () {
      test('copies fields when provided', () {
        const original = NotificationSettings(
          userId: 'user1',
          groupExpense: true,
          dailySummary: false,
        );

        final copied = original.copyWith(
          groupExpense: false,
          dailySummary: true,
        );

        expect(copied.userId, 'user1');
        expect(copied.groupExpense, false);
        expect(copied.dailySummary, true);
      });
    });

    group('Equatable', () {
      test('two settings with same props are equal', () {
        const s1 = NotificationSettings(userId: 'u1');
        const s2 = NotificationSettings(userId: 'u1');

        expect(s1, equals(s2));
      });

      test('props contains all 18 fields', () {
        const settings = NotificationSettings(userId: 'u1');
        expect(settings.props, hasLength(18));
      });
    });
  });
}
