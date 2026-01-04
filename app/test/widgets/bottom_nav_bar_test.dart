import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneypod/widgets/bottom_nav_bar.dart';

void main() {
  testWidgets('CustomBottomNavBar builds correctly', (
    WidgetTester tester,
  ) async {
    int selectedIndex = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: CustomBottomNavBar(
            selectedIndex: selectedIndex,
            onItemTapped: (index) {
              selectedIndex = index;
            },
          ),
        ),
      ),
    );

    expect(find.text('Tổng quan'), findsOneWidget);
    expect(find.text('Giao dịch'), findsOneWidget);
    expect(find.text('Nhóm'), findsOneWidget);
    expect(find.text('Tiết kiệm'), findsOneWidget);

    await tester.tap(find.text('Giao dịch'));
    await tester.pump();
    expect(selectedIndex, 1);
  });
}
