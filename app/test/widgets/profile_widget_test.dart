import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneypod/widgets/profile_widget.dart';

// ProfileWidget has hard dependency on AuthService and ProfileService.
// Similar to InsightWidget, we test basic build.
// Real auth service won't find token, so it should load ProfileScreen with empty token.

void main() {
  testWidgets('ProfileWidget builds', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ProfileWidget())),
    );

    await tester.pumpAndSettle();
    expect(find.byType(ProfileWidget), findsOneWidget);
  });
}
