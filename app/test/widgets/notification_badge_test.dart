import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneypod/widgets/notification_badge.dart';

void main() {
  testWidgets('NotificationBadge shows count', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: NotificationBadge(count: 5, child: Icon(Icons.notifications)),
        ),
      ),
    );

    expect(find.text('5'), findsOneWidget);
    expect(find.byType(Icon), findsOneWidget);
  });

  testWidgets('NotificationBadge hides when count is 0', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: NotificationBadge(count: 0, child: Icon(Icons.notifications)),
        ),
      ),
    );

    expect(
      find.byType(Container),
      findsNothing,
    ); // Badge container is conditional
    expect(find.byType(Icon), findsOneWidget);
  });
}
