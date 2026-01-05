import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:moneypod/repositories/profile_repository.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late ProfileRepository repository;

  setUp(() {
    mockDio = MockDio();
    repository = ProfileRepository(dio: mockDio);
  });

  group('ProfileRepository', () {
    test('fetchUserProfile returns profile on success', () async {
      when(
        () => mockDio.get('/profile', options: any(named: 'options')),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/profile'),
          statusCode: 200,
          data: {
            'data': {
              'id': 'p1',
              'full_name': 'Test User',
              'email': 'test@test.com',
            },
          },
        ),
      );

      final profile = await repository.fetchUserProfile('token');

      expect(profile, isNotNull);
      expect(profile!.fullName, 'Test User');
    });

    test('fetchUserProfile returns null on error', () async {
      when(
        () => mockDio.get('/profile', options: any(named: 'options')),
      ).thenThrow(
        DioException(requestOptions: RequestOptions(path: '/profile')),
      );

      final profile = await repository.fetchUserProfile('token');

      expect(profile, isNull);
    });
  });
}
