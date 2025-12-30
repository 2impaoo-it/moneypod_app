import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../bloc/savings/savings_bloc.dart';
import '../bloc/savings/savings_event.dart';
import '../bloc/savings/savings_state.dart';
import '../models/savings_goal.dart';
import '../models/wallet.dart';
import '../repositories/savings_repository.dart';
import '../repositories/wallet_repository.dart';
import '../theme/app_colors.dart';

class SavingsDetailScreen extends StatelessWidget {
  final String goalId;

  const SavingsDetailScreen({super.key, required this.goalId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SavingsBloc(SavingsRepository())
        ..add(LoadSavingsGoals()),
      child: SavingsDetailContent(goalId: goalId),
    );
  }
}

class SavingsDetailContent extends StatefulWidget {
  final String goalId;

  const SavingsDetailContent({super.key, required this.goalId});

  @override
  State<SavingsDetailContent> createState() => _SavingsDetailContentState();
}

class _SavingsDetailContentState extends State<SavingsDetailContent> {
  final currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );
  
  final WalletRepository _walletRepository = WalletRepository();
  List<Wallet> _wallets = [];
  bool _walletsLoading = false;
  
  final SavingsRepository _savingsRepository = SavingsRepository();
  List<SavingsTransaction> _transactions = [];
  bool _transactionsLoading = false;
  
  @override
  void initState() {
    super.initState();
    _loadWallets();
    _loadTransactions();
  }
  
  Future<void> _loadWallets() async {
    setState(() => _walletsLoading = true);
    try {
      final wallets = await _walletRepository.getWallets();
      setState(() {
        _wallets = wallets;
        _walletsLoading = false;
      });
    } catch (e) {
      setState(() => _walletsLoading = false);
      print('❌ Lỗi load wallets: $e');
    }
  }
  
  Future<void> _loadTransactions() async {
    setState(() => _transactionsLoading = true);
    try {
      final transactions = await _savingsRepository.getGoalTransactions(widget.goalId);
      setState(() {
        _transactions = transactions;
        _transactionsLoading = false;
      });
    } catch (e) {
      setState(() => _transactionsLoading = false);
      print('❌ Lỗi load transactions: $e');
    }
  }

  Color _getThemeColor(String? colorHex) {
    if (colorHex == null) return const Color(0xFF8B5CF6);
    
    switch (colorHex) {
      case '#3B82F6':
        return const Color(0xFF3B82F6);
      case '#14B8A6':
        return const Color(0xFF14B8A6);
      case '#8B5CF6':
        return const Color(0xFF8B5CF6);
      case '#F97316':
        return const Color(0xFFF97316);
      case '#22C55E':
        return const Color(0xFF22C55E);
      case '#EF4444':
        return const Color(0xFFEF4444);
      case '#EC4899':
        return const Color(0xFFEC4899);
      case '#6366F1':
        return const Color(0xFF6366F1);
      default:
        return const Color(0xFF8B5CF6);
    }
  }

  List<Color> _getThemeGradient(String? colorHex) {
    if (colorHex == null) {
      return [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)];
    }
    
    switch (colorHex) {
      case '#3B82F6':
        return [const Color(0xFF3B82F6), const Color(0xFF2563EB)];
      case '#14B8A6':
        return [const Color(0xFF14B8A6), const Color(0xFF0D9488)];
      case '#8B5CF6':
        return [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)];
      case '#F97316':
        return [const Color(0xFFF97316), const Color(0xFFEA580C)];
      case '#22C55E':
        return [const Color(0xFF22C55E), const Color(0xFF16A34A)];
      case '#EF4444':
        return [const Color(0xFFEF4444), const Color(0xFFDC2626)];
      case '#EC4899':
        return [const Color(0xFFEC4899), const Color(0xFFDB2777)];
      case '#6366F1':
        return [const Color(0xFF6366F1), const Color(0xFF4F46E5)];
      default:
        return [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)];
    }
  }

  IconData _getThemeIcon(String? icon) {
    switch (icon) {
      case 'smartphone':
      case 'phone':
        return LucideIcons.smartphone;
      case 'laptop':
        return LucideIcons.laptop;
      case 'plane':
        return LucideIcons.plane;
      case 'car':
        return LucideIcons.car;
      case 'bike':
        return LucideIcons.bike;
      case 'home':
        return LucideIcons.home;
      case 'heart':
        return LucideIcons.heart;
      case 'gift':
        return LucideIcons.gift;
      case 'shield':
        return LucideIcons.shield;
      case 'trending':
      case 'graduationCap':
        return LucideIcons.trendingUp;
      default:
        return LucideIcons.piggyBank;
    }
  }

  void _showAddMoneyModal(SavingsGoal goal) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    String? selectedWalletId = _wallets.isNotEmpty ? _wallets.first.id : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
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
                    color: AppColors.textMuted.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      LucideIcons.plus,
                      color: AppColors.success,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Thêm tiền',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.blue100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.info,
                      size: 16,
                      color: AppColors.blue500,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Còn thiếu: ${currencyFormat.format(goal.targetAmount - goal.currentAmount)}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_wallets.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.slate300, width: 1),
                  ),
                  child: StatefulBuilder(
                    builder: (context, setModalState) => DropdownButton<String>(
                      value: selectedWalletId,
                      isExpanded: true,
                      underline: const SizedBox(),
                      hint: const Text('Chọn ví'),
                      items: _wallets.map((wallet) => DropdownMenuItem(
                        value: wallet.id,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(wallet.name),
                            Text(
                              currencyFormat.format(wallet.balance),
                              style: const TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )).toList(),
                      onChanged: (value) => setModalState(() => selectedWalletId = value),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: '0',
                  hintStyle: TextStyle(
                    color: AppColors.textMuted.withOpacity(0.5),
                  ),
                  suffixText: '₫',
                  suffixStyle: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: noteController,
                decoration: InputDecoration(
                  hintText: 'Ghi chú (tùy chọn)',
                  hintStyle: TextStyle(
                    color: AppColors.textMuted.withOpacity(0.5),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final amount = double.tryParse(amountController.text);
                    final remaining = goal.targetAmount - goal.currentAmount;
                    
                    if (amount == null || amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Vui lòng nhập số tiền hợp lệ'),
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
                    
                    if (amount > remaining) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Số tiền không được vượt quá số tiền còn thiếu (${currencyFormat.format(remaining)})'),
                          backgroundColor: AppColors.danger,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                      return;
                    }
                    
                    // Kiểm tra số dư ví
                    final selectedWallet = _wallets.firstWhere((w) => w.id == selectedWalletId);
                    if (amount > selectedWallet.balance) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Số dư ví không đủ (${currencyFormat.format(selectedWallet.balance)})'),
                          backgroundColor: AppColors.danger,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                      return;
                    }
                    
                    context.read<SavingsBloc>().add(
                          DepositToGoal(
                            goalId: goal.id,
                            walletId: selectedWalletId!,
                            amount: amount,
                          ),
                        );
                    Navigator.pop(modalContext);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Xác nhận',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showWithdrawModal(SavingsGoal goal) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    String? selectedWalletId = _wallets.isNotEmpty ? _wallets.first.id : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
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
                    color: AppColors.textMuted.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      LucideIcons.minus,
                      color: AppColors.warning,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Rút tiền',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Số dư hiện tại: ',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      currencyFormat.format(goal.currentAmount),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _getThemeColor(goal.color),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_wallets.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.slate300, width: 1),
                  ),
                  child: StatefulBuilder(
                    builder: (context, setModalState) => DropdownButton<String>(
                      value: selectedWalletId,
                      isExpanded: true,
                      underline: const SizedBox(),
                      hint: const Text('Chọn ví nhận tiền'),
                      items: _wallets.map((wallet) => DropdownMenuItem(
                        value: wallet.id,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(wallet.name),
                            Text(
                              currencyFormat.format(wallet.balance),
                              style: const TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )).toList(),
                      onChanged: (value) => setModalState(() => selectedWalletId = value),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: '0',
                  hintStyle: TextStyle(
                    color: AppColors.textMuted.withOpacity(0.5),
                  ),
                  suffixText: '₫',
                  suffixStyle: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.warning,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: noteController,
                decoration: InputDecoration(
                  hintText: 'Lý do rút tiền (tùy chọn)',
                  hintStyle: TextStyle(
                    color: AppColors.textMuted.withOpacity(0.5),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final amount = double.tryParse(amountController.text);
                    
                    if (amount == null || amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Vui lòng nhập số tiền hợp lệ'),
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
                    
                    if (amount > goal.currentAmount) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Số tiền rút không được vượt quá số dư hiện tại (${currencyFormat.format(goal.currentAmount)})'),
                          backgroundColor: AppColors.danger,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                      return;
                    }
                    
                    context.read<SavingsBloc>().add(
                      WithdrawFromGoal(
                        goalId: goal.id,
                        walletId: selectedWalletId!,
                        amount: amount,
                      ),
                    );
                    Navigator.pop(modalContext);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Xác nhận',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOptionsMenu(SavingsGoal goal) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  LucideIcons.edit,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              title: const Text('Chỉnh sửa mục tiêu'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to edit screen
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  LucideIcons.trash2,
                  color: AppColors.danger,
                  size: 20,
                ),
              ),
              title: const Text(
                'Xóa mục tiêu',
                style: TextStyle(color: AppColors.danger),
              ),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmDialog(goal);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(SavingsGoal goal) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(LucideIcons.alertTriangle, color: AppColors.danger),
            SizedBox(width: 10),
            Text('Xác nhận xóa'),
          ],
        ),
        content: Text(
          'Bạn có chắc muốn xóa mục tiêu "${goal.name}"?\n\nHành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext); // Close dialog
              context.read<SavingsBloc>().add(DeleteSavingsGoal(goal.id));
              // Don't navigate here, let BlocListener handle it after deletion
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SavingsBloc, SavingsState>(
      listener: (context, state) {
        if (state is SavingsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.danger,
            ),
          );
        } else if (state is SavingsActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.success,
            ),
          );
          
          // Check if it's delete action by checking if goal still exists
          final goalStillExists = state.goals.any((g) => g.id == widget.goalId);
          if (!goalStillExists) {
            // Goal was deleted, go back to list
            Navigator.pop(context, true); // Return true to trigger refresh
          } else {
            // Other action (deposit/withdraw), reload current screen
            context.read<SavingsBloc>().add(LoadSavingsGoals());
            _loadTransactions(); // Reload transaction history
          }
        } else if (state is SavingsGoalCompleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 3),
            ),
          );
          context.read<SavingsBloc>().add(LoadSavingsGoals());
        }
      },
      builder: (context, state) {
        // Find goal from state
        SavingsGoal? goal;
        if (state is SavingsLoaded) {
          try {
            goal = state.goals.firstWhere((g) => g.id == widget.goalId);
          } catch (e) {
            // Goal not found
          }
        }

        // Loading or not found state
        if (goal == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(LucideIcons.arrowLeft),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        // Calculate values
        final progress = (goal.currentAmount / goal.targetAmount).clamp(0.0, 1.0);
        final remaining = goal.targetAmount - goal.currentAmount;
        final daysLeft = goal.deadline?.difference(DateTime.now()).inDays ?? 0;
        final themeColor = _getThemeColor(goal.color);
        final themeGradient = _getThemeGradient(goal.color);
        final themeIcon = _getThemeIcon(goal.icon);

        return Scaffold(
          backgroundColor: AppColors.background,
          extendBody: false,
          body: CustomScrollView(
            slivers: [
              _buildSliverAppBar(progress, daysLeft, goal, themeColor, themeGradient, themeIcon),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatsSection(progress, remaining, goal, themeColor, daysLeft),
                      const SizedBox(height: 24),
                      _buildTransactionsSection(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: _buildBottomButtons(goal),
        );
      },
    );
  }

  Widget _buildSliverAppBar(
    double progress,
    int daysLeft,
    SavingsGoal goal,
    Color themeColor,
    List<Color> themeGradient,
    IconData themeIcon,
  ) {
    return SliverAppBar(
      expandedHeight: 300,
      floating: false,
      pinned: true,
      backgroundColor: themeColor,
      leading: IconButton(
        icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(LucideIcons.moreVertical, color: Colors.white),
          onPressed: () => _showOptionsMenu(goal),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: themeGradient,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 70, 16, 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      themeIcon,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    goal.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Mục tiêu: ${goal.deadline != null ? DateFormat('dd/MM/yyyy').format(goal.deadline!) : 'Không có'}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 70,
                        height: 70,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 6,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                            Center(
                              child: Text(
                                '${(progress * 100).toInt()}%',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              currencyFormat.format(goal.currentAmount),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '/ ${currencyFormat.format(goal.targetAmount)}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.8),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection(
    double progress,
    double remaining,
    SavingsGoal goal,
    Color themeColor,
    int daysLeft,
  ) {
    // Calculate monthly savings suggestion
    double monthlyAmount = 0;
    String suggestionText = '';
    if (goal.deadline != null && remaining > 0) {
      final now = DateTime.now();
      final deadline = goal.deadline!;
      final monthsLeft = ((deadline.year - now.year) * 12 + deadline.month - now.month).clamp(1, 1000);
      monthlyAmount = remaining / monthsLeft;
      suggestionText = 'Tiết kiệm ${currencyFormat.format(monthlyAmount)}/tháng';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thống kê',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: LucideIcons.target,
                label: 'Còn lại',
                value: currencyFormat.format(remaining),
                color: themeColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: LucideIcons.calendar,
                label: 'Thời gian',
                value: '$daysLeft ngày',
                color: themeColor,
              ),
            ),
          ],
        ),
        if (monthlyAmount > 0) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [themeColor.withOpacity(0.1), themeColor.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: themeColor.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: themeColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(LucideIcons.lightbulb, size: 20, color: themeColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Gợi ý tiết kiệm',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        suggestionText,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: themeColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsSection() {
    if (_transactionsLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lịch sử giao dịch',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }

    if (_transactions.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lịch sử giao dịch',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Column(
                children: [
                  Icon(
                    LucideIcons.history,
                    size: 40,
                    color: AppColors.textMuted,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Chưa có giao dịch nào',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lịch sử giao dịch',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _transactions.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final transaction = _transactions[index];
              final isDeposit = transaction.type.toLowerCase() == 'deposit';
              
              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isDeposit ? AppColors.success : AppColors.warning).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isDeposit ? LucideIcons.plus : LucideIcons.minus,
                    color: isDeposit ? AppColors.success : AppColors.warning,
                    size: 20,
                  ),
                ),
                title: Text(
                  isDeposit ? 'Nạp tiền' : 'Rút tiền',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(transaction.createdAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                trailing: Text(
                  '${isDeposit ? '+' : '-'}${currencyFormat.format(transaction.amount)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDeposit ? AppColors.success : AppColors.warning,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButtons(SavingsGoal goal) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.warning.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () => _showWithdrawModal(goal),
                  icon: const Icon(LucideIcons.minus, size: 20),
                  label: const Text(
                    'Rút tiền',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 80), // Space for FAB in center
            Expanded(
              flex: 4,
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () => _showAddMoneyModal(goal),
                  icon: const Icon(LucideIcons.plus, size: 20),
                  label: const Text(
                    'Thêm tiền',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
