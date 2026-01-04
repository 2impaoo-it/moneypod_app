import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moneypod/screens/savings_detail_screen.dart';
import 'package:moneypod/repositories/savings_repository.dart';
import 'package:moneypod/repositories/wallet_repository.dart';

class MockSavingsRepository extends Mock implements SavingsRepository {}

class MockWalletRepository extends Mock implements WalletRepository {}

void main() {
  late MockSavingsRepository mockSavingsRepo;
  late MockWalletRepository mockWalletRepo;

  setUp(() {
    mockSavingsRepo = MockSavingsRepository();
    mockWalletRepo = MockWalletRepository();

    when(() => mockWalletRepo.getWallets()).thenAnswer((_) async => []);
    when(
      () => mockSavingsRepo.getGoalTransactions(any()),
    ).thenAnswer((_) async => []);
    when(() => mockSavingsRepo.getSavingsGoals()).thenAnswer((_) async => []);
  });

  testWidgets('SavingsDetailScreen builds', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SavingsDetailScreen(
          goalId: 'goal-123',
          savingsRepository: mockSavingsRepo,
          walletRepository: mockWalletRepo,
        ),
      ),
    );

    expect(find.byType(SavingsDetailScreen), findsOneWidget);
    // Might need pumpAndSettle if it loads data
    await tester.pumpAndSettle();
  });
}
