import 'package:flutter_test/flutter_test.dart';
import 'package:moneypod/models/notification.dart';

void main() {
  group('Notification Model Test', () {
    test('supports value equality', () {
      final date = DateTime.now();
      final notif1 = AppNotification(
        id: '1',
        userId: 'u1',
        type: 'info',
        title: 'Title',
        body: 'Body',
        isRead: false,
        createdAt: date,
      );
      final notif2 = AppNotification(
        id: '1',
        userId: 'u1',
        type: 'info',
        title: 'Title',
        body: 'Body',
        isRead: false,
        createdAt: date,
      );

      expect(notif1, equals(notif2));
    });

    test('fromJson parses correctly with String data', () {
      final json = {
        'id': '1',
        'user_id': 'u1',
        'type': 'group_expense',
        'title': 'New Expense',
        'body': 'User A added expense',
        'data': '{"group_id": "g1"}', // JSON String
        'is_read': true,
        'created_at': '2023-10-27T10:00:00Z',
      };

      final notif = AppNotification.fromJson(json);

      expect(notif.id, '1');
      expect(notif.data?['group_id'], 'g1');
      expect(notif.isRead, true);
    });

    test('fromJson parses correctly with Map data', () {
      final json = {
        'id': '1',
        'user_id': 'u1',
        'type': 'info',
        'title': 'Info',
        'body': 'Body',
        'data': {'key': 'value'}, // Map object
        'is_read': false,
      };

      final notif = AppNotification.fromJson(json);

      expect(notif.data?['key'], 'value');
    });

    test('icon getter returns correct emoji', () {
      final notif = AppNotification(
        id: '1',
        userId: 'u1',
        type: 'group_expense',
        title: 'Title',
        body: 'Body',
        isRead: false,
        createdAt: DateTime.now(),
      );

      expect(notif.icon, '💸');

      final unknown = notif.copyWith(type: 'unknown_type');
      expect(unknown.icon, '🔔');
    });
  });

  group('NotificationSettings Model Test', () {
    test('fromJson parses correctly', () {
      final json = {'user_id': 'u1', 'group_expense': false};

      final settings = NotificationSettings.fromJson(json);

      expect(settings.userId, 'u1');
      expect(settings.groupExpense, false);
      expect(settings.groupMemberAdded, true); // Default value
    });

    test('toJson returns correct map', () {
      final settings = NotificationSettings(userId: 'u1', groupExpense: false);
      final json = settings.toJson();
      expect(json['user_id'], 'u1');
      expect(json['group_expense'], false);
    });
  });
}
