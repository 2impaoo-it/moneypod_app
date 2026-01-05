import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../main.dart';
import '../../models/budget.dart';
import '../../models/transaction.dart' as model;
import '../../utils/category_helper.dart';
import '../../bloc/transaction/transaction_bloc.dart';
import '../../bloc/transaction/transaction_state.dart';
import '../../bloc/budget/budget_bloc.dart';
import '../../bloc/budget/budget_event.dart';
import '../../bloc/budget/budget_state.dart';

class BudgetDetailScreen extends StatefulWidget {
  final Budget budget;

  const BudgetDetailScreen({super.key, required this.budget});

  @override
  State<BudgetDetailScreen> createState() => _BudgetDetailScreenState();
}

class _BudgetDetailScreenState extends State<BudgetDetailScreen> {
  @override
  void initState() {
    super.initState();
  }

  int _daysLeftInMonth() {
    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0);
    return lastDay.day - now.day;
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
          'Bạn có chắc muốn xóa ngân sách "${widget.budget.category}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<BudgetBloc>().add(
                BudgetDeleteRequested(
                  id: widget.budget.id,
                  month: widget.budget.month,
                  year: widget.budget.year,
                ),
              );
            },
            child: const Text('Xóa', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  void _showEditBudgetDialog() {
    final controller = TextEditingController(
      text: widget.budget.amount.toInt().toString(),
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Chỉnh sửa ngân sách'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Số tiền mới',
                suffixText: 'đ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              final newAmount = double.tryParse(controller.text);
              if (newAmount != null && newAmount > 0) {
                Navigator.pop(ctx);
                context.read<BudgetBloc>().add(
                  BudgetUpdateRequested(
                    id: widget.budget.id,
                    amount: newAmount,
                    month: widget.budget.month,
                    year: widget.budget.year,
                  ),
                );
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    );

    final double remaining = widget.budget.remaining;
    final double spent = widget.budget.spent;
    final now = DateTime.now();
    final daysLeft = _daysLeftInMonth();

    return Scaffold(
      backgroundColor: const Color(0xFFFCE4EC), // Light pink background
      appBar: AppBar(
        backgroundColor: const Color(0xFFFCE4EC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Ngân sách",
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
      ),
      body: BlocListener<BudgetBloc, BudgetState>(
        listener: (context, state) {
          if (state is BudgetOperationSuccess) {
            Navigator.pop(
              context,
            ); // Close detail screen on success (delete/update)
            // If it was update, we might want to stay but reload?
            // For now pop is safer to refresh list.
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
        child: SingleChildScrollView(
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
                          "Tháng ${now.month} ${now.year}",
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

              // Budget Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
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
                          widget.budget.category,
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
                            if (value == 'edit') {
                              _showEditBudgetDialog();
                            } else if (value == 'delete') {
                              _confirmDelete();
                            }
                          },
                          itemBuilder: (BuildContext context) => [
                            const PopupMenuItem<String>(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(LucideIcons.pencil, size: 18),
                                  SizedBox(width: 8),
                                  Text('Chỉnh sửa'),
                                ],
                              ),
                            ),
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
                                    'Xóa',
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
                      spent: spent,
                      total: widget.budget.amount,
                      remaining: remaining,
                      currencyFormat: currencyFormat,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildStatColumn(
                              "Đã chi",
                              currencyFormat.format(spent),
                            ),
                          ),
                          Container(
                            height: 40,
                            width: 1,
                            color: Colors.grey[300],
                          ),
                          Expanded(
                            child: _buildStatColumn(
                              "Ngân sách",
                              currencyFormat.format(widget.budget.amount),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Transaction List Section
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        "Chi tiết giao dịch",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    _buildTransactionList(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ), // Column
        ), // SingleChildScrollView
      ), // BlocListener
    ); // Scaffold
  } // build

  Widget _buildHalfCircleChart({
    required double spent,
    required double total,
    required double remaining,
    required NumberFormat currencyFormat,
  }) {
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
            size: const Size(240, 120),
            painter: HalfCirclePainter(
              spent: spent,
              total: total,
              color: chartColor,
            ),
          ),
          Positioned(
            bottom: 10,
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
                    fontSize: 22,
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

  Widget _buildStatColumn(String label, String value) {
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
          value,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionList() {
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        if (state is! TransactionLoaded) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Filter transactions by budget category and current month/year
        final filteredTransactions = state.transactions.where((t) {
          return t.category == widget.budget.category &&
              t.date.month == widget.budget.month &&
              t.date.year == widget.budget.year &&
              t.type == 'expense';
        }).toList();

        // Sort by date descending
        filteredTransactions.sort((a, b) => b.date.compareTo(a.date));

        if (filteredTransactions.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(LucideIcons.receipt, size: 48, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  Text(
                    "Chưa có giao dịch cho danh mục này",
                    style: GoogleFonts.inter(color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: filteredTransactions.length,
          itemBuilder: (context, index) {
            final transaction = filteredTransactions[index];
            return _buildTransactionItem(transaction);
          },
        );
      },
    );
  }

  Widget _buildTransactionItem(model.Transaction transaction) {
    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    );

    return InkWell(
      onTap: () => _showTransactionDetail(transaction),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: CategoryHelper.getBackgroundColor(transaction.category),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                CategoryHelper.getIcon(transaction.category),
                color: CategoryHelper.getColor(transaction.category),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title.isNotEmpty
                        ? transaction.title
                        : transaction.category,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('HH:mm - dd/MM/yyyy').format(transaction.date),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              "-${currencyFormat.format(transaction.amount)}",
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.danger,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Hiển thị chi tiết transaction
  void _showTransactionDetail(model.Transaction tx) {
    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );
    final isExpense = tx.isExpense;
    final categoryColor = CategoryHelper.getColor(tx.category);
    final backgroundColor = CategoryHelper.getBackgroundColor(tx.category);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Icon(
                    CategoryHelper.getIcon(tx.category),
                    color: categoryColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx.category,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(tx.date),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(LucideIcons.x),
                ),
              ],
            ),

            const Divider(height: 32),

            // Transaction Info
            _buildDetailRow(
              'Loại giao dịch',
              isExpense ? 'Chi tiêu' : 'Thu nhập',
            ),
            _buildDetailRow('Danh mục', tx.category),
            _buildDetailRow(
              'Số tiền',
              "${isExpense ? '-' : '+'}${currencyFormat.format(tx.amount.abs())}",
              valueColor: isExpense ? AppColors.danger : AppColors.success,
            ),
            if (tx.title.isNotEmpty) _buildDetailRow('Ghi chú', tx.title),
            if (tx.walletName != null) _buildDetailRow('Ví', tx.walletName!),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
          ),
        ],
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
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
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
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      3.14, // Start from left
      3.14 * progress, // Draw based on progress
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
