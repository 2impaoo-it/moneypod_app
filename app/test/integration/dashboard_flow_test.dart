import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:moneypod/bloc/dashboard/dashboard_bloc.dart';
import 'package:moneypod/bloc/dashboard/dashboard_event.dart';
import 'package:moneypod/bloc/dashboard/dashboard_state.dart';
import 'package:moneypod/bloc/settings/settings_cubit.dart';
import 'package:moneypod/models/dashboard_data.dart';
import 'package:moneypod/screens/dashboard_screen.dart';
import 'package:moneypod/models/user.dart';

class MockDashboardBloc extends MockBloc<DashboardEvent, DashboardState>
    implements DashboardBloc {}

class MockSettingsCubit extends MockCubit<bool> implements SettingsCubit {}

class MockGoRouter extends Mock implements GoRouter {}

void main() {
  late MockDashboardBloc mockDashboardBloc;
  late MockSettingsCubit mockSettingsCubit;

  setUp(() {
    mockDashboardBloc = MockDashboardBloc();
    mockSettingsCubit = MockSettingsCubit();

    // Default mock behavior
    when(() => mockSettingsCubit.state).thenReturn(true); // Balance visible
  });

  Future<void> pumpDashboardScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<DashboardBloc>.value(value: mockDashboardBloc),
            BlocProvider<SettingsCubit>.value(value: mockSettingsCubit),
          ],
          child: const DashboardScreen(),
        ),
      ),
    );
  }

  group('Dashboard Flow Integration', () {
    testWidgets('Dashboard displays loading state initially', (tester) async {
      when(() => mockDashboardBloc.state).thenReturn(DashboardLoading());

      await pumpDashboardScreen(tester);
      await tester.pump(); // frame

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Dashboard displays loaded data', (tester) async {
      final mockData = DashboardData(
        userInfo: User(id: '1', email: 'test@test.com', fullName: 'Test User'),
        totalBalance: 1000000,
        wallets: [],
        recentTransactions: [],
      );

      when(() => mockDashboardBloc.state).thenReturn(DashboardLoaded(mockData));

      await pumpDashboardScreen(tester);
      await tester.pumpAndSettle();

      // Check Header
      expect(
        find.text('Test User'),
        findsOneWidget,
      ); // Assuming HeaderWidget shows name

      // Check Balance
      expect(find.textContaining('1.000.000'), findsOneWidget);
      expect(find.text('Số dư khả dụng'), findsOneWidget);
    });

    testWidgets('Pull to refresh triggers DashboardRefreshRequested', (
      tester,
    ) async {
      final mockData = DashboardData(
        userInfo: User(id: '1', email: 'test@test.com', fullName: 'Test User'),
        totalBalance: 1000000,
        wallets: [],
        recentTransactions: [],
      );

      when(() => mockDashboardBloc.state).thenReturn(DashboardLoaded(mockData));

      await pumpDashboardScreen(tester);
      await tester.pumpAndSettle();

      // Find scrollable area
      final finder = find.byType(SingleChildScrollView);

      // Drag down
      await tester.drag(finder, const Offset(0, 300));
      await tester.pumpAndSettle();

      verify(
        () => mockDashboardBloc.add(DashboardRefreshRequested()),
      ).called(1);
    });

    testWidgets('Toggle balance visibility interaction', (tester) async {
      final mockData = DashboardData(
        userInfo: User(id: '1', email: 'test@test.com', fullName: 'Test User'),
        totalBalance: 1000000,
        wallets: [],
        recentTransactions: [],
      );

      when(() => mockDashboardBloc.state).thenReturn(DashboardLoaded(mockData));
      // Start visible
      when(() => mockSettingsCubit.state).thenReturn(true);

      await pumpDashboardScreen(tester);
      await tester.pumpAndSettle();

      // Verify balance visible
      expect(find.textContaining('1.000.000'), findsOneWidget);

      // Find the toggle button (eye icon)
      // We will look for the icon directly that represents the toggle state
      // final isBalanceVisible = mockSettingsCubit.state;
      // Note: App might use LucideIcons, checking source again...
      // Source says: Icon(isBalanceVisible ? LucideIcons.eye : LucideIcons.eyeOff)
      // LucideIcons.eye is an IconData.

      // Let's tap the InkWell that contains the eye icon.
      // Since there are multiple InkWells (Reports, Wallets, etc), we need to be specific.
      // The toggle is in the "Balance Card".

      // Attempting to find by IconData might be fragile if LucideIcons are proxied.
      // Let's use `find.byType(InkWell).at(1)` as a fallback but verify it's the right one if possible.
      // Or better, finding by key if keys were added. No keys in source.

      await tester.tap(find.byType(InkWell).at(1));

      verify(() => mockSettingsCubit.toggleBalanceVisibility()).called(1);
    });
  });
}
