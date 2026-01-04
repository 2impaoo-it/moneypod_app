import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moneypod/screens/create_savings_goal_screen.dart';
import 'package:moneypod/repositories/savings_repository.dart';

class MockSavingsRepository extends Mock implements SavingsRepository {}

void main() {
  testWidgets('CreateSavingsGoalScreen builds', (WidgetTester tester) async {
    // Skipped due to environment issues
    final mockRepo = MockSavingsRepository();

    await tester.pumpWidget(
      MaterialApp(home: CreateSavingsGoalScreen(savingsRepository: mockRepo)),
    );

    // It uses BlocProvider which creates SavingsBloc which calls repo.getSavingsGoals?
    // Wait, SavingsBloc might load data on init.
    // If it does, we need to mock that call.
    // But SavingsBloc(repo) logic depends on repo.
    // If SavingsBloc constructor doesn't do anything, we are fine.

    expect(find.byType(CreateSavingsGoalScreen), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Tạo mục tiêu mới'), findsOneWidget);
  });
}
