import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneypod/screens/profile/change_password_screen.dart';

void main() {
  group('ChangePasswordScreen', () {
    Widget createTestWidget() {
      return const MaterialApp(home: ChangePasswordScreen());
    }

    testWidgets('renders screen title', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('Đổi mật khẩu'), findsOneWidget);
    });

    testWidgets('has password input fields', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Should have 3 password fields: current, new, confirm
      expect(find.byType(TextFormField), findsNWidgets(3));
    });

    testWidgets('has submit button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('Đổi mật khẩu'), findsWidgets); // Title and button
    });

    testWidgets('shows password field labels', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('Mật khẩu hiện tại'), findsOneWidget);
      expect(find.text('Mật khẩu mới'), findsOneWidget);
      expect(find.text('Xác nhận mật khẩu mới'), findsOneWidget);
    });

    testWidgets('has visibility toggle icons', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Each password field should have a visibility toggle
      expect(find.byType(IconButton), findsWidgets);
    });

    testWidgets('password fields are initially obscured', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Find TextField widgets and check their obscureText property
      final textFields = tester.widgetList<TextField>(find.byType(TextField));
      for (final field in textFields) {
        expect(field.obscureText, isTrue);
      }
    });
  });
}
