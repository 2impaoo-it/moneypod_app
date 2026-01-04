import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moneypod/screens/create_wallet_screen.dart';
import 'package:moneypod/repositories/wallet_repository.dart';

class MockWalletRepository extends Mock implements WalletRepository {}

void main() {
  testWidgets('CreateWalletScreen builds', (WidgetTester tester) async {
    final mockRepo = MockWalletRepository();

    await tester.pumpWidget(
      MaterialApp(home: CreateWalletScreen(walletRepository: mockRepo)),
    );

    expect(find.byType(CreateWalletScreen), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Tạo ví mới'), findsOneWidget);
  });
}
