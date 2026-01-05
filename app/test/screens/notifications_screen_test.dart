import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moneypod/screens/notifications_screen.dart';
import 'package:moneypod/bloc/notification/notification_state.dart';
import 'package:moneypod/bloc/notification/notification_event.dart';
import 'package:moneypod/models/notification.dart';

import 'package:timeago/timeago.dart' as timeago;

import '../mocks/test_helper.dart';

void main() {
  late TestHelper helper;

  setUpAll(() {
    TestHelper.registerFallbacks();
    timeago.setLocaleMessages('vi', timeago.ViMessages());
  });

  setUp(() {
    helper = TestHelper();
    helper.setUp();
  });

  final testNotifications = [
    AppNotification(
      id: '1',
      title: 'Welcome',
      body: 'Welcome to MoneyPod',
      type: 'info',
      isRead: false,
      createdAt: DateTime.now(),
      data: {},
      userId: 'test-user-id',
    ),
    AppNotification(
      id: '2',
      title: 'Warning',
      body: 'Budget Exceeded',
      type: 'budget_exceeded',
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      data: {},
      userId: 'test-user-id',
    ),
  ];

  group('NotificationsScreen', () {
    testWidgets('renders loading state', (tester) async {
      when(
        () => helper.notificationBloc.state,
      ).thenReturn(NotificationLoading());

      await tester.pumpWidget(
        helper.wrapWithProviders(const NotificationsScreenView()),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders empty state', (tester) async {
      when(
        () => helper.notificationBloc.state,
      ).thenReturn(NotificationLoaded(notifications: [], unreadCount: 0));

      await tester.pumpWidget(
        helper.wrapWithProviders(const NotificationsScreenView()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chưa có thông báo nào'), findsOneWidget);
    });

    testWidgets('renders error state', (tester) async {
      const errorMessage = 'Failed to load notifications';
      when(
        () => helper.notificationBloc.state,
      ).thenReturn(NotificationError(errorMessage));

      await tester.pumpWidget(
        helper.wrapWithProviders(const NotificationsScreenView()),
      );
      await tester.pumpAndSettle();

      expect(find.text(errorMessage), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);
    });

    testWidgets('renders list of notifications', (tester) async {
      when(() => helper.notificationBloc.state).thenReturn(
        NotificationLoaded(notifications: testNotifications, unreadCount: 1),
      );

      await tester.pumpWidget(
        helper.wrapWithProviders(const NotificationsScreenView()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Welcome'), findsOneWidget);
      expect(find.text('Budget Exceeded'), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('triggers refresh on pull down', (tester) async {
      when(() => helper.notificationBloc.state).thenReturn(
        NotificationLoaded(notifications: testNotifications, unreadCount: 1),
      );

      await tester.pumpWidget(
        helper.wrapWithProviders(const NotificationsScreenView()),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, 300));
      await tester.pumpAndSettle();

      verify(
        () =>
            helper.notificationBloc.add(any(that: isA<NotificationRefresh>())),
      ).called(1);
    });

    testWidgets('clicking mark all read triggers event', (tester) async {
      when(() => helper.notificationBloc.state).thenReturn(
        NotificationLoaded(notifications: testNotifications, unreadCount: 1),
      );

      await tester.pumpWidget(
        helper.wrapWithProviders(const NotificationsScreenView()),
      );
      await tester.pumpAndSettle();

      // Open popup menu
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      // Tap 'Đánh dấu tất cả đã đọc'
      await tester.tap(find.text('Đánh dấu tất cả đã đọc'));
      await tester.pumpAndSettle();

      verify(
        () => helper.notificationBloc.add(
          any(that: isA<NotificationMarkAllAsRead>()),
        ),
      ).called(1);
    });

    testWidgets('clicking delete all shows dialog', (tester) async {
      when(() => helper.notificationBloc.state).thenReturn(
        NotificationLoaded(notifications: testNotifications, unreadCount: 1),
      );

      await tester.pumpWidget(
        helper.wrapWithProviders(const NotificationsScreenView()),
      );
      await tester.pumpAndSettle();

      // Open popup menu
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      // Tap 'Xóa tất cả'
      await tester.tap(find.text('Xóa tất cả'));
      await tester.pumpAndSettle();

      expect(find.text('Xóa tất cả thông báo?'), findsOneWidget);

      // Confirm delete
      await tester.tap(find.text('Xóa').last);
      await tester.pumpAndSettle();

      verify(
        () => helper.notificationBloc.add(
          any(that: isA<NotificationDeleteAll>()),
        ),
      ).called(1);
    });

    testWidgets('tapping notification marks as read', (tester) async {
      when(() => helper.notificationBloc.state).thenReturn(
        NotificationLoaded(notifications: testNotifications, unreadCount: 1),
      );

      await tester.pumpWidget(
        helper.wrapWithProviders(const NotificationsScreenView()),
      );
      await tester.pumpAndSettle();

      // Tap the unread notification ('Welcome')
      await tester.tap(find.text('Welcome'));
      await tester.pump();

      verify(
        () => helper.notificationBloc.add(
          any(that: isA<NotificationMarkAsRead>()),
        ),
      ).called(1);
    });

    testWidgets('dismissing notification triggers delete', (tester) async {
      when(() => helper.notificationBloc.state).thenReturn(
        NotificationLoaded(notifications: testNotifications, unreadCount: 1),
      );

      await tester.pumpWidget(
        helper.wrapWithProviders(const NotificationsScreenView()),
      );
      await tester.pumpAndSettle();

      // Swipe left to delete 'Welcome'
      await tester.drag(find.text('Welcome'), const Offset(-500, 0));
      await tester.pumpAndSettle();

      // Confirm dialog appears
      expect(find.text('Xóa thông báo?'), findsOneWidget);

      await tester.tap(find.text('Xóa'));
      await tester.pumpAndSettle();

      verify(
        () => helper.notificationBloc.add(any(that: isA<NotificationDelete>())),
      ).called(1);
    });
  });
}
