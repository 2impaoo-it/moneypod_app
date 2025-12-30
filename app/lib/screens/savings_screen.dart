import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

import '../bloc/savings/savings_bloc.dart';
import '../bloc/savings/savings_event.dart';
import '../bloc/savings/savings_state.dart';
import '../models/savings_goal.dart';
import '../models/wallet.dart';
import '../repositories/savings_repository.dart';
import '../repositories/wallet_repository.dart';
import '../theme/app_colors.dart';

// Helper format tiền tệ
String formatCurrency(double amount) {
  final formatter = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );
  return formatter.format(amount);
}

final List<Map<String, dynamic>> suggestedGoals = [
  {
    "title": "Quỹ khẩn cấp",
    "description": "Nên có 3-6 tháng chi tiêu",
    "icon": "shield",
  },
  {
    "title": "Quỹ hưu trí",
    "description": "Bắt đầu sớm để hưởng lợi kép",
    "icon": "trending_up",
  },
];

// --- MAIN SCREEN ---
class SavingsScreen extends StatelessWidget {
  const SavingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          SavingsBloc(SavingsRepository())..add(LoadSavingsGoals()),
      child: const SavingsScreenContent(),
    );
  }
}

class SavingsScreenContent extends StatefulWidget {
  const SavingsScreenContent({super.key});

  @override
  State<SavingsScreenContent> createState() => _SavingsScreenContentState();
}

class _SavingsScreenContentState extends State<SavingsScreenContent> {
  Future<void> _onRefresh() async {
    context.read<SavingsBloc>().add(LoadSavingsGoals());
  }

  void _navigateToCreateGoal() async {
    final result = await context.push('/savings/create');
    if (result == true) {
      // Reload danh sách sau khi tạo mới
      if (mounted) {
        context.read<SavingsBloc>().add(LoadSavingsGoals());
      }
    }
  }

  void _navigateToGoalDetail(SavingsGoal goal) async {
    final result = await context.push('/savings/${goal.id}');
    if (result == true && mounted) {
      // Reload danh sách sau khi xóa hoặc cập nhật
      context.read<SavingsBloc>().add(LoadSavingsGoals());
    }
  }

  void _showAddMoneyModal(SavingsGoal goal) async {
    final amountController = TextEditingController();
    final walletRepository = WalletRepository();

    // Load wallets
    List<Wallet> wallets = [];
    try {
      wallets = await walletRepository.getWallets();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể tải danh sách ví: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String? selectedWalletId;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.slate300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Thêm tiền vào "${goal.name}"',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.slate900,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Wallet dropdown
                    DropdownButtonFormField<String>(
                      value: selectedWalletId,
                      decoration: InputDecoration(
                        labelText: 'Chọn ví',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: AppColors.slate50,
                      ),
                      items: wallets.map((wallet) {
                        return DropdownMenuItem<String>(
                          value: wallet.id,
                          child: Text(
                            '${wallet.name} (${NumberFormat('#,###', 'vi_VN').format(wallet.balance)}₫)',
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setModalState(() {
                          selectedWalletId = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        hintText: '0',
                        suffixText: '₫',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: AppColors.slate50,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final amountText = amountController.text.trim();
                          if (amountText.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Vui lòng nhập số tiền'),
                                backgroundColor: AppColors.danger,
                              ),
                            );
                            return;
                          }

                          final amount = double.tryParse(amountText);
                          if (amount == null || amount <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Số tiền phải lớn hơn 0'),
                                backgroundColor: AppColors.danger,
                              ),
                            );
                            return;
                          }

                          if (selectedWalletId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Vui lòng chọn ví'),
                                backgroundColor: AppColors.danger,
                              ),
                            );
                            return;
                          }

                          // Validate wallet balance
                          final selectedWallet = wallets.firstWhere(
                            (w) => w.id == selectedWalletId,
                          );
                          if (selectedWallet.balance < amount) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Số dư ví không đủ'),
                                backgroundColor: AppColors.danger,
                              ),
                            );
                            return;
                          }

                          // Validate amount doesn't exceed remaining target
                          final remaining =
                              goal.targetAmount - goal.currentAmount;
                          if (amount > remaining) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Số tiền vượt quá mục tiêu còn lại (${NumberFormat('#,###', 'vi_VN').format(remaining)}₫)',
                                ),
                                backgroundColor: AppColors.danger,
                              ),
                            );
                            return;
                          }

                          Navigator.pop(ctx);

                          // Dispatch deposit event
                          this.context.read<SavingsBloc>().add(
                            DepositToGoal(
                              goalId: goal.id,
                              walletId: selectedWalletId!,
                              amount: amount,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.teal500,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Xác nhận',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: BlocConsumer<SavingsBloc, SavingsState>(
          listener: (context, state) {
            if (state is SavingsError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            } else if (state is SavingsActionSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.teal500,
                ),
              );
            } else if (state is SavingsGoalCompleted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          },
          builder: (context, state) {
            // Loading state
            if (state is SavingsLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            // Get goals from state
            List<SavingsGoal> goals = [];
            if (state is SavingsLoaded) {
              goals = state.goals;
            } else if (state is SavingsActionSuccess) {
              goals = state.goals;
            } else if (state is SavingsGoalCompleted) {
              goals = state.goals;
            }

            return RefreshIndicator(
              onRefresh: _onRefresh,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Header Section
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Tiết kiệm",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: AppColors.slate900,
                            ),
                          ),
                          InkWell(
                            onTap: _navigateToCreateGoal,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.violet500,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.add,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    "Tạo mục tiêu",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 2. Total Savings Card
                    _buildTotalSavingsCard(goals),

                    // 3. Savings Goals Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Mục tiêu của bạn",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.slate700,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (goals.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.savings_outlined,
                                      size: 64,
                                      color: AppColors.slate300,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Chưa có mục tiêu tiết kiệm',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: AppColors.slate500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Tạo mục tiêu đầu tiên của bạn!',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppColors.slate400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ...goals.map((goal) => _buildSavingsGoalCard(goal)),
                        ],
                      ),
                    ),

                    // 4. Suggested Goals Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          const Text(
                            "Gợi ý cho bạn",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.slate700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...suggestedGoals.map(
                            (sg) => _buildSuggestionCard(sg),
                          ),
                          const SizedBox(height: 40), // Bottom padding
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // --- WIDGET COMPONENTS ---

  // 2. Total Savings Card
  Widget _buildTotalSavingsCard(List<SavingsGoal> goals) {
    // Tính tổng tiết kiệm từ tất cả các mục tiêu
    final double totalSavings = goals.fold(
      0,
      (sum, goal) => sum + goal.currentAmount,
    );

    // Tính tổng mục tiêu
    final double totalTarget = goals.fold(
      0,
      (sum, goal) => sum + goal.targetAmount,
    );

    // Tính phần trăm hoàn thành
    final double percentComplete = totalTarget > 0
        ? (totalSavings / totalTarget * 100)
        : 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.violet500, AppColors.purple600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.violet500.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Tổng tiết kiệm",
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formatCurrency(totalSavings),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.trending_up, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text(
                  "${percentComplete.toStringAsFixed(0)}% hoàn thành",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 3. Savings Goal Card
  Widget _buildSavingsGoalCard(SavingsGoal goal) {
    // Helper lấy màu và icon theo data
    final String? colorKey = goal.color;
    final IconData iconData = _getIconData(goal.icon);

    // Define Color Palette cho item này
    Color bgIconColor;
    Color iconColor;
    Color buttonColor;
    List<Color> gradientColors;

    switch (colorKey) {
      case '#3B82F6': // blue
      case 'blue':
        bgIconColor = AppColors.blue100;
        iconColor = AppColors.blue600;
        buttonColor = AppColors.blue500;
        gradientColors = [AppColors.blue500, AppColors.blue600];
        break;
      case '#14B8A6': // teal
      case 'teal':
        bgIconColor = AppColors.teal100;
        iconColor = AppColors.teal600;
        buttonColor = AppColors.teal500;
        gradientColors = [AppColors.teal500, AppColors.teal600];
        break;
      case '#F97316': // orange
      case 'orange':
        bgIconColor = AppColors.orange100;
        iconColor = AppColors.orange600;
        buttonColor = AppColors.orange600;
        gradientColors = [Colors.orange, AppColors.orange600];
        break;
      case '#EC4899': // pink
      case 'pink':
        bgIconColor = const Color(0xFFFCE7F3);
        iconColor = const Color(0xFFDB2777);
        buttonColor = const Color(0xFFEC4899);
        gradientColors = [const Color(0xFFEC4899), const Color(0xFFDB2777)];
        break;
      case '#22C55E': // green
      case 'green':
        bgIconColor = const Color(0xFFDCFCE7);
        iconColor = const Color(0xFF16A34A);
        buttonColor = const Color(0xFF22C55E);
        gradientColors = [const Color(0xFF22C55E), const Color(0xFF16A34A)];
        break;
      case '#EF4444': // red
      case 'red':
        bgIconColor = const Color(0xFFFEE2E2);
        iconColor = const Color(0xFFDC2626);
        buttonColor = const Color(0xFFEF4444);
        gradientColors = [const Color(0xFFEF4444), const Color(0xFFDC2626)];
        break;
      case '#6366F1': // indigo
      case 'indigo':
        bgIconColor = const Color(0xFFE0E7FF);
        iconColor = const Color(0xFF4F46E5);
        buttonColor = const Color(0xFF6366F1);
        gradientColors = [const Color(0xFF6366F1), const Color(0xFF4F46E5)];
        break;
      default: // Purple
        bgIconColor = AppColors.purple100;
        iconColor = AppColors.purple600;
        buttonColor = AppColors.purple600;
        gradientColors = [AppColors.violet500, AppColors.purple600];
    }

    // Tính toán số liệu
    final double progress = goal.progressPercentage / 100;
    final double remaining = goal.remainingAmount;
    final int percentage = goal.progressPercentage.toInt();

    // Format deadline
    String? deadlineText;
    if (goal.deadline != null) {
      deadlineText = DateFormat('dd/MM/yyyy').format(goal.deadline!);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _navigateToGoalDetail(goal),
          onLongPress: () {
            _showOptionsDialog(context, goal.name);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // a) Header Row
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: bgIconColor,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Icon(iconData, color: iconColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goal.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.slate900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            deadlineText != null
                                ? "Mục tiêu: $deadlineText"
                                : "Chưa có deadline",
                            style: TextStyle(
                              fontSize: 12,
                              color: goal.isOverdue
                                  ? Colors.red
                                  : AppColors.slate500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.more_vert, color: AppColors.slate400),
                  ],
                ),

                // b) Progress Section
                const SizedBox(height: 16),
                // Custom Animated Progress Bar
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return Stack(
                      children: [
                        Container(
                          height: 10,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.slate100,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: value,
                          child: Container(
                            height: 10,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: gradientColors),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formatCurrency(goal.currentAmount),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: buttonColor,
                      ),
                    ),
                    Text(
                      "/ ${formatCurrency(goal.targetAmount)}",
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.slate500,
                      ),
                    ),
                  ],
                ),

                // c) Stats Row
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatItem("Tiến độ", "$percentage%"),
                    _buildStatItem("Còn lại", formatCurrency(remaining)),
                  ],
                ),

                // d) Action Button
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _showAddMoneyModal(goal),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.add, size: 16),
                        SizedBox(width: 4),
                        Text(
                          "Thêm tiền",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.slate400),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.slate700,
          ),
        ),
      ],
    );
  }

  // 4. Suggestion Card
  Widget _buildSuggestionCard(Map<String, dynamic> suggestion) {
    return CustomPaint(
      painter: DashedBorderPainter(color: AppColors.slate300, radius: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.slate50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIconData(suggestion['icon']),
                color: AppColors.teal500,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    suggestion['title'],
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.slate900,
                    ),
                  ),
                  Text(
                    suggestion['description'],
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.slate500,
                    ),
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: _navigateToCreateGoal,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 6,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.teal500),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "Bắt đầu",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.teal600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Maps
  IconData _getIconData(String? name) {
    switch (name) {
      case 'smartphone':
      case 'phone':
        return Icons.smartphone;
      case 'plane':
        return Icons.flight_takeoff;
      case 'bike':
        return Icons.two_wheeler;
      case 'shield':
        return Icons.shield_outlined;
      case 'trending_up':
      case 'trending':
        return Icons.trending_up;
      case 'laptop':
        return Icons.laptop;
      case 'car':
        return Icons.directions_car;
      case 'home':
        return Icons.home;
      case 'graduationCap':
        return Icons.school;
      case 'heart':
        return Icons.favorite;
      case 'gift':
        return Icons.card_giftcard;
      case 'savings':
      default:
        return Icons.savings_outlined;
    }
  }

  // Dialog Options (Long press)
  void _showOptionsDialog(BuildContext context, String title) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit, color: AppColors.slate700),
                title: Text('Chỉnh sửa "$title"'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(
                  'Xóa mục tiêu',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }
}

// --- HELPER CLASSES ---

// Painter vẽ viền nét đứt (Dashed Border)
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;
  final double radius;

  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1,
    this.dashWidth = 5,
    this.dashSpace = 3,
    this.radius = 12,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final Path path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(radius),
        ),
      );

    final Path dashedPath = Path();
    double distance = 0.0;

    // Convert path to metrics to create dashes
    for (final ui.PathMetric metric in path.computeMetrics()) {
      while (distance < metric.length) {
        dashedPath.addPath(
          metric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }
    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
