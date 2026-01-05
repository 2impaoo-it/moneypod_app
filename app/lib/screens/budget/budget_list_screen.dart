import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';

import '../../main.dart';
import '../../models/budget.dart';
import '../../utils/category_helper.dart';
import '../../bloc/budget/budget_bloc.dart';
import '../../bloc/budget/budget_event.dart';
import '../../bloc/budget/budget_state.dart';
import 'budget_detail_screen.dart';

class BudgetListScreen extends StatefulWidget {
  const BudgetListScreen({super.key});

  @override
  State<BudgetListScreen> createState() => _BudgetListScreenState();
}

class _BudgetListScreenState extends State<BudgetListScreen> {
  late int _currentMonth;
  late int _currentYear;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = now.month;
    _currentYear = now.year;

    // Trigger load
    context.read<BudgetBloc>().add(
      BudgetLoadRequested(month: _currentMonth, year: _currentYear),
    );
  }

  int _daysLeftInMonth() {
    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0);
    return lastDay.day - now.day;
  }

  @override
  Widget build(BuildContext context) {
    final daysLeft = _daysLeftInMonth();

    return Scaffold(
      backgroundColor: const Color(0xFFFCE4EC), // Light pink background
      appBar: AppBar(
        backgroundColor: const Color(0xFFFCE4EC),
        elevation: 0,
        leading: const BackButton(color: AppColors.textPrimary),
        title: Text(
          "Ngân sách",
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.home, color: AppColors.textPrimary),
            onPressed: () => context.go('/report'),
          ),
        ],
      ),
      body: BlocConsumer<BudgetBloc, BudgetState>(
        listener: (context, state) {
          if (state is BudgetOperationSuccess) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
          if (state is BudgetError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.danger,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is BudgetLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          List<Budget> budgets = [];
          if (state is BudgetLoaded) {
            budgets = state.budgets;
          }

          if (budgets.isEmpty && state is BudgetLoaded) {
            return _buildEmptyState();
          }

          final totalBudget = budgets.fold(0.0, (sum, b) => sum + b.amount);
          final totalSpent = budgets.fold(0.0, (sum, b) => sum + b.spent);

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Month Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Tháng $_currentMonth $_currentYear",
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Còn $daysLeft ngày nữa hết tháng",
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: () {
                          // Navigate to create budget
                          context.push('/create-budget');
                        },
                        icon: const Icon(
                          LucideIcons.plus,
                          size: 16,
                          color: Colors.pink,
                        ),
                        label: Text(
                          "Thêm ngân sách",
                          style: GoogleFonts.inter(
                            color: Colors.pink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Total Budget Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Ngân sách tổng",
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(
                              LucideIcons.moreVertical,
                              color: AppColors.textSecondary,
                            ),
                            onSelected: (value) {
                              if (value == 'delete') {
                                _showDeleteAllDialog(context, budgets);
                              }
                            },
                            itemBuilder: (BuildContext context) => [
                              const PopupMenuItem<String>(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      LucideIcons.trash2,
                                      size: 18,
                                      color: AppColors.danger,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Xóa tất cả',
                                      style: TextStyle(color: AppColors.danger),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildHalfCircleChart(
                        spent: totalSpent,
                        total: totalBudget,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatColumn(
                            "Đã chi",
                            totalSpent,
                            AppColors.textPrimary,
                          ),
                          Container(
                            height: 40,
                            width: 1,
                            color: Colors.grey[200],
                          ),
                          _buildStatColumn(
                            "Ngân sách",
                            totalBudget,
                            AppColors.textPrimary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Individual Budget Items
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: budgets.length,
                    itemBuilder: (context, index) {
                      final budget = budgets[index];
                      return _buildBudgetItem(budget, index);
                    },
                  ),
                ),
                // Add padding at bottom to avoid FAB overlap if present
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.piggyBank, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            "Chưa có ngân sách nào",
            style: GoogleFonts.inter(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.push('/create-budget'),
            child: const Text('Tạo ngân sách ngay'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAllDialog(BuildContext context, List<Budget> budgets) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa tất cả ngân sách?'),
        content: Text('Bạn có chắc muốn xóa ${budgets.length} ngân sách?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              for (var budget in budgets) {
                context.read<BudgetBloc>().add(
                  BudgetDeleteRequested(
                    id: budget.id,
                    month: budget.month,
                    year: budget.year,
                  ),
                );
              }
            },
            child: const Text(
              'Xóa tất cả',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHalfCircleChart({required double spent, required double total}) {
    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    );
    // Avoid division by zero
    if (total == 0) total = 1;

    final remaining = total - spent;
    final bool isOverBudget = remaining < 0;
    final Color chartColor = isOverBudget
        ? AppColors.danger
        : AppColors.primary;

    return SizedBox(
      height: 150,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          CustomPaint(
            size: const Size(200, 100),
            painter: HalfCirclePainter(
              spent: spent,
              total: total,
              color: chartColor,
            ),
          ),
          Positioned(
            bottom: 5,
            child: Column(
              children: [
                Text(
                  "Còn lại",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currencyFormat.format(remaining),
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: chartColor,
                  ),
                ),
                if (isOverBudget)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        LucideIcons.alertTriangle,
                        color: AppColors.danger,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "Vượt hạn mức!",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.danger,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, double value, Color color) {
    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    );

    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          currencyFormat.format(value),
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetItem(Budget budget, int index) {
    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    );
    final progress = (budget.spent / budget.amount).clamp(0.0, 1.0);
    final isOverBudget = budget.spent > budget.amount;
    final color = CategoryHelper.getColor(budget.category);
    final bgColor = CategoryHelper.getBackgroundColor(budget.category);

    return Dismissible(
      key: Key(budget.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(LucideIcons.trash2, color: Colors.white, size: 32),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: Text(
                'Xác nhận xóa',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
              content: Text(
                'Bạn có chắc muốn xóa ngân sách "${budget.category}"?',
                style: GoogleFonts.inter(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(
                    'Hủy',
                    style: GoogleFonts.inter(color: AppColors.textSecondary),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: Text(
                    'Xóa',
                    style: GoogleFonts.inter(
                      color: AppColors.danger,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) {
        context.read<BudgetBloc>().add(
          BudgetDeleteRequested(
            id: budget.id,
            month: _currentMonth,
            year: _currentYear,
          ),
        );
      },
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BudgetDetailScreen(budget: budget),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: bgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      CategoryHelper.getIcon(budget.category),
                      color: color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          budget.category,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (isOverBudget)
                          Row(
                            children: [
                              const Icon(
                                LucideIcons.alertTriangle,
                                color: AppColors.danger,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "Vượt hạn mức!",
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.danger,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 4),
                        Text(
                          isOverBudget
                              ? "Vượt hạn mức ${currencyFormat.format(budget.spent - budget.amount)}"
                              : "Còn lại ${currencyFormat.format(budget.amount - budget.spent)}",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: isOverBudget
                                ? AppColors.danger
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currencyFormat.format(budget.amount),
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        "${(progress * 100).toInt()}%",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isOverBudget
                              ? AppColors.danger
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[100],
                  color: isOverBudget ? AppColors.danger : color,
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom Painter for Half Circle Chart
class HalfCirclePainter extends CustomPainter {
  final double spent;
  final double total;
  final Color color;

  HalfCirclePainter({
    required this.spent,
    required this.total,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (total <= 0) return; // Prevent division by zero

    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2;
    final strokeWidth = 30.0;

    // Background arc (gray)
    final bgPaint = Paint()
      ..color = Colors.grey[200]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      3.14, // Start from left (180 degrees)
      3.14, // Draw half circle
      false,
      bgPaint,
    );

    // Progress arc (colored)
    final progress = (spent / total).clamp(0.0, 1.0);
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      3.14, // Start from left
      3.14 * progress, // Draw based on progress
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
