import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneypod/screens/budget/create_budget_screen.dart';

void main() {
  group('CreateBudgetScreen', () {
    Widget createTestWidget() {
      return const MaterialApp(home: CreateBudgetScreen());
    }

    testWidgets('renders screen title', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('Tạo ngân sách'), findsOneWidget);
    });

    testWidgets('shows category selection header', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('Chọn danh mục chi tiêu'), findsOneWidget);
    });

    testWidgets('shows total monthly option', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('Tổng chi tiêu trong tháng'), findsOneWidget);
    });

    testWidgets('has continue button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('Tiếp tục'), findsOneWidget);
    });

    testWidgets('shows expense category groups', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Check for category group headers
      expect(find.textContaining('CHI TIÊU'), findsWidgets);
    });

    testWidgets('has radio list tiles for categories', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(RadioListTile<String>), findsWidgets);
      expect(find.byType(RadioListTile<bool>), findsOneWidget);
    });
  });
}
