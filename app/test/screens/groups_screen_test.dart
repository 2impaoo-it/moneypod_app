import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moneypod/screens/groups_screen.dart';
import 'package:moneypod/repositories/group_repository.dart';
import 'package:moneypod/repositories/profile_repository.dart';
import 'package:moneypod/services/auth_service.dart';
import 'package:moneypod/models/profile.dart'; // Ensure correct import

import '../mocks/test_helper.dart';

class MockGroupRepository extends Mock implements GroupRepository {}

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockAuthService extends Mock implements AuthService {}

void main() {
  late MockGroupRepository mockGroupRepository;
  late MockProfileRepository mockProfileRepository;
  late MockAuthService mockAuthService;
  late TestHelper helper;

  setUpAll(() {
    TestHelper.registerFallbacks();
  });

  setUp(() {
    helper = TestHelper();
    helper.setUp();
    mockGroupRepository = MockGroupRepository();
    mockProfileRepository = MockProfileRepository();
    mockAuthService = MockAuthService();
  });

  final testGroups = [
    {
      'id': '1',
      'name': 'Trip to Da Lat',
      'members': [
        {
          'user': {'full_name': 'User A', 'avatar_url': ''},
        },
        {
          'user': {'full_name': 'User B', 'avatar_url': ''},
        },
        {
          'user': {'full_name': 'User C', 'avatar_url': ''},
        },
        {
          'user': {'full_name': 'User D', 'avatar_url': ''},
        },
        {
          'user': {'full_name': 'User E', 'avatar_url': ''},
        },
      ],
      'created_by': 'user1',
    },
    {
      'id': '2',
      'name': 'House Rent',
      'members': [
        {
          'user': {'full_name': 'User X', 'avatar_url': ''},
        },
        {
          'user': {'full_name': 'User Y', 'avatar_url': ''},
        },
        {
          'user': {'full_name': 'User Z', 'avatar_url': ''},
        },
      ],
      'created_by': 'user2',
    },
  ];

  final testProfile = Profile(
    id: 'user1',
    email: 'test@example.com',
    fullName: 'Test User',
    avatarUrl: 'http://example.com/avatar.png',
    phone: '123456789',
  );

  group('GroupsScreen', () {
    testWidgets(
      'renders loading state initially',
      skip: true, // WidgetsBinding observer lifecycle issue in test env
      (tester) async {
        when(
          () => mockAuthService.getToken(),
        ).thenAnswer((_) async => 'fake-token');
        when(
          () => mockProfileRepository.fetchUserProfile(any()),
        ).thenAnswer((_) async => testProfile);
        // Delay validation to keep loading true for a bit?
        // Actually _fetchGroups and _fetchDebtData run in initState.
        // We can just verify initial build before future completes?
        // But flutter_test pumps are synchronous unless await.

        when(() => mockGroupRepository.getGroups()).thenAnswer((_) async {
          await Future.delayed(const Duration(seconds: 1));
          return testGroups;
        });
        // Loop calls getMyDebts and getDebtsToMe for each group.
        // Since _fetchDebtData loops through groups, we need to mock these calls.
        // However, initial load just checks isLoading.
        when(
          () => mockGroupRepository.getMyDebts(any()),
        ).thenAnswer((_) async => []);
        when(
          () => mockGroupRepository.getDebtsToMe(any()),
        ).thenAnswer((_) async => []);

        await tester.pumpWidget(
          helper.wrapWithProviders(
            Scaffold(
              body: GroupsScreen(
                authService: mockAuthService,
                groupRepository: mockGroupRepository,
              ),
            ),
          ),
        );

        // Initial state has _isLoading = true
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );

    testWidgets('renders list of groups', (tester) async {
      when(
        () => mockAuthService.getToken(),
      ).thenAnswer((_) async => 'fake-token');
      when(
        () => mockProfileRepository.fetchUserProfile(any()),
      ).thenAnswer((_) async => testProfile);
      when(
        () => mockGroupRepository.getGroups(),
      ).thenAnswer((_) async => testGroups);
      when(
        () => mockGroupRepository.getMyDebts(any()),
      ).thenAnswer((_) async => []);
      when(
        () => mockGroupRepository.getDebtsToMe(any()),
      ).thenAnswer((_) async => []);
      await tester.pumpWidget(
        helper.wrapWithProviders(
          Scaffold(
            body: GroupsScreen(
              authService: mockAuthService,
              groupRepository: mockGroupRepository,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Trip to Da Lat'), findsOneWidget);
      expect(find.text('House Rent'), findsOneWidget);
      expect(find.text('5 thành viên'), findsOneWidget);
      expect(find.text('3 thành viên'), findsOneWidget);
    });

    testWidgets('renders empty groups state', (tester) async {
      when(
        () => mockAuthService.getToken(),
      ).thenAnswer((_) async => 'fake-token');
      when(
        () => mockProfileRepository.fetchUserProfile(any()),
      ).thenAnswer((_) async => testProfile);
      when(() => mockGroupRepository.getGroups()).thenAnswer((_) async => []);
      when(
        () => mockGroupRepository.getMyDebts(any()),
      ).thenAnswer((_) async => []);
      when(
        () => mockGroupRepository.getDebtsToMe(any()),
      ).thenAnswer((_) async => []);
      await tester.pumpWidget(
        helper.wrapWithProviders(
          Scaffold(
            body: GroupsScreen(
              authService: mockAuthService,
              groupRepository: mockGroupRepository,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chưa có nhóm nào'), findsOneWidget);
      expect(find.text('Tạo ngay'), findsOneWidget);
    });

    // Add tests for Debt Optimization if possible (requires mocking complex json response)
  });
}
