import 'package:mocktail/mocktail.dart';
import 'package:moneypod/repositories/transaction_repository.dart';
import 'package:moneypod/services/auth_service.dart';
import 'package:moneypod/repositories/dashboard_repository.dart';
import 'package:moneypod/repositories/budget_repository.dart';
import 'package:moneypod/repositories/wallet_repository.dart';
import 'package:moneypod/repositories/bill_scan_repository.dart';
import 'package:moneypod/models/transaction.dart';
import 'package:moneypod/models/budget.dart';

// Mocks
class MockTransactionRepository extends Mock implements TransactionRepository {}

class MockAuthService extends Mock implements AuthService {}

class MockDashboardRepository extends Mock implements DashboardRepository {}

class MockBudgetRepository extends Mock implements BudgetRepository {}

class MockWalletRepository extends Mock implements WalletRepository {}

class MockBillScanRepository extends Mock implements BillScanRepository {}

// Fake classes to use with fallbackKey (registerFallbackValue)
class FakeTransaction extends Fake implements Transaction {}

class FakeBudget extends Fake implements Budget {}
