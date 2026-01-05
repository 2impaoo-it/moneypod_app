import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moneypod/services/insight_service.dart';
import 'package:moneypod/widgets/insight_widget.dart';

class MockInsightService extends Mock implements InsightService {}

void main() {
  late MockInsightService mockInsightService;

  setUp(() {
    mockInsightService = MockInsightService();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: Scaffold(body: InsightWidget(insightService: mockInsightService)),
    );
  }

  testWidgets('renders loading state then loaded', (tester) async {
    // Arrange
    final completer = Completer<String>();
    when(
      () => mockInsightService.getMonthlyInsight(),
    ).thenAnswer((_) => completer.future);

    // Act
    await tester.pumpWidget(createWidgetUnderTest());

    // Assert Loading
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Insight thông minh'), findsOneWidget);

    // Complete Future
    completer.complete('Spending analysis content');
    await tester.pumpAndSettle();

    // Assert Loaded
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Spending analysis content'), findsOneWidget);
  });

  testWidgets('renders error message when service fails', (tester) async {
    // Arrange
    when(
      () => mockInsightService.getMonthlyInsight(),
    ).thenThrow(Exception('Network error'));

    // Act
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Assert
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Không thể tải insight lúc này.'), findsOneWidget);
  });
}
