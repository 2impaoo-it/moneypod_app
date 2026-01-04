import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneypod/screens/splash_screen.dart';

void main() {
  testWidgets('SplashScreen builds', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));
    expect(find.byType(SplashScreen), findsOneWidget);
    // SplashScreen might navigate away or show logo.
    // Check for logo or app name if present.
    expect(find.byType(Image), findsOneWidget); // Assuming logo
  });
}
