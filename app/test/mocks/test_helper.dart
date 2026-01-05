// Comprehensive BLoC Mocks for Screen Testing
//
// This file provides all the mock BLoCs needed for screen testing.
// Usage: import this file and use the provided mock classes with default behaviors.

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

// Auth BLoC
import 'package:moneypod/bloc/auth/auth_bloc.dart';
import 'package:moneypod/bloc/auth/auth_event.dart';
import 'package:moneypod/bloc/auth/auth_state.dart';
import 'package:moneypod/models/user.dart';
import 'package:moneypod/models/profile.dart';

// Dashboard BLoC
import 'package:moneypod/bloc/dashboard/dashboard_bloc.dart';
import 'package:moneypod/bloc/dashboard/dashboard_event.dart';
import 'package:moneypod/bloc/dashboard/dashboard_state.dart';
import 'package:moneypod/models/dashboard_data.dart';

// Transaction BLoC
import 'package:moneypod/bloc/transaction/transaction_bloc.dart';
import 'package:moneypod/bloc/transaction/transaction_event.dart';
import 'package:moneypod/bloc/transaction/transaction_state.dart';
import 'package:moneypod/models/transaction.dart' as model;

// Savings BLoC
import 'package:moneypod/bloc/savings/savings_bloc.dart';
import 'package:moneypod/bloc/savings/savings_event.dart';
import 'package:moneypod/bloc/savings/savings_state.dart';
import 'package:moneypod/models/savings_goal.dart';

// Budget BLoC
import 'package:moneypod/bloc/budget/budget_bloc.dart';
import 'package:moneypod/bloc/budget/budget_event.dart';
import 'package:moneypod/bloc/budget/budget_state.dart';
import 'package:moneypod/models/budget.dart';

// Wallet List BLoC
import 'package:moneypod/bloc/wallet_list/wallet_list_bloc.dart';
import 'package:moneypod/bloc/wallet_list/wallet_list_event.dart';
import 'package:moneypod/bloc/wallet_list/wallet_list_state.dart';
import 'package:moneypod/models/wallet.dart';

// Notification BLoC
import 'package:moneypod/bloc/notification/notification_bloc.dart';
import 'package:moneypod/bloc/notification/notification_event.dart';
import 'package:moneypod/bloc/notification/notification_state.dart';

// Settings Cubit
import 'package:moneypod/bloc/settings/settings_cubit.dart';

// Services
import 'package:moneypod/services/biometric_service.dart';
import 'package:moneypod/services/fcm_service.dart';
import 'package:moneypod/services/profile_service.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

// ============================================================================
// MOCK BLOC CLASSES
// ============================================================================

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockDashboardBloc extends MockBloc<DashboardEvent, DashboardState>
    implements DashboardBloc {}

class MockTransactionBloc extends MockBloc<TransactionEvent, TransactionState>
    implements TransactionBloc {}

class MockSavingsBloc extends MockBloc<SavingsEvent, SavingsState>
    implements SavingsBloc {}

class MockBudgetBloc extends MockBloc<BudgetEvent, BudgetState>
    implements BudgetBloc {}

class MockWalletListBloc extends MockBloc<WalletListEvent, WalletListState>
    implements WalletListBloc {}

class MockNotificationBloc
    extends MockBloc<NotificationEvent, NotificationState>
    implements NotificationBloc {}

class MockSettingsCubit extends MockCubit<bool> implements SettingsCubit {}

// ============================================================================
// MOCK SERVICES
// ============================================================================

class MockBiometricService extends Mock implements BiometricService {}

class MockFCMService extends Mock implements FCMService {}

class MockProfileService extends Mock implements ProfileService {}

class MockFirebaseAuth extends Mock implements firebase_auth.FirebaseAuth {}

// ============================================================================
// FAKE CLASSES FOR registerFallbackValue
// ============================================================================

class FakeAuthEvent extends Fake implements AuthEvent {}

class FakeDashboardEvent extends Fake implements DashboardEvent {}

class FakeTransactionEvent extends Fake implements TransactionEvent {}

class FakeSavingsEvent extends Fake implements SavingsEvent {}

class FakeBudgetEvent extends Fake implements BudgetEvent {}

class FakeWalletListEvent extends Fake implements WalletListEvent {}

class FakeNotificationEvent extends Fake implements NotificationEvent {}

// ============================================================================
// TEST HELPER CLASS
// ============================================================================

/// Helper class that provides pre-configured mocks and test data
class TestHelper {
  // Mock instances
  late MockAuthBloc authBloc;
  late MockDashboardBloc dashboardBloc;
  late MockTransactionBloc transactionBloc;
  late MockSavingsBloc savingsBloc;
  late MockBudgetBloc budgetBloc;
  late MockWalletListBloc walletListBloc;
  late MockNotificationBloc notificationBloc;
  late MockSettingsCubit settingsCubit;
  late MockBiometricService biometricService;
  late MockFCMService fcmService;
  late MockProfileService profileService;
  late MockFirebaseAuth firebaseAuth;

  // Test data
  static final testUser = User(
    id: 'test-user-id',
    email: 'test@example.com',
    fullName: 'Test User',
    token: 'test-token',
  );

  static final testWallets = [
    Wallet(
      id: 'w1',
      name: 'Cash',
      balance: 5000000,
      currency: 'VND',
      userId: 'test-user-id',
      createdAt: DateTime.now(),
    ),
    Wallet(
      id: 'w2',
      name: 'Bank',
      balance: 10000000,
      currency: 'VND',
      userId: 'test-user-id',
      createdAt: DateTime.now(),
    ),
  ];

  static final testTransactions = [
    model.Transaction(
      id: 't1',
      title: 'Lunch',
      category: 'Ăn uống',
      amount: 50000,
      date: DateTime.now(),
      isExpense: true,
    ),
    model.Transaction(
      id: 't2',
      title: 'Salary',
      category: 'Lương',
      amount: 10000000,
      date: DateTime.now(),
      isExpense: false,
    ),
  ];

  static final testBudgets = [
    Budget(
      id: 'b1',
      category: 'Ăn uống',
      amount: 5000000,
      spent: 2000000,
      month: 1,
      year: 2026,
    ),
  ];

  static final testSavingsGoals = [
    SavingsGoal(
      id: 's1',
      userId: 'test-user-id',
      name: 'Vacation',
      targetAmount: 10000000,
      currentAmount: 5000000,
      status: 'IN_PROGRESS',
      isOverdue: false,
      createdAt: DateTime.now(),
    ),
  ];

  static DashboardData get testDashboardData => DashboardData(
    userInfo: testUser,
    totalBalance: 15000000,
    wallets: testWallets,
    recentTransactions: testTransactions,
  );

  /// Initialize all mocks with default behaviors
  void setUp() {
    // Initialize mocks
    authBloc = MockAuthBloc();
    dashboardBloc = MockDashboardBloc();
    transactionBloc = MockTransactionBloc();
    savingsBloc = MockSavingsBloc();
    budgetBloc = MockBudgetBloc();
    walletListBloc = MockWalletListBloc();
    notificationBloc = MockNotificationBloc();
    settingsCubit = MockSettingsCubit();
    biometricService = MockBiometricService();
    fcmService = MockFCMService();
    profileService = MockProfileService();
    firebaseAuth = MockFirebaseAuth();

    // Set default states
    when(() => authBloc.state).thenReturn(AuthAuthenticated(testUser));
    when(() => dashboardBloc.state).thenReturn(
      DashboardLoaded(
        testDashboardData,
        categoryStats: const {'Ăn uống': 50000},
        incomeStats: const {'Lương': 10000000},
      ),
    );
    when(
      () => transactionBloc.state,
    ).thenReturn(TransactionLoaded(testTransactions));
    when(() => savingsBloc.state).thenReturn(SavingsLoaded(testSavingsGoals));
    when(
      () => budgetBloc.state,
    ).thenReturn(BudgetLoaded(budgets: testBudgets, month: 1, year: 2026));
    // WalletListState uses status enum pattern
    when(() => walletListBloc.state).thenReturn(
      WalletListState(status: WalletStatus.success, wallets: testWallets),
    );
    when(
      () => notificationBloc.state,
    ).thenReturn(NotificationLoaded(notifications: [], unreadCount: 0));
    when(() => settingsCubit.state).thenReturn(true);

    // Service defaults
    when(
      () => biometricService.isBiometricAvailable(),
    ).thenAnswer((_) async => false);
    when(() => biometricService.getSavedAccounts()).thenAnswer((_) async => []);
    when(
      () => fcmService.getCurrentToken(),
    ).thenAnswer((_) async => 'mock-fcm-token');

    // Profile Service defaults
    when(() => profileService.getUserProfile(any())).thenAnswer(
      (_) async => Profile(
        id: 'test-user-id',
        email: 'test@example.com',
        fullName: 'Test User',
      ),
    );
  }

  /// Create a widget wrapped with all necessary BlocProviders
  Widget wrapWithProviders(Widget child) {
    return MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: authBloc),
          BlocProvider<DashboardBloc>.value(value: dashboardBloc),
          BlocProvider<TransactionBloc>.value(value: transactionBloc),
          BlocProvider<SavingsBloc>.value(value: savingsBloc),
          BlocProvider<BudgetBloc>.value(value: budgetBloc),
          BlocProvider<WalletListBloc>.value(value: walletListBloc),
          BlocProvider<NotificationBloc>.value(value: notificationBloc),
          BlocProvider<SettingsCubit>.value(value: settingsCubit),
        ],
        child: child,
      ),
    );
  }

  /// Register all fallback values for mocktail
  static void registerFallbacks() {
    registerFallbackValue(FakeAuthEvent());
    registerFallbackValue(FakeDashboardEvent());
    registerFallbackValue(FakeTransactionEvent());
    registerFallbackValue(FakeSavingsEvent());
    registerFallbackValue(FakeBudgetEvent());
    registerFallbackValue(FakeWalletListEvent());
    registerFallbackValue(FakeNotificationEvent());
  }
}
