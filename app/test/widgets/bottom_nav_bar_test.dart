import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneypod/widgets/bottom_nav_bar.dart';

void main() {
  group('CustomBottomNavBar', () {
    testWidgets('renders all navigation items', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: CustomBottomNavBar(
              selectedIndex: 0,
              onItemTapped: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Tổng quan'), findsOneWidget);
      expect(find.text('Giao dịch'), findsOneWidget);
      expect(find.text('Nhóm'), findsOneWidget);
      expect(find.text('Tiết kiệm'), findsOneWidget);
    });

    testWidgets('highlights selected item (index 0)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: CustomBottomNavBar(
              selectedIndex: 0,
              onItemTapped: (_) {},
            ),
          ),
        ),
      );

      // Icon filled for selected
      expect(find.byIcon(Icons.dashboard), findsOneWidget);
      // Icon outlined for unselected
      expect(find.byIcon(Icons.group_outlined), findsOneWidget);
    });

    testWidgets('triggers callback on tap', (tester) async {
      int? tappedIndex;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: CustomBottomNavBar(
              selectedIndex: 0,
              onItemTapped: (index) {
                tappedIndex = index;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Nhóm'));
      expect(tappedIndex, 2);

      await tester.tap(find.text('Giao dịch'));
      expect(tappedIndex, 1);
    });
  });
}
