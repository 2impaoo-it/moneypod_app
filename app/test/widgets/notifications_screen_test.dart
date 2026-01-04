import 'package:flutter_test/flutter_test.dart';
import 'package:moneypod/bloc/notification/notification_state.dart';
import 'package:moneypod/bloc/auth/auth_state.dart';
import 'package:moneypod/models/user.dart';

void main() {
  group('NotificationsScreen', () {
    test('NotificationState types exist', () {
      final initial = NotificationInitial();
      expect(initial, isA<NotificationState>());
    });

    test('NotificationLoading state exists', () {
      final loading = NotificationLoading();
      expect(loading, isA<NotificationState>());
    });

    test('AuthAuthenticated requires User', () {
      final user = User(id: '1', email: 'test@test.com', fullName: 'Test');
      final state = AuthAuthenticated(user);
      expect(state.user, equals(user));
    });

    test('AuthInitial state exists', () {
      expect(AuthInitial(), isA<AuthState>());
    });
  });
}
