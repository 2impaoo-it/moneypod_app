import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moneypod/screens/groups_screen.dart';
import 'package:moneypod/repositories/group_repository.dart';
import 'package:moneypod/repositories/profile_repository.dart';
import 'package:moneypod/services/auth_service.dart';

class MockGroupRepository extends Mock implements GroupRepository {}

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockAuthService extends Mock implements AuthService {}

void main() {
  late MockGroupRepository mockGroupRepo;
  late MockProfileRepository mockProfileRepo;
  late MockAuthService mockAuthService;

  setUp(() {
    mockGroupRepo = MockGroupRepository();
    mockProfileRepo = MockProfileRepository();
    mockAuthService = MockAuthService();

    when(() => mockAuthService.getToken()).thenAnswer((_) async => 'token');
  });

  testWidgets('GroupsScreen builds', (WidgetTester tester) async {
    // Provide mocks to avoid network calls in initState
    // e.g. _fetchGroups likely calls repo.getGroups
    when(() => mockGroupRepo.getGroups()).thenAnswer((_) async => []);
    when(
      () => mockProfileRepo.fetchUserProfile(any()),
    ).thenAnswer((_) async => null);

    await tester.pumpWidget(
      MaterialApp(
        home: GroupsScreen(
          groupRepository: mockGroupRepo,
          authService: mockAuthService,
        ),
      ),
    );

    expect(find.byType(GroupsScreen), findsOneWidget);
    await tester.pumpAndSettle();
  });
}
