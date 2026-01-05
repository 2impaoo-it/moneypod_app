import 'package:flutter_test/flutter_test.dart';
import 'package:moneypod/models/user.dart';

void main() {
  group('User Model', () {
    group('fromJson', () {
      test('parses complete JSON correctly', () {
        final json = {
          'id': '123',
          'email': 'test@example.com',
          'full_name': 'Test User',
          'token': 'abc123',
          'avatar_url': 'https://example.com/avatar.png',
        };

        final user = User.fromJson(json);

        expect(user.id, '123');
        expect(user.email, 'test@example.com');
        expect(user.fullName, 'Test User');
        expect(user.token, 'abc123');
        expect(user.avatarUrl, 'https://example.com/avatar.png');
      });

      test('handles uppercase ID key', () {
        final json = {'ID': 456, 'email': 'test@example.com'};

        final user = User.fromJson(json);
        expect(user.id, '456');
      });

      test('handles missing optional fields', () {
        final json = {'email': 'test@example.com'};

        final user = User.fromJson(json);

        expect(user.id, '');
        expect(user.email, 'test@example.com');
        expect(user.fullName, '');
        expect(user.token, isNull);
        expect(user.avatarUrl, isNull);
      });

      test('handles null values', () {
        final json = {'id': null, 'email': null, 'full_name': null};

        final user = User.fromJson(json);
        expect(user.id, '');
        expect(user.email, '');
        expect(user.fullName, '');
      });

      test('handles avatar key alternative', () {
        final json = {
          'email': 'test@example.com',
          'avatar': 'https://example.com/alt-avatar.png',
        };

        final user = User.fromJson(json);
        expect(user.avatarUrl, 'https://example.com/alt-avatar.png');
      });
    });

    group('toJson', () {
      test('serializes all fields correctly', () {
        const user = User(
          id: '123',
          email: 'test@example.com',
          fullName: 'Test User',
          token: 'abc123',
          avatarUrl: 'https://example.com/avatar.png',
        );

        final json = user.toJson();

        expect(json['id'], '123');
        expect(json['email'], 'test@example.com');
        expect(json['full_name'], 'Test User');
        expect(json['token'], 'abc123');
        expect(json['avatar_url'], 'https://example.com/avatar.png');
      });

      test('handles null optional fields', () {
        const user = User(email: 'test@example.com');

        final json = user.toJson();

        expect(json['id'], isNull);
        expect(json['full_name'], isNull);
        expect(json['token'], isNull);
        expect(json['avatar_url'], isNull);
      });
    });

    group('copyWith', () {
      test('copies all fields when provided', () {
        const original = User(
          id: '1',
          email: 'old@example.com',
          fullName: 'Old Name',
        );

        final copied = original.copyWith(
          id: '2',
          email: 'new@example.com',
          fullName: 'New Name',
          token: 'newToken',
          avatarUrl: 'https://new.com/avatar.png',
        );

        expect(copied.id, '2');
        expect(copied.email, 'new@example.com');
        expect(copied.fullName, 'New Name');
        expect(copied.token, 'newToken');
        expect(copied.avatarUrl, 'https://new.com/avatar.png');
      });

      test('preserves original values when not provided', () {
        const original = User(
          id: '1',
          email: 'test@example.com',
          fullName: 'Test',
          token: 'token',
        );

        final copied = original.copyWith(fullName: 'New Name');

        expect(copied.id, '1');
        expect(copied.email, 'test@example.com');
        expect(copied.fullName, 'New Name');
        expect(copied.token, 'token');
      });
    });

    group('Equatable', () {
      test('two users with same props are equal', () {
        const user1 = User(id: '1', email: 'test@example.com');
        const user2 = User(id: '1', email: 'test@example.com');

        expect(user1, equals(user2));
        expect(user1.hashCode, equals(user2.hashCode));
      });

      test('two users with different props are not equal', () {
        const user1 = User(id: '1', email: 'test@example.com');
        const user2 = User(id: '2', email: 'test@example.com');

        expect(user1, isNot(equals(user2)));
      });

      test('props contains all fields', () {
        const user = User(
          id: '1',
          email: 'test@example.com',
          fullName: 'Test',
          token: 'token',
          avatarUrl: 'url',
        );

        expect(user.props, hasLength(5));
        expect(user.props, contains('1'));
        expect(user.props, contains('test@example.com'));
        expect(user.props, contains('Test'));
        expect(user.props, contains('token'));
        expect(user.props, contains('url'));
      });
    });

    group('roundtrip', () {
      test('fromJson -> toJson preserves data', () {
        final originalJson = {
          'id': '123',
          'email': 'test@example.com',
          'full_name': 'Test User',
          'token': 'abc123',
          'avatar_url': 'https://example.com/avatar.png',
        };

        final user = User.fromJson(originalJson);
        final resultJson = user.toJson();

        expect(resultJson['id'], originalJson['id']);
        expect(resultJson['email'], originalJson['email']);
        expect(resultJson['full_name'], originalJson['full_name']);
        expect(resultJson['token'], originalJson['token']);
        expect(resultJson['avatar_url'], originalJson['avatar_url']);
      });
    });
  });
}
