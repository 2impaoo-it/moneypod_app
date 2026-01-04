import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:moneypod/screens/dashboard_screen.dart';
import 'package:moneypod/bloc/dashboard/dashboard_bloc.dart';
import 'package:moneypod/bloc/dashboard/dashboard_event.dart';
import 'package:moneypod/bloc/dashboard/dashboard_state.dart';
import 'package:moneypod/bloc/settings/settings_cubit.dart';

class MockDashboardBloc extends MockBloc<DashboardEvent, DashboardState>
    implements DashboardBloc {}

class MockSettingsCubit extends MockCubit<bool> implements SettingsCubit {}

void main() {
  late MockDashboardBloc mockDashboardBloc;
  late MockSettingsCubit mockSettingsCubit;

  setUp(() {
    mockDashboardBloc = MockDashboardBloc();
    mockSettingsCubit = MockSettingsCubit();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<DashboardBloc>.value(value: mockDashboardBloc),
          BlocProvider<SettingsCubit>.value(value: mockSettingsCubit),
        ],
        child: const DashboardScreen(),
      ),
    );
  }

  testWidgets('renders loading indicator when state is DashboardLoading', (
    tester,
  ) async {
    when(() => mockDashboardBloc.state).thenReturn(DashboardLoading());
    when(() => mockSettingsCubit.state).thenReturn(true);

    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('renders error message when state is DashboardError', (
    tester,
  ) async {
    when(
      () => mockDashboardBloc.state,
    ).thenReturn(DashboardError('Something went wrong'));
    when(() => mockSettingsCubit.state).thenReturn(true);

    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.text('Lỗi: Something went wrong'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
  });
}
