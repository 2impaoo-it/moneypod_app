import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:moneypod/repositories/notification_repository.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late NotificationRepository repository;

  setUp(() {
    mockDio = MockDio();
    repository = NotificationRepository(dio: mockDio);
  });

  group('NotificationRepository', () {
    test('getNotifications returns list', () async {
      when(
        () => mockDio.get('/notifications', options: any(named: 'options')),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/notifications'),
          statusCode: 200,
          data: {
            'data': [
              {'id': '1', 'title': 'Test', 'body': 'Body', 'is_read': false},
            ],
          },
        ),
      );

      final notifications = await repository.getNotifications('token');

      expect(notifications.length, 1);
      expect(notifications.first.title, 'Test');
    });

    test('getUnreadCount returns correct count', () async {
      when(
        () => mockDio.get(
          '/notifications/unread-count',
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/notifications/unread-count'),
          statusCode: 200,
          data: {
            'data': {'count': 5},
          },
        ),
      );

      final count = await repository.getUnreadCount('token');

      expect(count, 5);
    });
  });
}
