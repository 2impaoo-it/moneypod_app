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

// --- IMPORTS MÀN HÌNH & WIDGETS ---
import 'screens/splash_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/transactions_screen.dart';
import 'screens/groups_screen.dart';
import 'screens/savings_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'widgets/add_transaction_modal.dart';
import 'widgets/profile_widget.dart';

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

// --- MAIN APP SETUP ---
void main() {
  // Cấu hình thanh trạng thái trong suốt
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const MoneyPodApp());
}

// Cấu hình Router
final _router = GoRouter(
  initialLocation: '/splash',
  routes: [
    // Splash screen - Kiểm tra server trước
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    // Auth routes (không có bottom nav)
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    // Main app routes (có bottom nav)
    ShellRoute(
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
          path: '/savings',
          builder: (context, state) => const SavingsScreen(),
        ),
        GoRoute(path: '/profile', builder: (context, state) => ProfileWidget()),
      ],
    ),
  ],
);

class MoneyPodApp extends StatelessWidget {
  const MoneyPodApp({super.key});

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
        routerConfig: _router,
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
  void _showAddTransactionModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled:
          true, // Quan trọng: để modal có thể full màn hình nếu cần
      backgroundColor: Colors.transparent,
      builder: (context) => const AddTransactionModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);

    return Scaffold(
      body: widget.child,

      // --- FLOATING ACTION BUTTON (GRADIENT) ---
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark], // Teal Gradient
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
          onPressed: () => _showAddTransactionModal(context),
          backgroundColor: Colors.transparent, // Để lộ Gradient bên dưới
          elevation: 0,
          shape: const CircleBorder(),
          child: const Icon(LucideIcons.plus, color: Colors.white, size: 28),
        ),
      ),

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
                    "Quỹ nhóm",
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
