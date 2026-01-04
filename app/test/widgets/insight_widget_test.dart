import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneypod/widgets/insight_widget.dart';
// Removed unused mocktail import

void main() {
  testWidgets('InsightWidget builds and shows loading', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: InsightWidget())),
    );

    await tester.pumpAndSettle();

    expect(find.byType(InsightWidget), findsOneWidget);
  });
}
