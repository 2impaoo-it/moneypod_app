import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moneypod/models/profile.dart';
import 'package:moneypod/services/profile_service.dart';
import 'package:moneypod/repositories/profile_repository.dart';

class MockDio extends Mock implements Dio {}

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockResponse<T> extends Mock implements Response<T> {}

void main() {
  late ProfileService profileService;
  late MockDio mockDio;
  late MockProfileRepository mockRepo;

  setUp(() {
    mockDio = MockDio();
    mockRepo = MockProfileRepository();
    // Inject mocks
    profileService = ProfileService(mockRepo, mockDio);
  });

  group('ProfileService', () {
    const token = 'test-token';
    final profile = Profile(id: '1', fullName: 'Test', email: 'test@test.com');

    test('getUserProfile calls repository', () async {
      when(
        () => mockRepo.fetchUserProfile(token),
      ).thenAnswer((_) async => profile);

      final result = await profileService.getUserProfile(token);

      verify(() => mockRepo.fetchUserProfile(token)).called(1);
      expect(result, profile);
    });

    test('getUserProfile returns null on error', () async {
      when(
        () => mockRepo.fetchUserProfile(token),
      ).thenThrow(Exception('Error'));

      final result = await profileService.getUserProfile(token);

      expect(result, null);
    });

    test('updateUserProfile calls API and returns updated profile', () async {
      final updates = {'full_name': 'New Name'};
      final response = MockResponse<Map<String, dynamic>>();

      when(() => response.statusCode).thenReturn(200);
      when(() => response.data).thenReturn({
        'data': {'id': '1', 'full_name': 'New Name', 'email': 'test@test.com'},
      });

      when(
        () => mockDio.put(
          '/profile',
          data: updates,
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => response);

      final result = await profileService.updateUserProfile(token, updates);

      expect(result?.fullName, 'New Name');
    });

    test('updatePhoneNumber success', () async {
      final response = MockResponse();
      when(() => response.statusCode).thenReturn(200);

      when(
        () => mockDio.post(
          '/profile/phone',
          data: {'phone': '123456789'},
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => response);

      await expectLater(
        profileService.updatePhoneNumber(token, '123456789'),
        completes,
      );
    });
  });
}
