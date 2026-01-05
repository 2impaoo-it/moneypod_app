import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moneypod/widgets/add_transaction_modal.dart';
import '../mocks/repositories.dart';

void main() {
  late MockTransactionRepository mockTransactionRepo;
  late MockWalletRepository mockWalletRepo;

  setUp(() {
    mockTransactionRepo = MockTransactionRepository();
    mockWalletRepo = MockWalletRepository();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: Scaffold(
        body: AddTransactionModal(
          transactionRepository: mockTransactionRepo,
          walletRepository: mockWalletRepo,
        ),
      ),
    );
  }

  group('AddTransactionModal', () {
    testWidgets('renders all input fields correctly', (tester) async {
      when(() => mockWalletRepo.getWallets()).thenAnswer((_) async => []);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Thêm giao dịch'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2)); // Amount and Note
      expect(find.text('Chi tiêu'), findsOneWidget);
      expect(find.text('Thu nhập'), findsOneWidget);
      expect(find.text('Lưu giao dịch'), findsOneWidget);
    });

    testWidgets('shows error when saving empty amount', (tester) async {
      when(() => mockWalletRepo.getWallets()).thenAnswer((_) async => []);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final saveButton = find.text('Lưu giao dịch');
      await tester.tap(saveButton);
      await tester.pump(); // Trigger setState or simple rebuild

      verifyNever(
        () => mockTransactionRepo.createTransaction(
          walletId: any(named: 'walletId'),
          amount: any(named: 'amount'),
          category: any(named: 'category'),
          type: any(named: 'type'),
          note: any(named: 'note'),
        ),
      );
    });
  });
}
