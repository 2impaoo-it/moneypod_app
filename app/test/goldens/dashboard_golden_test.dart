import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moneypod/bloc/dashboard/dashboard_bloc.dart';
import 'package:moneypod/bloc/dashboard/dashboard_state.dart';
import 'package:moneypod/bloc/auth/auth_bloc.dart';
import 'package:moneypod/bloc/auth/auth_state.dart';
import 'package:moneypod/bloc/settings/settings_cubit.dart'; // Import SettingsCubit
import 'package:moneypod/screens/dashboard_screen.dart';
import 'package:moneypod/models/dashboard_data.dart';
import 'package:moneypod/models/user.dart';

class MockDashboardBloc extends Mock implements DashboardBloc {}

class MockAuthBloc extends Mock implements AuthBloc {}

class MockSettingsCubit extends Mock
    implements SettingsCubit {} // Mock SettingsCubit

void main() {
  late MockDashboardBloc mockDashboardBloc;
  late MockAuthBloc mockAuthBloc;
  late MockSettingsCubit mockSettingsCubit;

  setUp(() {
    mockDashboardBloc = MockDashboardBloc();
    mockAuthBloc = MockAuthBloc();
    mockSettingsCubit = MockSettingsCubit();

    when(
      () => mockAuthBloc.stream,
    ).thenAnswer((_) => Stream.value(AuthInitial()));
    when(() => mockAuthBloc.state).thenReturn(AuthInitial());
    when(() => mockAuthBloc.close()).thenAnswer((_) async {});

    when(
      () => mockDashboardBloc.stream,
    ).thenAnswer((_) => Stream.value(DashboardInitial()));
    when(() => mockDashboardBloc.state).thenReturn(DashboardInitial());
    when(() => mockDashboardBloc.close()).thenAnswer((_) async {});

    // Stub SettingsCubit
    when(
      () => mockSettingsCubit.stream,
    ).thenAnswer((_) => Stream.value(false)); // isDarkTheme = false
    when(() => mockSettingsCubit.state).thenReturn(false);
  });

  testWidgets('DashboardScreen initial state golden test', (
    WidgetTester tester,
  ) async {
    final dummyData = DashboardData(
      userInfo: User(id: 'u1', email: 'test@test.com', fullName: 'John Doe'),
      totalBalance: 1234567.0,
      wallets: [],
      recentTransactions: [],
    );

    when(() => mockDashboardBloc.state).thenReturn(DashboardLoaded(dummyData));

    await tester.pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: mockAuthBloc),
            BlocProvider<DashboardBloc>.value(value: mockDashboardBloc),
            BlocProvider<SettingsCubit>.value(
              value: mockSettingsCubit,
            ), // Provide SettingsCubit
          ],
          child: const DashboardScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await expectLater(
      find.byType(DashboardScreen),
      matchesGoldenFile('goldens/dashboard_screen_loaded.png'),
    );
  });
}
