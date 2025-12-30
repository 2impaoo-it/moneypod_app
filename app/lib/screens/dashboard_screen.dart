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
import '../models/transaction.dart' as model;
import '../widgets/header_widget.dart';
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
                    context.read<DashboardBloc>().add(DashboardLoadRequested());
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
              context.read<DashboardBloc>().add(DashboardRefreshRequested());
              // Đợi một chút để UI cập nhật
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
                        const Text(
                          "Số dư khả dụng",
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currencyFormat.format(totalBalance),
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
                              currencyFormat.format(totalIncome),
                              AppColors.success,
                            ),
                            const SizedBox(width: 24),
                            _buildBalanceRowItem(
                              LucideIcons.arrowUp,
                              "Chi tiêu",
                              currencyFormat.format(totalExpense),
                              AppColors.danger,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Nút xem danh sách ví
                        InkWell(
                          onTap: () {
                            context.push('/wallet-list');
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
                        onTap: () {
                          context.push('/bill-scan');
                        },
                      ),
                      _buildQuickAction(context, LucideIcons.mic, "Giọng nói"),
                      _buildQuickAction(
                        context,
                        LucideIcons.arrowRightLeft,
                        "Chuyển tiền",
                      ),
                      _buildQuickAction(
                        context,
                        LucideIcons.wallet,
                        "Thêm ví",
                        onTap: () async {
                          // Mở màn hình tạo ví và chờ kết quả
                          final result = await context.push('/create-wallet');

                          // Nếu tạo thành công (result == true)
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
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: const Border(
                        left: BorderSide(color: AppColors.warning, width: 4),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            LucideIcons.sparkles,
                            color: AppColors.warning,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Insight thông minh",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                "Bạn đã chi tiêu 2tr cho cafe tháng này. Giảm bớt để đạt mục tiêu nhé!",
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- SPENDING CHART ---
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
                                children: _generateLegends(state.categoryStats),
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
                      child: const Text("Chưa có dữ liệu chi tiêu tháng này"),
                    ),
                  ],
                  const SizedBox(height: 24),
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
                  const SizedBox(
                    height: 80,
                  ), // Padding bottom for scrolling above FAB
                ],
              ),
            ),
          ),
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

  List<PieChartSectionData> _generatePieSections(Map<String, double> stats) {
    double total = stats.values.fold(0, (sum, item) => sum + item);
    if (total == 0) return [];

    return stats.entries.map((entry) {
      final percentage = (entry.value / total) * 100;
      final color = _getColorForCategory(entry.key);
      return PieChartSectionData(
        color: color,
        value: percentage,
        title: '',
        radius: 20,
      );
    }).toList();
  }

  List<Widget> _generateLegends(Map<String, double> stats) {
    double total = stats.values.fold(0, (sum, item) => sum + item);
    if (total == 0) return [];

    return stats.entries.map((entry) {
      final percentage = (entry.value / total) * 100;
      return _ChartLegend(
        color: _getColorForCategory(entry.key),
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

  Widget _buildTransactionItem(model.Transaction tx, NumberFormat fmt) {
    // Mapping style based on category
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
        bgColor: const Color(0xFFCCFBF1), // teal-100
        iconColor: const Color(0xFF0D9488), // teal-600
        icon: LucideIcons.utensils,
      );
    } else if (lowerCategory.contains('di chuyển') ||
        lowerCategory.contains('transport')) {
      return _CategoryStyle(
        bgColor: const Color(0xFFDBEAFE), // blue-100
        iconColor: const Color(0xFF2563EB), // blue-600
        icon: LucideIcons.car,
      );
    } else if (lowerCategory.contains('mua sắm') ||
        lowerCategory.contains('shopping')) {
      return _CategoryStyle(
        bgColor: const Color(0xFFFCE7F3), // pink-100
        iconColor: const Color(0xFFDB2777), // pink-600
        icon: LucideIcons.shoppingBag,
      );
    } else if (lowerCategory.contains('giải trí') ||
        lowerCategory.contains('entertainment')) {
      return _CategoryStyle(
        bgColor: const Color(0xFFF3E8FF), // purple-100
        iconColor: const Color(0xFF9333EA), // purple-600
        icon: LucideIcons.gamepad2,
      );
    } else if (lowerCategory.contains('lương') ||
        lowerCategory.contains('salary')) {
      return _CategoryStyle(
        bgColor: const Color(0xFFDCFCE7), // green-100
        iconColor: const Color(0xFF16A34A), // green-600
        icon: LucideIcons.wallet,
      );
    } else if (lowerCategory.contains('hóa đơn') ||
        lowerCategory.contains('bill')) {
      return _CategoryStyle(
        bgColor: const Color(0xFFFFEDD5), // orange-100
        iconColor: const Color(0xFFEA580C), // orange-600
        icon: LucideIcons.fileText,
      );
    } else if (lowerCategory.contains('sức khỏe') ||
        lowerCategory.contains('health')) {
      return _CategoryStyle(
        bgColor: const Color(0xFFFEE2E2), // red-100
        iconColor: const Color(0xFFDC2626), // red-600
        icon: LucideIcons.heart,
      );
    }

    return _CategoryStyle(
      bgColor: const Color(0xFFF3F4F6), // gray-100
      iconColor: const Color(0xFF4B5563), // gray-600
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
