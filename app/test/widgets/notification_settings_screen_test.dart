import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneypod/screens/notification_settings_screen.dart';

void main() {
  testWidgets('NotificationSettingsScreen builds', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: NotificationSettingsScreen()),
    );
    expect(find.byType(NotificationSettingsScreen), findsOneWidget);
    expect(find.text('Cài đặt thông báo'), findsOneWidget); // Title check
  });
}
