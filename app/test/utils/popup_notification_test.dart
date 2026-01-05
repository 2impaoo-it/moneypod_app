import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneypod/utils/popup_notification.dart';

void main() {
  group('PopupNotification', () {
    testWidgets('showSuccess displays success dialog', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  PopupNotification.showSuccess(
                    context,
                    'Test success message',
                  );
                },
                child: const Text('Show Success'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Success'));
      await tester.pumpAndSettle();

      expect(find.text('Thành công'), findsOneWidget);
      expect(find.text('Test success message'), findsOneWidget);
      expect(find.text('Đóng'), findsOneWidget);
    });

    testWidgets('showError displays error dialog', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  PopupNotification.showError(context, 'Test error message');
                },
                child: const Text('Show Error'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Error'));
      await tester.pumpAndSettle();

      expect(find.text('Lỗi'), findsOneWidget);
      expect(find.text('Test error message'), findsOneWidget);
    });

    testWidgets('showWarning displays warning dialog', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  PopupNotification.showWarning(context, 'Test warning');
                },
                child: const Text('Show Warning'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Warning'));
      await tester.pumpAndSettle();

      expect(find.text('Cảnh báo'), findsOneWidget);
      expect(find.text('Test warning'), findsOneWidget);
    });

    testWidgets('close button dismisses dialog', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  PopupNotification.showSuccess(context, 'Dismiss test');
                },
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.text('Dismiss test'), findsOneWidget);

      await tester.tap(find.text('Đóng'));
      await tester.pumpAndSettle();

      expect(find.text('Dismiss test'), findsNothing);
    });
  });
}
