import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moneypod/bloc/auth/auth_bloc.dart';
import 'package:moneypod/bloc/auth/auth_state.dart';
import 'package:moneypod/bloc/auth/auth_event.dart';
import 'package:moneypod/bloc/notification/notification_bloc.dart';
import 'package:moneypod/bloc/notification/notification_event.dart';
import 'package:moneypod/bloc/notification/notification_state.dart';
import 'package:moneypod/models/profile.dart';
import 'package:moneypod/models/user.dart';
import 'package:moneypod/widgets/header_widget.dart';
import 'package:moneypod/widgets/notification_badge.dart';

class MockNotificationBloc
    extends MockBloc<NotificationEvent, NotificationState>
    implements NotificationBloc {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockNotificationBloc mockNotificationBloc;
  late MockAuthBloc mockAuthBloc;

  setUp(() {
    mockNotificationBloc = MockNotificationBloc();
    mockAuthBloc = MockAuthBloc();
  });

  group('HeaderWidget', () {
    final profile = Profile(
      id: '1',
      email: 'test@test.com',
      fullName: 'John Doe',
      avatarUrl: null, // Avoid NetworkImage in tests
    );

    testWidgets('renders user profile and notification badge', (tester) async {
      when(
        () => mockNotificationBloc.state,
      ).thenReturn(NotificationLoaded(notifications: [], unreadCount: 5));
      when(() => mockAuthBloc.state).thenReturn(
        AuthAuthenticated(
          User(
            id: '1',
            email: 'test@test.com',
            token: 'token',
            fullName: 'John Doe',
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiBlocProvider(
              providers: [
                BlocProvider<NotificationBloc>.value(
                  value: mockNotificationBloc,
                ),
                BlocProvider<AuthBloc>.value(value: mockAuthBloc),
              ],
              child: HeaderWidget(profile: profile),
            ),
          ),
        ),
      );

      // Verify Profile Info
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Xin chào,'), findsOneWidget);
      expect(find.byType(CircleAvatar), findsOneWidget);

      // Verify Notification Badge
      expect(find.byIcon(LucideIcons.bell), findsOneWidget);
      expect(find.byType(NotificationBadge), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });
  });
}
