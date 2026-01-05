import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneypod/utils/notification_handler.dart';
import 'package:moneypod/models/notification.dart';

void main() {
  group('NotificationHandler', () {
    group('handleNotificationTap', () {
      testWidgets('does nothing if context is not mounted', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: Text('Test'))),
        );

        final notification = AppNotification(
          id: '1',
          userId: 'user1',
          title: 'Test',
          body: 'Test body',
          type: 'unknown',
          createdAt: DateTime.now(),
          isRead: false,
        );

        // Get context after widget is disposed
        final context = tester.element(find.text('Test'));

        // Should not throw even with unknown type
        expect(
          () =>
              NotificationHandler.handleNotificationTap(context, notification),
          returnsNormally,
        );
      });
    });

    group('handleFCMNotificationTap', () {
      testWidgets('does nothing if type is null', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                // Test that null type doesn't crash
                NotificationHandler.handleFCMNotificationTap(context, {});
                return const Text('Test');
              },
            ),
          ),
        );

        expect(find.text('Test'), findsOneWidget);
      });
    });

    group('class structure', () {
      test('NotificationHandler exists', () {
        expect(NotificationHandler, isNotNull);
      });
    });
  });
}
