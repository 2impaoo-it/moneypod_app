import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moneypod/bloc/notification/notification_bloc.dart';
import 'package:moneypod/bloc/notification/notification_event.dart';
import 'package:moneypod/bloc/notification/notification_state.dart';
import 'package:moneypod/repositories/notification_repository.dart';
import 'package:moneypod/models/notification.dart';

class MockNotificationRepository extends Mock
    implements NotificationRepository {}

void main() {
  late MockNotificationRepository mockRepository;

  setUp(() {
    mockRepository = MockNotificationRepository();
  });

  group('NotificationBloc', () {
    final mockNotification = AppNotification(
      id: '1',
      userId: 'user1',
      title: 'Test',
      body: 'Body',
      isRead: false,
      type: 'info',
      createdAt: DateTime.now(),
      data: {},
    );

    blocTest<NotificationBloc, NotificationState>(
      'emits [Loading, Loaded] when NotificationLoadRequested is added',
      build: () {
        when(
          () => mockRepository.getNotifications('token'),
        ).thenAnswer((_) async => [mockNotification]);
        when(
          () => mockRepository.getUnreadCount('token'),
        ).thenAnswer((_) async => 1);
        return NotificationBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(NotificationLoadRequested('token')),
      expect: () => [isA<NotificationLoading>(), isA<NotificationLoaded>()],
    );

    blocTest<NotificationBloc, NotificationState>(
      'updates unread count when NotificationLoadUnreadCount is added',
      build: () {
        when(
          () => mockRepository.getUnreadCount('token'),
        ).thenAnswer((_) async => 5);
        return NotificationBloc(repository: mockRepository);
      },
      seed: () => NotificationLoaded(notifications: [], unreadCount: 0),
      act: (bloc) => bloc.add(NotificationLoadUnreadCount('token')),
      expect: () => [NotificationLoaded(notifications: [], unreadCount: 5)],
    );
    blocTest<NotificationBloc, NotificationState>(
      'emits [NotificationActionSuccess, NotificationLoading, NotificationLoaded] when MarkAllAsRead succeeds',
      build: () {
        when(
          () => mockRepository.markAllAsRead('token'),
        ).thenAnswer((_) async => true);
        when(
          () => mockRepository.getNotifications('token'),
        ).thenAnswer((_) async => []);
        when(
          () => mockRepository.getUnreadCount('token'),
        ).thenAnswer((_) async => 0);
        return NotificationBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(NotificationMarkAllAsRead('token')),
      wait: const Duration(milliseconds: 100),
      expect: () => [
        isA<NotificationActionSuccess>(),
        isA<NotificationLoading>(),
        isA<NotificationLoaded>(),
      ],
    );

    blocTest<NotificationBloc, NotificationState>(
      'emits [NotificationActionSuccess, NotificationLoading, NotificationLoaded] when Delete succeeds',
      build: () {
        when(
          () => mockRepository.deleteNotification('token', '1'),
        ).thenAnswer((_) async => true);
        when(
          () => mockRepository.getNotifications('token'),
        ).thenAnswer((_) async => []);
        when(
          () => mockRepository.getUnreadCount('token'),
        ).thenAnswer((_) async => 0);
        return NotificationBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(NotificationDelete('token', '1')),
      wait: const Duration(milliseconds: 100),
      expect: () => [
        isA<NotificationActionSuccess>(),
        isA<NotificationLoading>(),
        isA<NotificationLoaded>(),
      ],
    );

    blocTest<NotificationBloc, NotificationState>(
      'emits [Loaded] with empty list when DeleteAll succeeds',
      build: () {
        when(
          () => mockRepository.deleteAllNotifications('token'),
        ).thenAnswer((_) async => true);
        return NotificationBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(NotificationDeleteAll('token')),
      expect: () => [
        // Logic: emit(Loaded([], 0)), emit(ActionSuccess)
        NotificationLoaded(notifications: [], unreadCount: 0),
        isA<NotificationActionSuccess>(),
      ],
    );

    final mockSettings = NotificationSettings(
      userId: 'user1',
      groupExpense: true,
      groupMemberAdded: true,
      groupMemberRemoved: true,
      groupDeleted: true,
      expenseUpdated: true,
      expenseDeleted: true,
      savingsGoalReached: true,
      savingsReminder: true,
      savingsProgress: true,
      systemAnnouncement: true,
      securityAlert: true,
      appUpdate: true,
      maintenance: true,
    );

    blocTest<NotificationBloc, NotificationState>(
      'emits [NotificationLoading, NotificationSettingsLoaded] when LoadSettings succeeds',
      build: () {
        when(
          () => mockRepository.getSettings('token'),
        ).thenAnswer((_) async => mockSettings);
        return NotificationBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(NotificationLoadSettings('token')),
      expect: () => [
        isA<NotificationLoading>(),
        NotificationSettingsLoaded(mockSettings),
      ],
    );

    blocTest<NotificationBloc, NotificationState>(
      'emits [NotificationLoading, NotificationSettingsUpdated, NotificationActionSuccess] when UpdateSettings succeeds',
      build: () {
        when(
          () => mockRepository.updateSettings('token', mockSettings),
        ).thenAnswer((_) async => mockSettings);
        return NotificationBloc(repository: mockRepository);
      },
      act: (bloc) =>
          bloc.add(NotificationUpdateSettings('token', mockSettings)),
      expect: () => [
        isA<NotificationLoading>(),
        NotificationSettingsUpdated(mockSettings),
        isA<NotificationActionSuccess>(),
      ],
    );
  });
}
