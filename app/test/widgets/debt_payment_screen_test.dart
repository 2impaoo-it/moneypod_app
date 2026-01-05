import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moneypod/screens/debt_payment_screen.dart';
import 'package:moneypod/repositories/group_repository.dart';
import 'package:moneypod/repositories/wallet_repository.dart';

class MockGroupRepository extends Mock implements GroupRepository {}

class MockWalletRepository extends Mock implements WalletRepository {}

void main() {
  late MockGroupRepository mockGroupRepo;
  late MockWalletRepository mockWalletRepo;

  setUp(() {
    mockGroupRepo = MockGroupRepository();
    mockWalletRepo = MockWalletRepository();

    when(() => mockWalletRepo.getWallets()).thenAnswer((_) async => []);
  });

  testWidgets('DebtPaymentScreen builds', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DebtPaymentScreen(
          debtId: 'debt1',
          creditorName: 'Creditor',
          creditorAvatar: '',
          amount: 100000,
          description: 'Test Debt',
          groupName: 'Group Test',
          groupRepository: mockGroupRepo,
          walletRepository: mockWalletRepo,
        ),
      ),
    );

    expect(find.byType(DebtPaymentScreen), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Thanh toán nợ'), findsOneWidget);
  });
}
