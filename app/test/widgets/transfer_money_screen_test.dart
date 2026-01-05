import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moneypod/screens/transfer_money_screen.dart';
import 'package:moneypod/repositories/wallet_repository.dart';

class MockWalletRepository extends Mock implements WalletRepository {}

void main() {
  late MockWalletRepository mockWalletRepo;

  setUp(() {
    mockWalletRepo = MockWalletRepository();
    when(() => mockWalletRepo.getWallets()).thenAnswer((_) async => []);
  });

  testWidgets('TransferMoneyScreen builds', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(home: TransferMoneyScreen(walletRepository: mockWalletRepo)),
    );

    expect(find.byType(TransferMoneyScreen), findsOneWidget);
    expect(find.text('Chuyển tiền giữa các ví'), findsOneWidget);
    await tester.pumpAndSettle();
  });
}
