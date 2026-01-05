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

import '../widgets/header_widget.dart';
import '../widgets/insight_widget.dart';
import '../widgets/transaction_item.dart';
import '../widgets/transaction_detail_modal.dart';
import '../models/profile.dart';
import '../utils/popup_notification.dart';
import 'voice_assistant_screen.dart';
import '../models/voice_command.dart';
import '../models/wallet.dart';
import '../repositories/transaction_repository.dart';

import '../services/insight_service.dart'; // Ensure import

class DashboardScreen extends StatefulWidget {
  final InsightService? insightService;

  const DashboardScreen({super.key, this.insightService});

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
                  physics: const AlwaysScrollableScrollPhysics(),
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
                              color: AppColors.primary.withValues(alpha: 0.3),
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
                                InkWell(
                                  onTap: () => context.push('/report'),
                                  child: _buildBalanceRowItem(
                                    LucideIcons.arrowDown,
                                    "Thu nhập",
                                    isBalanceVisible
                                        ? currencyFormat.format(totalIncome)
                                        : '******',
                                    AppColors.success,
                                  ),
                                ),
                                const SizedBox(width: 24),
                                InkWell(
                                  onTap: () => context.push('/report'),
                                  child: _buildBalanceRowItem(
                                    LucideIcons.arrowUp,
                                    "Chi tiêu",
                                    isBalanceVisible
                                        ? currencyFormat.format(totalExpense)
                                        : '******',
                                    AppColors.danger,
                                  ),
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
                                  color: Colors.white.withValues(alpha: 0.2),
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
                            onTap: _openVoiceAssistant,
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
                      InsightWidget(insightService: widget.insightService),
                      const SizedBox(height: 24),

                      // --- SPENDING CHARTS - ENHANCED ---
                      if (state.categoryStats.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Phân bổ chi tiêu",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: const Text(
                                          "Tháng này",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      InkWell(
                                        onTap: () => context.push('/report'),
                                        borderRadius: BorderRadius.circular(20),
                                        child: Padding(
                                          padding: const EdgeInsets.all(4.0),
                                          child: Icon(
                                            LucideIcons.arrowRight,
                                            size: 20,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                height: 220,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    PieChart(
                                      PieChartData(
                                        sectionsSpace: 3,
                                        centerSpaceRadius: 60,
                                        sections: _generatePieSections(
                                          state.categoryStats,
                                        ),
                                        pieTouchData: PieTouchData(
                                          enabled: true,
                                        ),
                                      ),
                                    ),
                                    // Center Total Display
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          LucideIcons.trendingDown,
                                          color: AppColors.danger,
                                          size: 20,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          NumberFormat.compact(
                                            locale: 'vi',
                                          ).format(
                                            state.categoryStats.values.fold(
                                              0.0,
                                              (a, b) => a + b,
                                            ),
                                          ),
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const Text(
                                          "Chi tiêu",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(height: 32),
                              // Enhanced legends with amounts
                              Wrap(
                                spacing: 16,
                                runSpacing: 12,
                                children: _generateEnhancedLegends(
                                  state.categoryStats,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                "Phân bổ chi tiêu",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Container(
                                height: 150,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      LucideIcons.pieChart,
                                      size: 48,
                                      color: Colors.grey.shade300,
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      "Chưa có dữ liệu chi tiêu tháng này",
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),

                      // --- INCOME CHARTS - ENHANCED ---
                      if (state.incomeStats.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Phân bổ thu nhập",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.success.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: const Text(
                                          "Tháng này",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.success,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      InkWell(
                                        onTap: () => context.push('/report'),
                                        borderRadius: BorderRadius.circular(20),
                                        child: Padding(
                                          padding: const EdgeInsets.all(4.0),
                                          child: Icon(
                                            LucideIcons.arrowRight,
                                            size: 20,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                height: 220,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    PieChart(
                                      PieChartData(
                                        sectionsSpace: 3,
                                        centerSpaceRadius: 60,
                                        sections: _generatePieSections(
                                          state.incomeStats,
                                          isIncome: true,
                                        ),
                                        pieTouchData: PieTouchData(
                                          enabled: true,
                                        ),
                                      ),
                                    ),
                                    // Center Total Display
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          LucideIcons.trendingUp,
                                          color: AppColors.success,
                                          size: 20,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          NumberFormat.compact(
                                            locale: 'vi',
                                          ).format(
                                            state.incomeStats.values.fold(
                                              0.0,
                                              (a, b) => a + b,
                                            ),
                                          ),
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const Text(
                                          "Thu nhập",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(height: 32),
                              // Enhanced legends with amounts
                              Wrap(
                                spacing: 16,
                                runSpacing: 12,
                                children: _generateEnhancedLegends(
                                  state.incomeStats,
                                  isIncome: true,
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
                          return TransactionItem(
                            transaction: tx,
                            onTap: () =>
                                TransactionDetailModal.show(context, tx),
                          );
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
            color: Colors.white.withValues(alpha: 0.2),
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
                  color: Colors.black.withValues(alpha: 0.05),
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
        title: percentage >= 10 ? '${percentage.toInt()}%' : '',
        titleStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        radius: 35,
        titlePositionPercentageOffset: 0.55,
      );
    }).toList();
  }

  // Enhanced legends with colored dots, labels, and amounts
  List<Widget> _generateEnhancedLegends(
    Map<String, double> stats, {
    bool isIncome = false,
  }) {
    double total = stats.values.fold(0, (sum, item) => sum + item);
    if (total == 0) return [];
    if (total == 0) return [];

    return stats.entries.map((entry) {
      final percentage = (entry.value / total) * 100;
      final color = isIncome
          ? _getIncomeColor(entry.key)
          : _getColorForCategory(entry.key);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              entry.key,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '${percentage.toInt()}%',
              style: TextStyle(
                fontSize: 11,
                color: color.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
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

  Future<void> _openVoiceAssistant() async {
    List<Wallet>? wallets;
    final state = context.read<DashboardBloc>().state;
    if (state is DashboardLoaded) {
      wallets = state.data.wallets;
    }

    final command = await showModalBottomSheet<VoiceCommand>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VoiceAssistantScreen(preloadedWallets: wallets),
    );

    if (command != null && mounted) {
      await _executeVoiceCommand(command);
    }
  }

  Future<void> _executeVoiceCommand(VoiceCommand command) async {
    try {
      final repository = context.read<TransactionRepository>();
      final state = context.read<DashboardBloc>().state;
      String? walletId = command.walletId;

      if (walletId == null &&
          state is DashboardLoaded &&
          state.data.wallets.isNotEmpty) {
        // Fallback to first wallet if not selected
        walletId = state.data.wallets.first.id;
      }

      if (walletId == null) {
        if (mounted) {
          PopupNotification.showError(
            context,
            'Vui lòng tạo ví trước khi sử dụng tính năng này',
          );
        }
        return;
      }

      switch (command.type) {
        case 'expense':
        case 'income':
          await repository.createTransaction(
            walletId: walletId,
            amount: command.amount,
            category: command.category ?? 'Khác',
            type: command.type,
            note: command.note ?? '',
          );

          if (mounted) {
            PopupNotification.showSuccess(
              context,
              'Đã thêm ${command.type == 'expense' ? 'chi tiêu' : 'thu nhập'} thành công',
            );
            // Refresh dashboard
            context.read<DashboardBloc>().add(DashboardRefreshRequested());
          }
          break;

        case 'transfer':
          if (mounted) {
            PopupNotification.showInfo(
              context,
              'Tính năng chuyển tiền giọng nói đang phát triển',
            );
          }
          break;

        case 'query':
          if (mounted) {
            PopupNotification.showInfo(
              context,
              'Tính năng hỏi đáp đang phát triển',
            );
          }
          break;
      }
    } catch (e) {
      if (mounted) {
        PopupNotification.showError(context, 'Lỗi: $e');
      }
    }
  }
}
