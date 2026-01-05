import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneypod/widgets/notification_badge.dart';

void main() {
  group('NotificationBadge', () {
    testWidgets('shows count when greater than 0', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NotificationBadge(count: 5, child: Icon(Icons.notifications)),
          ),
        ),
      );

      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('hides count when 0', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NotificationBadge(count: 0, child: Icon(Icons.notifications)),
          ),
        ),
      );

      expect(find.text('0'), findsNothing);
    });

    testWidgets('shows 99+ when count is large', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NotificationBadge(
              count: 100,
              child: Icon(Icons.notifications),
            ),
          ),
        ),
      );

      expect(find.text('99+'), findsOneWidget);
    });

    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NotificationBadge(count: 0, child: Icon(Icons.notifications)),
          ),
        ),
      );

      expect(find.byIcon(Icons.notifications), findsOneWidget);
    });
  });
}
