import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moneypod/screens/savings_screen.dart';
import 'package:moneypod/bloc/savings/savings_bloc.dart';
import 'package:moneypod/bloc/savings/savings_state.dart';
import 'package:moneypod/bloc/savings/savings_event.dart';
import 'package:moneypod/bloc/dashboard/dashboard_bloc.dart';
import 'package:moneypod/bloc/dashboard/dashboard_state.dart';
import 'package:moneypod/bloc/dashboard/dashboard_event.dart';

class MockSavingsBloc extends MockBloc<SavingsEvent, SavingsState>
    implements SavingsBloc {}

class MockDashboardBloc extends MockBloc<DashboardEvent, DashboardState>
    implements DashboardBloc {}

void main() {
  late MockSavingsBloc mockSavingsBloc;
  late MockDashboardBloc mockDashboardBloc;

  setUp(() {
    mockSavingsBloc = MockSavingsBloc();
    mockDashboardBloc = MockDashboardBloc();

    when(() => mockSavingsBloc.state).thenReturn(SavingsInitial());
    when(() => mockDashboardBloc.state).thenReturn(DashboardInitial());
  });

  testWidgets('SavingsScreen builds and loads goals', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<SavingsBloc>.value(value: mockSavingsBloc),
          BlocProvider<DashboardBloc>.value(value: mockDashboardBloc),
        ],
        child: const MaterialApp(home: SavingsScreen()),
      ),
    );

    expect(find.byType(SavingsScreen), findsOneWidget);
    verify(
      () => mockSavingsBloc.add(any(that: isA<LoadSavingsGoals>())),
    ).called(1);
  });
}
