import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moneypod/screens/confirm_receive_payment_screen.dart';
import 'package:moneypod/repositories/group_repository.dart';
import 'package:moneypod/repositories/wallet_repository.dart';

class MockGroupRepository extends Mock implements GroupRepository {}

class MockWalletRepository extends Mock implements WalletRepository {}

void main() {
  late MockWalletRepository mockWalletRepository;

  setUp(() {
    mockWalletRepository = MockWalletRepository();

    // Mock wallet loading
    when(() => mockWalletRepository.getWallets()).thenAnswer((_) async => []);
  });

  testWidgets('ConfirmReceivePaymentScreen builds', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ConfirmReceivePaymentScreen(
          debtId: 'debt123',
          debtorName: 'Debtor',
          debtorAvatar: '',
          amount: 50000,
          description: 'Payment',
          groupName: 'Test Group',

          // notificationId removed as it's not in constructor
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byType(ConfirmReceivePaymentScreen), findsOneWidget);
    expect(find.text('50.000 ₫'), findsOneWidget); // Checks currency formatting
  });
}
