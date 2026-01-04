import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moneypod/screens/create_group_screen.dart';
import 'package:moneypod/services/auth_service.dart';
import 'package:moneypod/repositories/group_repository.dart';
import 'package:moneypod/repositories/profile_repository.dart';
import 'package:moneypod/models/profile.dart';

class MockAuthService extends Mock implements AuthService {}

class MockGroupRepository extends Mock implements GroupRepository {}

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late MockAuthService mockAuthService;
  late MockGroupRepository mockGroupRepository;
  late MockProfileRepository mockProfileRepository;

  setUp(() {
    mockAuthService = MockAuthService();
    mockGroupRepository = MockGroupRepository();
    mockProfileRepository = MockProfileRepository();

    when(() => mockAuthService.getToken()).thenAnswer((_) async => 'token');
    when(
      () => mockProfileRepository.fetchUserProfile(any()),
    ).thenAnswer((_) async => Profile(id: 'user1', fullName: 'User'));
  });

  testWidgets('CreateGroupScreen builds', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CreateGroupScreen(
          authService: mockAuthService,
          groupRepository: mockGroupRepository,
          profileRepository: mockProfileRepository,
        ),
      ),
    );

    expect(find.byType(CreateGroupScreen), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Tạo nhóm mới'), findsOneWidget);
  });
}
