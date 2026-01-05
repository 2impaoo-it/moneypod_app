import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moneypod/screens/add_expense_screen.dart';
import 'package:moneypod/repositories/group_repository.dart';
import 'package:moneypod/repositories/profile_repository.dart';
import 'package:moneypod/services/auth_service.dart';
import 'package:moneypod/models/profile.dart'; // Ensure Profile is imported

// Create Mocks
class MockGroupRepository extends Mock implements GroupRepository {}

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockAuthService extends Mock implements AuthService {}

void main() {
  late MockGroupRepository mockGroupRepository;
  late MockProfileRepository mockProfileRepository;
  late MockAuthService mockAuthService;

  setUpAll(() {
    // Register fallbacks if necessary, e.g. for addExpense arguments
    // registerFallbackValue(...);
  });

  setUp(() {
    mockGroupRepository = MockGroupRepository();
    mockProfileRepository = MockProfileRepository();
    mockAuthService = MockAuthService();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: AddExpenseScreen(
        groupRepository: mockGroupRepository,
        profileRepository: mockProfileRepository,
        authService: mockAuthService,
      ),
    );
  }

  group('AddExpenseScreen', () {
    testWidgets('renders initial form correctly', (tester) async {
      // Setup default mock responses to avoid errors on init
      when(
        () => mockAuthService.getToken(),
      ).thenAnswer((_) async => 'fake_token');
      when(() => mockGroupRepository.getGroups()).thenAnswer((_) async => []);
      when(() => mockProfileRepository.fetchUserProfile(any())).thenAnswer(
        (_) async =>
            Profile(id: '1', fullName: 'Test User', email: 'test@test.com'),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Thêm chi tiêu nhóm'), findsOneWidget);
      expect(find.text('Số tiền'), findsOneWidget);
      expect(find.text('Nội dung'), findsOneWidget);
      expect(find.text('Nhóm'), findsOneWidget);
      // 'Người trả tiền' only appears if group selected & members loaded
      expect(find.text('Người trả tiền'), findsNothing);
    });

    /*
    testWidgets('validates empty input', (tester) async {
      when(
        () => mockAuthService.getToken(),
      ).thenAnswer((_) async => 'fake_token');
      when(() => mockGroupRepository.getGroups()).thenAnswer((_) async => []);
      when(
        () => mockProfileRepository.fetchUserProfile(any()),
      ).thenAnswer((_) async => null);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final buttonFinder = find.widgetWithText(ElevatedButton, 'Lưu chi tiêu');

      // Ensure button is visible by scrolling
      await tester.scrollUntilVisible(
        buttonFinder,
        500.0,
        scrollable: find.byType(SingleChildScrollView),
      );
      await tester.pumpAndSettle();

      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      // Check for Dialog
      expect(find.byType(Dialog), findsOneWidget);
      // Use icon finder as text might be rich or formatted differently
      // expect(find.text('Vui lòng nhập số tiền'), findsOneWidget);
      // Popup uses LucideIcons.alertCircle for error
      // But we need to ensure LucideIcons is available or matched by IconCode?
      // Just check for 'Lỗi' title or similar?
      expect(find.text('Lỗi'), findsOneWidget);

      // Close dialog
      await tester.tap(find.text('Đóng'));
      await tester.pumpAndSettle();
    });

    testWidgets('submits valid data', (tester) async {
      when(
        () => mockAuthService.getToken(),
      ).thenAnswer((_) async => 'fake_token');
      // Have one group to select
      when(() => mockGroupRepository.getGroups()).thenAnswer(
        (_) async => [
          {'id': 'g1', 'name': 'Group 1'},
        ],
      );
      when(
        () => mockGroupRepository.getGroupDetails('g1'),
      ).thenAnswer((_) async => {'members': []}); // Mock members
      when(() => mockProfileRepository.fetchUserProfile(any())).thenAnswer(
        (_) async => Profile(id: 'u1', fullName: 'User 1', email: 'e1'),
      );
      when(
        () => mockGroupRepository.addExpense(
          groupId: any(named: 'groupId'),
          amount: any(named: 'amount'),
          description: any(named: 'description'),
          payerId: any(named: 'payerId'),
          imageUrl: any(named: 'imageUrl'),
          splitDetails: any(named: 'splitDetails'),
        ),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Select group (if not pre-selected)
      // Tap dropdown to select 'Group 1'
      // Dropdown finder is tricky. find.text('Chọn nhóm').
      await tester.tap(find.text('Chọn nhóm'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Group 1').last);
      await tester.pumpAndSettle();

      // Enter amount
      // Find TextField with '0 ₫'.
      await tester.enterText(find.byType(TextField).first, '50000');
      await tester.pumpAndSettle();

      // Enter description
      await tester.enterText(
        find.widgetWithText(TextField, 'Ví dụ: Ăn trưa, xem phim...'),
        'Lunch',
      );
      await tester.pumpAndSettle();

      // Tap Save
      final buttonFinder = find.widgetWithText(ElevatedButton, 'Lưu chi tiêu');
      await tester.scrollUntilVisible(
        buttonFinder,
        500,
        scrollable: find.byType(SingleChildScrollView),
      );
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      // Verify success dialog
      expect(find.text('Thành công'), findsOneWidget);
      expect(find.text('✅ Đã thêm chi tiêu thành công!'), findsOneWidget);

      verify(
        () => mockGroupRepository.addExpense(
          groupId: 'g1',
          amount: 50000,
          description: 'Lunch',
          payerId: 'u1', // defaults to current user
          imageUrl: null,
          splitDetails: [], // empty members
        ),
      ).called(1);
    });
*/
  });
}
