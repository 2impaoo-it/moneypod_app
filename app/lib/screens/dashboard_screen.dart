import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../main.dart';
import '../bloc/dashboard/dashboard_bloc.dart';
import '../bloc/dashboard/dashboard_state.dart';
import '../bloc/dashboard/dashboard_event.dart';
import '../bloc/settings/settings_cubit.dart';
import '../models/transaction.dart' as model;
import '../widgets/header_widget.dart';
import '../widgets/insight_widget.dart';
import '../models/profile.dart';
import '../utils/popup_notification.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DashboardBloc>().add(DashboardLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );

    return BlocBuilder<SettingsCubit, bool>(
      builder: (context, isBalanceVisible) {
        return BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, state) {
            if (state is DashboardLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is DashboardError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Lỗi: ${state.message}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<DashboardBloc>().add(
                          DashboardLoadRequested(),
                        );
                      },
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              );
            }

            if (state is! DashboardLoaded) {
              return const Center(child: Text('Không có dữ liệu'));
            }

            final dashboardData = state.data;
            final userInfo = dashboardData.userInfo;
            final totalBalance = dashboardData.totalBalance;
            final wallets = dashboardData.wallets;
            final recentTransactions = dashboardData.recentTransactions;

            // Tính tổng thu nhập và chi tiêu từ transactions
            double totalIncome = 0;
            double totalExpense = 0;
            for (var transaction in recentTransactions) {
              if (transaction.isExpense) {
                totalExpense += transaction.amount;
              } else {
                totalIncome += transaction.amount;
              }
            }

            return SafeArea(
              child: RefreshIndicator(
                onRefresh: () async {
                  context.read<DashboardBloc>().add(
                    DashboardRefreshRequested(),
                  );
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- HEADER ---
                      HeaderWidget(
                        profile: Profile(
                          id: userInfo.id,
                          fullName: userInfo.fullName,
                          email: userInfo.email,
                          avatarUrl: userInfo.avatarUrl,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // --- BALANCE CARD ---
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Số dư khả dụng",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    context
                                        .read<SettingsCubit>()
                                        .toggleBalanceVisibility();
                                  },
                                  child: Icon(
                                    isBalanceVisible
                                        ? LucideIcons.eye
                                        : LucideIcons.eyeOff,
                                    color: Colors.white70,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isBalanceVisible
                                  ? currencyFormat.format(totalBalance)
                                  : '******',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                _buildBalanceRowItem(
                                  LucideIcons.arrowDown,
                                  "Thu nhập",
                                  isBalanceVisible
                                      ? currencyFormat.format(totalIncome)
                                      : '******',
                                  AppColors.success,
                                ),
                                const SizedBox(width: 24),
                                _buildBalanceRowItem(
                                  LucideIcons.arrowUp,
                                  "Chi tiêu",
                                  isBalanceVisible
                                      ? currencyFormat.format(totalExpense)
                                      : '******',
                                  AppColors.danger,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Nút xem danh sách ví
                            InkWell(
                              onTap: () async {
                                await context.push('/wallet-list');
                                // Auto-reload when returning
                                if (context.mounted) {
                                  context.read<DashboardBloc>().add(
                                    DashboardRefreshRequested(),
                                  );
                                }
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      LucideIcons.wallet,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Xem tất cả ví (${wallets.length})',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      LucideIcons.chevronRight,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // --- QUICK ACTIONS ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildQuickAction(
                            context,
                            LucideIcons.scanLine,
                            "Quét Bill",
                            onTap: () async {
                              await context.push('/bill-scan');
                              if (context.mounted) {
                                context.read<DashboardBloc>().add(
                                  DashboardRefreshRequested(),
                                );
                              }
                            },
                          ),
                          _buildQuickAction(
                            context,
                            LucideIcons.mic,
                            "Giọng nói",
                          ),
                          _buildQuickAction(
                            context,
                            LucideIcons.arrowRightLeft,
                            "Chuyển tiền",
                            onTap: () async {
                              final result = await context.push(
                                '/transfer-money',
                              );
                              if (result == true && context.mounted) {
                                context.read<DashboardBloc>().add(
                                  DashboardRefreshRequested(),
                                );
                              }
                            },
                          ),
                          _buildQuickAction(
                            context,
                            LucideIcons.wallet,
                            "Thêm ví",
                            onTap: () async {
                              final result = await context.push(
                                '/create-wallet',
                              );
                              if (result == true && context.mounted) {
                                context.read<DashboardBloc>().add(
                                  DashboardRefreshRequested(),
                                );
                                PopupNotification.showSuccess(
                                  context,
                                  'Ví mới đã được tạo!',
                                );
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // --- AI INSIGHT CARD ---
                      const InsightWidget(),
                      const SizedBox(height: 24),

                      // --- SPENDING CHARTS ---
                      if (state.categoryStats.isNotEmpty) ...[
                        const Text(
                          "Phân bổ chi tiêu tháng này",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 200,
                          child: Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: PieChart(
                                  PieChartData(
                                    sectionsSpace: 2,
                                    centerSpaceRadius: 40,
                                    sections: _generatePieSections(
                                      state.categoryStats,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 1,
                                child: SingleChildScrollView(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: _generateLegends(
                                      state.categoryStats,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        const Text(
                          "Phân bổ chi tiêu",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          height: 150,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            "Chưa có dữ liệu chi tiêu tháng này",
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),

                      // --- INCOME CHARTS ---
                      if (state.incomeStats.isNotEmpty) ...[
                        const Text(
                          "Phân bổ thu nhập tháng này",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 200,
                          child: Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: PieChart(
                                  PieChartData(
                                    sectionsSpace: 2,
                                    centerSpaceRadius: 40,
                                    sections: _generatePieSections(
                                      state.incomeStats,
                                      isIncome: true,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 1,
                                child: SingleChildScrollView(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: _generateLegends(
                                      state.incomeStats,
                                      isIncome: true,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),

                      // --- RECENT TRANSACTIONS ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Giao dịch gần đây",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              context.go('/transactions');
                            },
                            child: const Text(
                              "Xem tất cả",
                              style: TextStyle(color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                      ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: recentTransactions.length,
                        itemBuilder: (context, index) {
                          final tx = recentTransactions[index];
                          return _buildTransactionItem(tx, currencyFormat);
                        },
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildBalanceRowItem(
    IconData icon,
    String label,
    String amount,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Text(
              amount,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickAction(
    BuildContext context,
    IconData icon,
    String label, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: AppColors.primaryDark),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // --- HELPER METHODS FOR CHART ---

  List<PieChartSectionData> _generatePieSections(
    Map<String, double> stats, {
    bool isIncome = false,
  }) {
    double total = stats.values.fold(0, (sum, item) => sum + item);
    if (total == 0) return [];

    return stats.entries.map((entry) {
      final percentage = (entry.value / total) * 100;
      final color = isIncome
          ? _getIncomeColor(entry.key)
          : _getColorForCategory(entry.key);
      return PieChartSectionData(
        color: color,
        value: percentage,
        title: '',
        radius: 20,
      );
    }).toList();
  }

  List<Widget> _generateLegends(
    Map<String, double> stats, {
    bool isIncome = false,
  }) {
    double total = stats.values.fold(0, (sum, item) => sum + item);
    if (total == 0) return [];

    return stats.entries.map((entry) {
      final percentage = (entry.value / total) * 100;
      return _ChartLegend(
        color: isIncome
            ? _getIncomeColor(entry.key)
            : _getColorForCategory(entry.key),
        label: entry.key,
        percent: "${percentage.toStringAsFixed(1)}%",
      );
    }).toList();
  }

  Color _getColorForCategory(String category) {
    switch (category) {
      case 'Ăn uống':
        return AppColors.primary;
      case 'Di chuyển':
        return Colors.blue;
      case 'Mua sắm':
        return Colors.pink;
      case 'Giải trí':
        return AppColors.purple;
      case 'Y tế':
        return Colors.red;
      case 'Giáo dục':
        return Colors.orange;
      case 'Hóa đơn':
        return Colors.cyan;
      default:
        return Colors.grey;
    }
  }

  Color _getIncomeColor(String category) {
    switch (category) {
      case 'Lương':
        return Colors.green;
      case 'Thưởng':
        return Colors.teal;
      case 'Đầu tư':
        return Colors.lightGreen;
      case 'Quà tặng':
        return Colors.amber;
      case 'Hoàn tiền':
        return Colors.lime;
      default:
        return Colors.green.shade300;
    }
  }

  Widget _buildTransactionItem(model.Transaction tx, NumberFormat fmt) {
    final style = _getCategoryStyle(tx.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: style.bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(style.icon, color: style.iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      tx.category,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    if (tx.hashtag != null && tx.hashtag != tx.category) ...[
                      const SizedBox(width: 8),
                      Text(
                        tx.hashtag!,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${tx.isExpense ? '-' : '+'}${fmt.format(tx.amount)}",
                style: TextStyle(
                  color: tx.isExpense ? AppColors.danger : AppColors.success,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                DateFormat('dd/MM HH:mm').format(tx.date),
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  _CategoryStyle _getCategoryStyle(String category) {
    final lowerCategory = category.toLowerCase();

    if (lowerCategory.contains('ăn') ||
        lowerCategory.contains('food') ||
        lowerCategory.contains('ăn uống')) {
      return _CategoryStyle(
        bgColor: const Color(0xFFCCFBF1),
        iconColor: const Color(0xFF0D9488),
        icon: LucideIcons.utensils,
      );
    } else if (lowerCategory.contains('di chuyển') ||
        lowerCategory.contains('transport')) {
      return _CategoryStyle(
        bgColor: const Color(0xFFDBEAFE),
        iconColor: const Color(0xFF2563EB),
        icon: LucideIcons.car,
      );
    } else if (lowerCategory.contains('mua sắm') ||
        lowerCategory.contains('shopping')) {
      return _CategoryStyle(
        bgColor: const Color(0xFFFCE7F3),
        iconColor: const Color(0xFFDB2777),
        icon: LucideIcons.shoppingBag,
      );
    } else if (lowerCategory.contains('giải trí') ||
        lowerCategory.contains('entertainment')) {
      return _CategoryStyle(
        bgColor: const Color(0xFFF3E8FF),
        iconColor: const Color(0xFF9333EA),
        icon: LucideIcons.gamepad2,
      );
    } else if (lowerCategory.contains('lương') ||
        lowerCategory.contains('salary')) {
      return _CategoryStyle(
        bgColor: const Color(0xFFDCFCE7),
        iconColor: const Color(0xFF16A34A),
        icon: LucideIcons.wallet,
      );
    } else if (lowerCategory.contains('hóa đơn') ||
        lowerCategory.contains('bill')) {
      return _CategoryStyle(
        bgColor: const Color(0xFFFFEDD5),
        iconColor: const Color(0xFFEA580C),
        icon: LucideIcons.fileText,
      );
    } else if (lowerCategory.contains('sức khỏe') ||
        lowerCategory.contains('health')) {
      return _CategoryStyle(
        bgColor: const Color(0xFFFEE2E2),
        iconColor: const Color(0xFFDC2626),
        icon: LucideIcons.heart,
      );
    }

    return _CategoryStyle(
      bgColor: const Color(0xFFF3F4F6),
      iconColor: const Color(0xFF4B5563),
      icon: LucideIcons.moreHorizontal,
    );
  }
}

class _ChartLegend extends StatelessWidget {
  final Color color;
  final String label;
  final String percent;

  const _ChartLegend({
    required this.color,
    required this.label,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            percent,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _CategoryStyle {
  final Color bgColor;
  final Color iconColor;
  final IconData icon;

  _CategoryStyle({
    required this.bgColor,
    required this.iconColor,
    required this.icon,
  });
}
