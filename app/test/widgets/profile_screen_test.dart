import 'package:flutter_test/flutter_test.dart';
import 'package:moneypod/models/user.dart';

void main() {
  group('ProfileScreen', () {
    test('User model properties', () {
      final user = User(
        id: '1',
        email: 'test@example.com',
        fullName: 'Test User',
      );

      expect(user.id, equals('1'));
      expect(user.email, equals('test@example.com'));
      expect(user.fullName, equals('Test User'));
    });

    test('User model fromJson', () {
      final json = {
        'id': '1',
        'email': 'test@example.com',
        'full_name': 'Test User',
      };

      final user = User.fromJson(json);
      expect(user.id, equals('1'));
      expect(user.email, equals('test@example.com'));
      expect(user.fullName, equals('Test User'));
    });

    test('User model toJson', () {
      final user = User(
        id: '1',
        email: 'test@example.com',
        fullName: 'Test User',
      );

      final json = user.toJson();
      expect(json['id'], equals('1'));
      expect(json['email'], equals('test@example.com'));
      expect(json['full_name'], equals('Test User'));
    });

    test('User model handles null avatarUrl', () {
      final user = User(
        id: '1',
        email: 'test@example.com',
        fullName: 'Test User',
        avatarUrl: null,
      );

      expect(user.avatarUrl, isNull);
    });

    test('User model handles avatar', () {
      final user = User(
        id: '1',
        email: 'test@example.com',
        fullName: 'Test User',
        avatarUrl: 'https://example.com/avatar.png',
      );

      expect(user.avatarUrl, equals('https://example.com/avatar.png'));
    });
  });
}
