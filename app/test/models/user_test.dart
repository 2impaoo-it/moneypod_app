import 'package:flutter_test/flutter_test.dart';
import 'package:moneypod/models/user.dart';

void main() {
  group('User Model Test', () {
    test('supports value equality', () {
      final user1 = User(id: '1', email: 'test@exam.com', fullName: 'Test');
      final user2 = User(id: '1', email: 'test@exam.com', fullName: 'Test');
      expect(user1, equals(user2));
    });

    test('fromJson parses correctly', () {
      final json = {
        'id': '1',
        'email': 'test@exam.com',
        'full_name': 'Test User',
        'token': 'tok123',
        'avatar_url': 'http://avatar.com',
      };

      final user = User.fromJson(json);

      expect(user.id, '1');
      expect(user.email, 'test@exam.com');
      expect(user.fullName, 'Test User');
      expect(user.token, 'tok123');
      expect(user.avatarUrl, 'http://avatar.com');
    });

    test('toJson returns correct map', () {
      final user = User(
        id: '1',
        email: 'test@exam.com',
        fullName: 'Test User',
        token: 'tok123',
      );

      final json = user.toJson();

      expect(json['id'], '1');
      expect(json['email'], 'test@exam.com');
      expect(json['full_name'], 'Test User');
      expect(json['token'], 'tok123');
    });

    test('copyWith creates new instance with updated values', () {
      final user = User(id: '1', email: 'old@test.com');
      final updated = user.copyWith(email: 'new@test.com');

      expect(updated.id, '1');
      expect(updated.email, 'new@test.com');
    });
  });
}
