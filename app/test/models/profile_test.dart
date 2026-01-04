import 'package:flutter_test/flutter_test.dart';
import 'package:moneypod/models/profile.dart';

void main() {
  group('Profile Model Test', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 'p1',
        'full_name': 'Profile Name',
        'email': 'profile@test.com',
        'avatar_url': 'http://avatar.com',
        'phone': '123456789',
      };

      final profile = Profile.fromJson(json);

      expect(profile.id, 'p1');
      expect(profile.fullName, 'Profile Name');
      expect(profile.email, 'profile@test.com');
      expect(profile.avatarUrl, 'http://avatar.com');
      expect(profile.phone, '123456789');
    });

    test('toJson returns correct map', () {
      final profile = Profile(
        id: 'p1',
        fullName: 'Name',
        email: 'email',
        avatarUrl: 'url',
        phone: 'phone',
      );

      final json = profile.toJson();

      expect(json['id'], 'p1');
      expect(json['full_name'], 'Name');
      expect(json['email'], 'email');
      expect(json['avatar_url'], 'url');
      expect(json['phone'], 'phone');
    });
  });
}
