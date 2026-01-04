import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moneypod/widgets/header_widget.dart';
import 'package:moneypod/models/profile.dart';
import 'package:moneypod/models/user.dart';
import 'package:moneypod/bloc/notification/notification_bloc.dart';
import 'package:moneypod/bloc/notification/notification_state.dart';
import 'package:moneypod/bloc/auth/auth_bloc.dart';
import 'package:moneypod/bloc/auth/auth_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MockNotificationBloc extends Mock implements NotificationBloc {}

class MockAuthBloc extends Mock implements AuthBloc {}

void main() {
  late MockNotificationBloc mockNotificationBloc;
  late MockAuthBloc mockAuthBloc;

  setUp(() {
    mockNotificationBloc = MockNotificationBloc();
    mockAuthBloc = MockAuthBloc();

    when(
      () => mockNotificationBloc.stream,
    ).thenAnswer((_) => Stream.value(NotificationInitial()));
    when(() => mockNotificationBloc.state).thenReturn(NotificationInitial());
    when(() => mockNotificationBloc.close()).thenAnswer((_) async {});

    when(
      () => mockAuthBloc.stream,
    ).thenAnswer((_) => Stream.value(AuthInitial()));
    when(() => mockAuthBloc.state).thenReturn(AuthInitial());
    when(() => mockAuthBloc.close()).thenAnswer((_) async {});
  });

  testWidgets('HeaderWidget builds with profile data', (
    WidgetTester tester,
  ) async {
    final profile = Profile(
      id: "1", // Fixed int to String
      fullName: 'Test User',
      email: 'test@examples.com',
    );

    when(
      () => mockAuthBloc.state,
    ).thenReturn(const AuthAuthenticated(User(email: 'test', token: 'token')));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MultiBlocProvider(
            providers: [
              BlocProvider<NotificationBloc>.value(value: mockNotificationBloc),
              BlocProvider<AuthBloc>.value(value: mockAuthBloc),
            ],
            child: HeaderWidget(profile: profile),
          ),
        ),
      ),
    );

    expect(find.text('Test User'), findsOneWidget);
    expect(find.text('Xin chào,'), findsOneWidget);
  });
}
