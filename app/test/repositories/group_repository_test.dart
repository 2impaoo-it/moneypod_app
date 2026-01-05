import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:moneypod/services/auth_service.dart';
import 'package:moneypod/repositories/group_repository.dart';

class MockDio extends Mock implements Dio {}

class MockAuthService extends Mock implements AuthService {}

void main() {
  late MockDio mockDio;
  late MockAuthService mockAuthService;
  late GroupRepository groupRepository;

  setUp(() {
    mockDio = MockDio();
    mockAuthService = MockAuthService();

    // Default Dio options mock handled inside repository constructor

    groupRepository = GroupRepository(
      dio: mockDio,
      authService: mockAuthService,
    );
  });

  group('GroupRepository', () {
    test('createGroup sends correct request', () async {
      // Arrange
      when(
        () => mockAuthService.getToken(),
      ).thenAnswer((_) async => 'fake_token');

      when(
        () => mockDio.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/groups'),
          statusCode: 200,
          data: {
            'data': {'id': '123', 'invite_code': 'ABC', 'name': 'Test Group'},
          },
        ),
      );

      // Act
      final result = await groupRepository.createGroup(name: 'Test Group');

      // Assert
      expect(result['id'], '123');
      expect(result['invite_code'], 'ABC');
      verify(() => mockAuthService.getToken()).called(1);
      verify(
        () => mockDio.post(
          '/groups',
          data: {'name': 'Test Group', 'members': []},
          options: any(named: 'options'),
        ),
      ).called(1);
    });
  });
}
