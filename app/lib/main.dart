import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

// --- IMPORTS BLOC ---
import 'bloc/auth/auth_bloc.dart';
import 'bloc/auth/auth_event.dart';
import 'bloc/transaction/transaction_bloc.dart';
import 'bloc/transaction/transaction_event.dart';
import 'bloc/dashboard/dashboard_bloc.dart';
import 'bloc/dashboard/dashboard_event.dart';

// --- IMPORTS SERVICES ---
import 'services/auth_service.dart';
import 'utils/session_manager.dart';
import 'utils/popup_notification.dart';

// --- IMPORTS MÀN HÌNH & WIDGETS ---
import 'screens/splash_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/transactions_screen.dart';
import 'screens/groups_screen.dart';
import 'screens/create_group_screen.dart';
import 'screens/group_detail_screen.dart';
import 'screens/savings_screen.dart';
import 'screens/create_savings_goal_screen.dart';
import 'screens/savings_detail_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/profile/change_password_screen.dart';
import 'widgets/add_transaction_modal.dart';
import 'widgets/profile_widget.dart';
import 'screens/add_expense_screen.dart';
import 'screens/create_wallet_screen.dart';
import 'screens/bill_scan_screen.dart';
import 'screens/wallet_list_screen.dart';

// --- DESIGN SYSTEM CONSTANTS ---
class AppColors {
  static const primary = Color(0xFF14B8A6); // Teal-500
  static const primaryDark = Color(0xFF0F766E); // Teal-700
  static const background = Color(0xFFF8FAFC); // Slate-50
  static const cardBg = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF0F172A); // Slate-900
  static const textSecondary = Color(0xFF64748B); // Slate-500
  static const textMuted = Color(0xFF94A3B8); // Slate-400
  static const success = Color(0xFF22C55E); // Green-500
  static const danger = Color(0xFFEF4444); // Red-500
  static const warning = Color(0xFFF59E0B); // Amber-500
  static const purple = Color(0xFF8B5CF6); // Violet-500
}

// Global key for navigation
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> shellNavigatorKey = GlobalKey<NavigatorState>();

// --- MAIN APP SETUP ---
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Cấu hình thanh trạng thái trong suốt
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Kiểm tra session timeout khi khởi động app (trường hợp Kill App rồi mở lại)
  final isSessionExpired = await SessionManager.checkSessionExpired();

  runApp(MoneyPodApp(forceLogin: isSessionExpired));
}

class MoneyPodApp extends StatefulWidget {
  final bool forceLogin;
  const MoneyPodApp({super.key, this.forceLogin = false});

  @override
  State<MoneyPodApp> createState() => _MoneyPodAppState();
}

class _MoneyPodAppState extends State<MoneyPodApp> with WidgetsBindingObserver {
  late GoRouter _appRouter;

  @override
  void initState() {
    super.initState();
    // Đăng ký lắng nghe sự kiện App Lifecycle (ẩn/hiện)
    WidgetsBinding.instance.addObserver(this);

    // Khởi tạo router với initialLocation dựa vào forceLogin
    _appRouter = GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: widget.forceLogin ? '/login' : '/splash',
      routes: [
        // Splash screen - Kiểm tra server trước
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        // Auth routes (không có bottom nav)
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          parentNavigatorKey: rootNavigatorKey,
          path: '/create-wallet',
          builder: (context, state) => const CreateWalletScreen(),
        ),
        GoRoute(
          parentNavigatorKey: rootNavigatorKey,
          path: '/bill-scan',
          builder: (context, state) => const BillScanScreen(),
        ),
        GoRoute(
          parentNavigatorKey: rootNavigatorKey,
          path: '/wallet-list',
          builder: (context, state) => const WalletListScreen(),
        ),
        // Main app routes (có bottom nav)
        ShellRoute(
          navigatorKey: shellNavigatorKey,
          builder: (context, state, child) {
            return MainWrapper(child: child);
          },
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const DashboardScreen(),
            ),
            GoRoute(
              path: '/transactions',
              builder: (context, state) => const TransactionsScreen(),
            ),
            GoRoute(
              path: '/groups',
              builder: (context, state) => const GroupsScreen(),
            ),
            GoRoute(
              path: '/groups/create',
              builder: (context, state) => const CreateGroupScreen(),
            ),
            GoRoute(
              path: '/groups/:id',
              builder: (context, state) {
                final groupId = state.pathParameters['id'] ?? '';
                final extra = state.extra as Map<String, dynamic>?;
                return GroupDetailScreen(
                  groupId: groupId,
                  groupName: extra?['groupName'],
                  inviteCode: extra?['inviteCode'],
                );
              },
            ),
            GoRoute(
              path: '/savings',
              builder: (context, state) => const SavingsScreen(),
            ),
            GoRoute(
              path: '/savings/create',
              builder: (context, state) => const CreateSavingsGoalScreen(),
            ),
            GoRoute(
              path: '/savings/:id',
              builder: (context, state) {
                final goalId = state.pathParameters['id'] ?? '';
                return SavingsDetailScreen(goalId: goalId);
              },
            ),
            GoRoute(
              path: '/profile',
              builder: (context, state) => ProfileWidget(),
            ),
            GoRoute(
              path: '/profile/change-password',
              builder: (context, state) => const ChangePasswordScreen(),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    // Hủy lắng nghe khi đóng app
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // 🔥 HÀM QUAN TRỌNG: Bắt sự kiện App Lifecycle
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('🔔 [AppLifecycle] ====== STATE CHANGED: $state ======');

    if (state == AppLifecycleState.paused) {
      // User ẩn App (bấm Home, chuyển app khác, tắt màn hình) → Lưu thời gian
      print('📱 [AppLifecycle] App going to background - Saving pause time...');
      SessionManager.saveLastActiveTime();
    } else if (state == AppLifecycleState.resumed) {
      // User quay lại App → Kiểm tra timeout
      print('📱 [AppLifecycle] App coming to foreground - Checking session...');
      _checkSessionTimeout();
    } else if (state == AppLifecycleState.inactive) {
      print('📱 [AppLifecycle] App inactive (transitioning)');
    } else if (state == AppLifecycleState.detached) {
      print('📱 [AppLifecycle] App detached');
    }
  }

  Future<void> _checkSessionTimeout() async {
    final isExpired = await SessionManager.checkSessionExpired();
    if (isExpired && mounted) {
      print('⏰ Session hết hạn! Chuyển về màn hình đăng nhập.');
      // Chuyển về màn hình Login
      _appRouter.go('/login');

      // Hiển thị thông báo
      WidgetsBinding.instance.addPostFrameCallback((_) {
        PopupNotification.showError(
          rootNavigatorKey.currentContext ?? context,
          'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              AuthBloc(authService: AuthService())..add(AuthCheckRequested()),
        ),
        BlocProvider(
          create: (context) =>
              TransactionBloc()..add(TransactionLoadRequested()),
        ),
        BlocProvider(
          create: (context) => DashboardBloc()..add(DashboardLoadRequested()),
        ),
      ],
      child: MaterialApp.router(
        title: 'MoneyPod',
        debugShowCheckedModeBanner: false,
        routerConfig: _appRouter,
        theme: ThemeData(
          scaffoldBackgroundColor: AppColors.background,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            primary: AppColors.primary,
            secondary: AppColors.primaryDark,
            background: AppColors.background,
          ),
          // Sử dụng Google Fonts Inter
          textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme)
              .apply(
                bodyColor: AppColors.textPrimary,
                displayColor: AppColors.textPrimary,
              ),
          useMaterial3: true,
        ),
      ),
    );
  }
}

// --- BOTTOM NAVIGATION WRAPPER ---
class MainWrapper extends StatefulWidget {
  final Widget child;
  const MainWrapper({super.key, required this.child});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  // Hàm tính toán index dựa trên URL hiện tại để BottomBar luôn đúng trạng thái
  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/transactions')) return 1;
    if (location.startsWith('/groups')) return 2;
    if (location.startsWith('/savings')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/transactions');
        break;
      case 2:
        context.go('/groups');
        break;
      case 3:
        context.go('/savings');
        break;
    }
  }

  // Hàm mở Modal Thêm Giao Dịch
  void _showAddTransactionModal(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled:
          true, // Quan trọng: để modal có thể full màn hình nếu cần
      backgroundColor: Colors.transparent,
      builder: (context) => const AddTransactionModal(),
    );

    // Nếu thêm giao dịch thành công, reload cả transactions và dashboard
    if (result == true && mounted) {
      context.read<TransactionBloc>().add(TransactionLoadRequested());
      context.read<DashboardBloc>().add(DashboardLoadRequested());
    }
  }

  // Hàm mở màn hình Thêm Chi Tiêu Nhóm
  void _openAddExpenseScreen(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddExpenseScreen()),
    );

    // Nếu thêm chi tiêu thành công, có thể refresh nếu cần
    if (result == true && mounted) {
      // Refresh có thể được xử lý bởi GroupsScreen
    }
  }

  // Kiểm tra xem có nên hiển thị FAB hay không
  bool _shouldShowFAB(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();

    // Ẩn FAB trên các màn hình tạo mới, chi tiết, profile
    if (location.contains('/create')) return false;
    if (location.startsWith('/groups/') && location != '/groups') return false;
    if (location.startsWith('/savings/') && location != '/savings')
      return false;
    if (location.startsWith('/profile')) return false;
    if (location.startsWith('/change-password')) return false;

    return true;
  }

  // Xác định action khi nhấn FAB dựa trên màn hình hiện tại
  void _handleFABPressed(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();

    if (location == '/groups') {
      // Trên màn hình Nhóm chi tiêu -> Thêm chi tiêu nhóm
      _openAddExpenseScreen(context);
    } else {
      // Các màn hình khác -> Thêm giao dịch cá nhân
      _showAddTransactionModal(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);
    final showFAB = _shouldShowFAB(context);

    return Scaffold(
      body: widget.child,

      // --- FLOATING ACTION BUTTON (GRADIENT) ---
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: showFAB
          ? Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primaryDark,
                  ], // Teal Gradient
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FloatingActionButton(
                onPressed: () => _handleFABPressed(context),
                backgroundColor: Colors.transparent, // Để lộ Gradient bên dưới
                elevation: 0,
                shape: const CircleBorder(),
                child: const Icon(
                  LucideIcons.plus,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            )
          : null,

      // --- BOTTOM APP BAR ---
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 10,
        shadowColor: Colors.black.withOpacity(0.1),
        padding: const EdgeInsets.symmetric(horizontal: 0),
        height: 65,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Left Side
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(
                    context,
                    0,
                    LucideIcons.layoutDashboard,
                    "Tổng quan",
                    selectedIndex,
                  ),
                  _buildNavItem(
                    context,
                    1,
                    LucideIcons.receipt,
                    "Giao dịch",
                    selectedIndex,
                  ),
                ],
              ),
            ),

            // Spacer for FAB
            const SizedBox(width: 48),

            // Right Side
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(
                    context,
                    2,
                    LucideIcons.users,
                    "Nhóm",
                    selectedIndex,
                  ),
                  _buildNavItem(
                    context,
                    3,
                    LucideIcons.piggyBank,
                    "Tiết kiệm",
                    selectedIndex,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Widget cho từng Item Navigation
  Widget _buildNavItem(
    BuildContext context,
    int index,
    IconData icon,
    String label,
    int selectedIndex,
  ) {
    final isSelected = selectedIndex == index;
    return InkWell(
      onTap: () => _onItemTapped(index, context),
      customBorder: const CircleBorder(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
