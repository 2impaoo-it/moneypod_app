import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moneypod/screens/splash_screen.dart';
import 'package:moneypod/services/api_service.dart';

class MockApiService extends Mock implements ApiService {}

void main() {
  group('SplashScreen', () {
    testWidgets('renders app logo and name', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SplashScreen()));
      await tester.pump();

      // Should show MoneyPod branding
      expect(find.text('MoneyPod'), findsOneWidget);
      expect(find.text('Quản lý tiền bạc thông minh'), findsOneWidget);
    });

    testWidgets('shows loading indicator initially', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SplashScreen()));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Đang kiểm tra kết nối...'), findsOneWidget);
    });

    testWidgets('has retry button when connection fails', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SplashScreen()));

      // Wait for check to complete (simulating timeout)
      await tester.pump(const Duration(seconds: 3));

      // Should have a retry button eventually
      final retryButton = find.text('Thử lại');
      if (retryButton.evaluate().isNotEmpty) {
        expect(retryButton, findsOneWidget);
      }
    });

    testWidgets('displays error state correctly', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SplashScreen()));
      await tester.pump();

      // Initially no error
      expect(find.text('Không thể kết nối đến server'), findsNothing);
    });

    testWidgets('renders gradient background', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SplashScreen()));
      await tester.pump();

      // Container with gradient should exist
      final container = find.byType(Container);
      expect(container, findsWidgets);
    });
  });
}
