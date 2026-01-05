import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moneypod/models/profile.dart';
import 'package:moneypod/repositories/group_repository.dart';
import 'package:moneypod/repositories/profile_repository.dart';
import 'package:moneypod/services/auth_service.dart';
import 'package:moneypod/screens/group_detail_screen.dart';

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
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: GroupDetailScreen(
        groupId: 'g1',
        groupName: 'Test Group',
        groupRepo: mockGroupRepo,
        profileRepo: mockProfileRepo,
        authService: mockAuthService,
      ),
    );
  }

  final mockProfile = Profile(
    id: 'u1',
    fullName: 'Test User',
    email: 'test@example.com',
    avatarUrl: 'avatars/u1.png',
  );

  final mockGroupData = {
    'id': 'g1',
    'name': 'Test Group',
    'members': [
      {'user_id': 'u1', 'role': 'member'},
    ],
    'creator_id': 'u2',
  };

  testWidgets('renders loading initially and then content', (tester) async {
    // Arrange
    final completer = Completer<Map<String, dynamic>>();

    when(() => mockAuthService.getToken()).thenAnswer((_) async => 'token');
    when(
      () => mockProfileRepo.fetchUserProfile('token'),
    ).thenAnswer((_) async => mockProfile);

    when(
      () => mockGroupRepo.getGroupDetails('g1'),
    ).thenAnswer((_) => completer.future);
    when(() => mockGroupRepo.getMyDebts('g1')).thenAnswer((_) async => []);
    when(() => mockGroupRepo.getDebtsToMe('g1')).thenAnswer((_) async => []);
    when(
      () => mockGroupRepo.getGroupExpenses('g1'),
    ).thenAnswer((_) async => []);

    // Act
    await tester.pumpWidget(createWidgetUnderTest());

    // Assert Loading
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Filter completions
    completer.complete(mockGroupData);
    await tester.pumpAndSettle();

    // Assert Loaded
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Test Group'), findsOneWidget);
    expect(find.text('Tôi nợ'), findsOneWidget);
    expect(find.text('Nợ tôi'), findsOneWidget);
  });
}
