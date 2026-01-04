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
  });
}
