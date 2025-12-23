import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'screens/dashboard_screen.dart';
import 'screens/transactions_screen.dart'; // Import màn hình Dashboard

// --- MOCK DATA ---
class Transaction {
  final String id;
  final String title;
  final String category;
  final double amount;
  final DateTime date;
  final bool isExpense;
  final String? hashtag;

  Transaction({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    required this.isExpense,
    this.hashtag,
  });
}

final mockTransactions = [
  Transaction(
    id: '1',
    title: 'Cà phê Highland',
    category: 'Ăn uống',
    amount: 55000,
    date: DateTime.now(),
    isExpense: true,
    hashtag: '#caphe',
  ),
  Transaction(
    id: '2',
    title: 'Grab đi làm',
    category: 'Di chuyển',
    amount: 32000,
    date: DateTime.now(),
    isExpense: true,
    hashtag: '#xebus',
  ),
  Transaction(
    id: '3',
    title: 'Lương tháng 1',
    category: 'Lương',
    amount: 25000000,
    date: DateTime.now().subtract(const Duration(days: 1)),
    isExpense: false,
    hashtag: '#luong',
  ),
  Transaction(
    id: '4',
    title: 'Mua áo Uniqlo',
    category: 'Mua sắm',
    amount: 499000,
    date: DateTime.now().subtract(const Duration(days: 2)),
    isExpense: true,
  ),
  Transaction(
    id: '5',
    title: 'Netflix Premium',
    category: 'Giải trí',
    amount: 260000,
    date: DateTime.now().subtract(const Duration(days: 3)),
    isExpense: true,
  ),
];

// --- DESIGN SYSTEM CONSTANTS ---
class AppColors {
  static const primary = Color(0xFF14B8A6); // Teal-500
  static const primaryDark = Color(0xFF0D9488); // Teal-600
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
  runApp(const ProviderScope(child: MoneyPodApp()));
}

// Cấu hình Router
final _router = GoRouter(
  initialLocation: '/',
  routes: [
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
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text("Màn hình Quỹ nhóm"))),
        ),
        GoRoute(
          path: '/savings',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text("Màn hình Tiết kiệm"))),
        ),
      ],
    ),
  ],
);

class MoneyPodApp extends StatelessWidget {
  const MoneyPodApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
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
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme)
            .apply(
              bodyColor: AppColors.textPrimary,
              displayColor: AppColors.textPrimary,
            ),
        useMaterial3: true,
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
  int _selectedIndex = 0;

  void _onItemTapped(int index, BuildContext context) {
    setState(() => _selectedIndex = index);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      floatingActionButton: FloatingActionButton(
        onPressed: () {}, // TODO: Open Add Modal
        backgroundColor: AppColors.primary,
        shape: const CircleBorder(),
        child: const Icon(LucideIcons.plus, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: Colors.white,
        surfaceTintColor: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, LucideIcons.home, "Tổng quan"),
            _buildNavItem(1, LucideIcons.receipt, "Giao dịch"),
            const SizedBox(width: 48), // Khoảng trống cho FAB
            _buildNavItem(2, LucideIcons.users, "Quỹ nhóm"),
            _buildNavItem(3, LucideIcons.piggyBank, "Tiết kiệm"),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => _onItemTapped(index, context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? AppColors.primary : AppColors.textMuted,
            size: 24,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
