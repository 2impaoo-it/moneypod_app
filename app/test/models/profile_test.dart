import 'package:flutter_test/flutter_test.dart';
import 'package:moneypod/models/profile.dart';

void main() {
  group('Profile Model', () {
    group('fromJson', () {
      test('parses complete JSON correctly', () {
        final json = {
          'id': '123',
          'full_name': 'Test User',
          'email': 'test@example.com',
          'avatar_url': 'https://example.com/avatar.png',
          'phone': '0901234567',
        };

        final profile = Profile.fromJson(json);

        expect(profile.id, '123');
        expect(profile.fullName, 'Test User');
        expect(profile.email, 'test@example.com');
        expect(profile.avatarUrl, 'https://example.com/avatar.png');
        expect(profile.phone, '0901234567');
      });

      test('handles phoneNumber alternative key', () {
        final json = {'id': '1', 'phoneNumber': '0909876543'};

        final profile = Profile.fromJson(json);
        expect(profile.phone, '0909876543');
      });

      test('prefers phone over phoneNumber', () {
        final json = {'id': '1', 'phone': '111111', 'phoneNumber': '222222'};

        final profile = Profile.fromJson(json);
        expect(profile.phone, '111111');
      });

      test('handles null values', () {
        final json = <String, dynamic>{};

        final profile = Profile.fromJson(json);

        expect(profile.id, isNull);
        expect(profile.fullName, isNull);
        expect(profile.email, isNull);
        expect(profile.avatarUrl, isNull);
        expect(profile.phone, isNull);
      });
    });

    group('toJson', () {
      test('serializes all fields correctly', () {
        final profile = Profile(
          id: '123',
          fullName: 'Test User',
          email: 'test@example.com',
          avatarUrl: 'https://example.com/avatar.png',
          phone: '0901234567',
        );

        final json = profile.toJson();

        expect(json['id'], '123');
        expect(json['full_name'], 'Test User');
        expect(json['email'], 'test@example.com');
        expect(json['avatar_url'], 'https://example.com/avatar.png');
        expect(json['phone'], '0901234567');
      });

      test('handles null fields', () {
        final profile = Profile();

        final json = profile.toJson();

        expect(json['id'], isNull);
        expect(json['full_name'], isNull);
        expect(json['email'], isNull);
        expect(json['avatar_url'], isNull);
        expect(json['phone'], isNull);
      });
    });

    group('roundtrip', () {
      test('fromJson -> toJson preserves data', () {
        final originalJson = {
          'id': '123',
          'full_name': 'Test User',
          'email': 'test@example.com',
          'avatar_url': 'url',
          'phone': '123456',
        };

        final profile = Profile.fromJson(originalJson);
        final resultJson = profile.toJson();

        expect(resultJson['id'], originalJson['id']);
        expect(resultJson['full_name'], originalJson['full_name']);
        expect(resultJson['email'], originalJson['email']);
        expect(resultJson['avatar_url'], originalJson['avatar_url']);
        expect(resultJson['phone'], originalJson['phone']);
      });
    });
  });
}
