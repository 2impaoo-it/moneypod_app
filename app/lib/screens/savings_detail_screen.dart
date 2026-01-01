import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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
import '../utils/popup_notification.dart';
import '../utils/currency_formatter.dart';

class SavingsDetailScreen extends StatelessWidget {
  final String goalId;

  const SavingsDetailScreen({super.key, required this.goalId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          SavingsBloc(SavingsRepository())..add(LoadSavingsGoals()),
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

  final SavingsRepository _savingsRepository = SavingsRepository();
  List<SavingsTransaction> _transactions = [];
  bool _transactionsLoading = false;

  Timer? _countdownTimer;
  bool _shouldReload = false;

  @override
  void initState() {
    super.initState();
    _loadWallets();
    _loadTransactions();
    _startCountdownTimer();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdownTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _loadWallets() async {
    try {
      final wallets = await _walletRepository.getWallets();
      setState(() {
        _wallets = wallets;
      });
    } catch (e) {
      print('❌ Lỗi load wallets: $e');
    }
  }

  Future<void> _loadTransactions() async {
    setState(() => _transactionsLoading = true);
    try {
      final transactions = await _savingsRepository.getGoalTransactions(
        widget.goalId,
      );
      setState(() {
        _transactions = transactions;
        _transactionsLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _transactionsLoading = false);
      print('❌ Lỗi load transactions: $e');
    }
  }

  Color _getThemeColor(String? colorHex) {
    if (colorHex == null) return const Color(0xFF8B5CF6);

    // Try to parse hex if it starts with #
    if (colorHex.startsWith('#')) {
      try {
        return Color(int.parse(colorHex.substring(1), radix: 16) + 0xFF000000);
      } catch (_) {}
    }

    switch (colorHex) {
      case 'blue':
        return const Color(0xFF3B82F6);
      case 'teal':
        return const Color(0xFF14B8A6);
      case 'purple':
        return const Color(0xFF8B5CF6);
      case 'orange':
        return const Color(0xFFF97316);
      case 'green':
        return const Color(0xFF22C55E);
      case 'red':
        return const Color(0xFFEF4444);
      case 'pink':
        return const Color(0xFFEC4899);
      case 'indigo':
        return const Color(0xFF6366F1);
      default:
        return const Color(0xFF8B5CF6);
    }
  }

  List<Color> _getThemeGradient(String? colorHex) {
    final baseColor = _getThemeColor(colorHex);
    // Darken the base color slightly for gradient
    final darkColor = HSLColor.fromColor(baseColor)
        .withLightness(
          (HSLColor.fromColor(baseColor).lightness - 0.1).clamp(0.0, 1.0),
        )
        .toColor();
    return [baseColor, darkColor];
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
      builder: (modalContext) => SingleChildScrollView(
        child: Container(
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.slate300, width: 1),
                    ),
                    child: StatefulBuilder(
                      builder: (context, setModalState) =>
                          DropdownButton<String>(
                            value: selectedWalletId,
                            isExpanded: true,
                            underline: const SizedBox(),
                            hint: const Text('Chọn ví'),
                            items: _wallets
                                .map(
                                  (wallet) => DropdownMenuItem(
                                    value: wallet.id,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
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
                                  ),
                                )
                                .toList(),
                            onChanged: (value) =>
                                setModalState(() => selectedWalletId = value),
                          ),
                    ),
                  ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [CurrencyInputFormatter()],
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
                      final amount = CurrencyInputFormatter.parse(
                        amountController.text,
                      );
                      final remaining = goal.targetAmount - goal.currentAmount;

                      if (amount <= 0) {
                        PopupNotification.showError(
                          context,
                          'Vui lòng nhập số tiền hợp lệ',
                        );
                        return;
                      }

                      if (selectedWalletId == null) {
                        PopupNotification.showError(
                          context,
                          'Vui lòng chọn ví',
                        );
                        return;
                      }

                      if (amount > remaining) {
                        PopupNotification.showError(
                          context,
                          'Số tiền không được vượt quá số tiền còn thiếu (${currencyFormat.format(remaining)})',
                        );
                        return;
                      }

                      // Kiểm tra số dư ví
                      final selectedWallet = _wallets.firstWhere(
                        (w) => w.id == selectedWalletId,
                      );
                      if (amount > selectedWallet.balance) {
                        PopupNotification.showError(
                          context,
                          'Số dư ví không đủ (${currencyFormat.format(selectedWallet.balance)})',
                        );
                        return;
                      }

                      context.read<SavingsBloc>().add(
                        DepositToGoal(
                          goalId: goal.id,
                          walletId: selectedWalletId!,
                          amount: amount,
                          note: noteController.text,
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
      builder: (modalContext) => SingleChildScrollView(
        child: Container(
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.slate300, width: 1),
                    ),
                    child: StatefulBuilder(
                      builder: (context, setModalState) =>
                          DropdownButton<String>(
                            value: selectedWalletId,
                            isExpanded: true,
                            underline: const SizedBox(),
                            hint: const Text('Chọn ví nhận tiền'),
                            items: _wallets
                                .map(
                                  (wallet) => DropdownMenuItem(
                                    value: wallet.id,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
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
                                  ),
                                )
                                .toList(),
                            onChanged: (value) =>
                                setModalState(() => selectedWalletId = value),
                          ),
                    ),
                  ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [CurrencyInputFormatter()],
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
                      final amount = CurrencyInputFormatter.parse(
                        amountController.text,
                      );

                      if (amount <= 0) {
                        PopupNotification.showError(
                          context,
                          'Vui lòng nhập số tiền hợp lệ',
                        );
                        return;
                      }

                      if (selectedWalletId == null) {
                        PopupNotification.showError(
                          context,
                          'Vui lòng chọn ví',
                        );
                        return;
                      }

                      if (amount > goal.currentAmount) {
                        PopupNotification.showError(
                          context,
                          'Số tiền rút không được vượt quá số dư hiện tại (${currencyFormat.format(goal.currentAmount)})',
                        );
                        return;
                      }

                      context.read<SavingsBloc>().add(
                        WithdrawFromGoal(
                          goalId: goal.id,
                          walletId: selectedWalletId!,
                          amount: amount,
                          note: noteController.text,
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
              onTap: () async {
                // Capture the parent context and bloc before popping
                final parentContext = this.context;
                final bloc = parentContext.read<SavingsBloc>();

                Navigator.pop(context); // Pop the modal

                // Use the parent context to push, ensuring we stay in the right scope
                final result = await parentContext.push(
                  '/savings/create',
                  extra: goal,
                );

                if (result == true) {
                  _shouldReload = true;
                  bloc.add(LoadSavingsGoals());
                }
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
    if (goal.currentAmount > 0) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(LucideIcons.alertTriangle, color: AppColors.warning),
              SizedBox(width: 10),
              Text('Không thể xóa'),
            ],
          ),
          content: Text(
            'Mục tiêu này đang có số dư ${currencyFormat.format(goal.currentAmount)}.\n\nVui lòng rút hết tiền về ví giao dịch trước khi xóa mục tiêu.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Đã hiểu'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _showWithdrawModal(goal);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: Colors.white,
              ),
              child: const Text('Rút tiền ngay'),
            ),
          ],
        ),
      );
      return;
    }

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
      listener: (context, state) async {
        if (state is SavingsError) {
          PopupNotification.showError(context, state.message);
        } else if (state is SavingsDeleteSuccess) {
          PopupNotification.showSuccess(context, state.message);
          if (context.mounted) {
            Navigator.pop(context, true); // Pop with reload signal
          }
        } else if (state is SavingsActionSuccess) {
          _shouldReload = true;
          PopupNotification.showSuccess(context, state.message);
          await Future.delayed(const Duration(milliseconds: 500));
          if (context.mounted) {
            _loadWallets();
            _loadTransactions();
          }
        } else if (state is SavingsGoalCompleted) {
          _shouldReload = true;
          PopupNotification.showSuccess(context, state.message);
          await Future.delayed(const Duration(milliseconds: 500));
          if (context.mounted) {
            _loadWallets();
            _loadTransactions();
          }
        }
      },
      builder: (context, state) {
        // Find goal from state
        SavingsGoal? goal;
        if (state is SavingsLoaded ||
            state is SavingsActionSuccess ||
            state is SavingsGoalCompleted) {
          // In ActionSuccess, state.goals should have the latest list
          final goals = (state is SavingsLoaded)
              ? state.goals
              : (state is SavingsActionSuccess)
              ? state.goals
              : (state is SavingsGoalCompleted)
              ? state.goals
              : [];
          try {
            goal = goals.firstWhere((g) => g.id == widget.goalId);
          } catch (e) {
            // If not found in list, and we are not deleting, it might be an issue.
            // But if we just deleted, we popped already.
          }
        }

        // Loading or not found state
        if (goal == null) {
          // Try to find in initial state if bloc hasn't loaded yet?
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(
                  LucideIcons.arrowLeft,
                  color: AppColors.textPrimary,
                ),
                onPressed: () => context.pop(),
              ),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        return PopScope(
          canPop: false,
          onPopInvoked: (didPop) {
            if (didPop) return;
            Navigator.pop(context, _shouldReload);
          },
          child: Scaffold(
            backgroundColor: AppColors.background,
            body: BlocBuilder<SavingsBloc, SavingsState>(
              builder: (context, state) {
                // Loading state
                if (state is SavingsLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Get goals from state (loaded from local bloc)
                List<SavingsGoal> goals = [];
                if (state is SavingsLoaded) {
                  goals = state.goals;
                } else if (state is SavingsActionSuccess) {
                  goals = state.goals;
                } else if (state is SavingsGoalCompleted) {
                  goals = state.goals;
                }

                // Find current goal
                final goal = goals.firstWhere(
                  (g) => g.id == widget.goalId,
                  orElse: () => SavingsGoal(
                    id: '',
                    userId: '',
                    name: 'Không tìm thấy',
                    targetAmount: 0,
                    currentAmount: 0,
                    color: '#8B5CF6',
                    icon: 'star',
                    createdAt: DateTime.now(),
                    status: 'ACTIVE',
                    isOverdue: false,
                  ),
                );

                if (goal.id.isEmpty &&
                    state is! SavingsInitial &&
                    state is! SavingsLoading) {
                  return const Center(child: Text('Không tìm thấy mục tiêu'));
                }

                // Helpers
                final themeColor = _getThemeColor(goal.color);
                final themeGradient = _getThemeGradient(goal.color);
                final themeIcon = _getThemeIcon(goal.icon);

                final progress = goal.progressPercentage / 100;
                final remaining = goal.remainingAmount;

                // Calculate Time Left
                String timeText = "Không giới hạn";
                int daysLeft = 0;
                if (goal.deadline != null) {
                  final now = DateTime.now();
                  final diff = goal.deadline!.difference(now);
                  daysLeft = diff.inDays;
                  if (diff.isNegative) {
                    timeText = "Đã quá hạn";
                  } else if (daysLeft == 0) {
                    final hours = diff.inHours;
                    final minutes = diff.inMinutes % 60;
                    final seconds = diff.inSeconds % 60;
                    timeText = "${hours}h ${minutes}p ${seconds}s";
                  } else {
                    timeText = "$daysLeft ngày còn lại";
                  }
                }

                return CustomScrollView(
                  slivers: [
                    _buildSliverAppBar(
                      progress,
                      daysLeft,
                      goal,
                      themeColor,
                      themeGradient,
                      themeIcon,
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildQuickActions(goal),
                            const SizedBox(height: 24),
                            _buildStatsSection(
                              progress,
                              remaining,
                              goal,
                              themeColor,
                              timeText,
                            ),
                            const SizedBox(height: 24),
                            _buildTransactionsSection(),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
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
    // Check if warning is shown to adjust height
    final bool showWarning =
        goal.deadline != null &&
        (DateTime.now().isAfter(goal.deadline!) ||
            DateUtils.isSameDay(DateTime.now(), goal.deadline!)) &&
        progress < 1.0;

    return SliverAppBar(
      expandedHeight: showWarning ? 420.0 : 340.0,
      floating: false,
      pinned: true,
      backgroundColor: themeColor,
      leading: IconButton(
        icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
        onPressed: () => Navigator.pop(context, _shouldReload),
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
              padding: const EdgeInsets.fromLTRB(16, 60, 16, 20),
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
                    child: Icon(themeIcon, size: 32, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    goal.name,
                    style: const TextStyle(
                      fontSize: 22,
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
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (goal.deadline != null &&
                      (DateTime.now().isAfter(goal.deadline!) ||
                          DateUtils.isSameDay(
                            DateTime.now(),
                            goal.deadline!,
                          )) &&
                      progress < 1.0)
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.danger.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            LucideIcons.alertTriangle,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Đã đến ngày mục tiêu',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 8,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                            Center(
                              child: Text(
                                '${(progress * 100).toInt()}%',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              currencyFormat.format(goal.currentAmount),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '/ ${currencyFormat.format(goal.targetAmount)}',
                              style: TextStyle(
                                fontSize: 15,
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

  Widget _buildQuickActions(SavingsGoal goal) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildCircularActionButton(
          icon: LucideIcons.plus,
          label: 'Nạp tiền',
          color: AppColors.success,
          onTap: () => _showAddMoneyModal(goal),
        ),
        _buildCircularActionButton(
          icon: LucideIcons.minus,
          label: 'Rút tiền',
          color: AppColors.warning, // Or Red/Orange
          onTap: () => _showWithdrawModal(goal),
        ),
      ],
    );
  }

  Widget _buildCircularActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: color.withOpacity(0.1)),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection(
    double progress,
    double remaining,
    SavingsGoal goal,
    Color themeColor,
    String timeText,
  ) {
    // Calculate monthly savings suggestion
    double monthlyAmount = 0;
    String suggestionText = '';
    if (goal.deadline != null && remaining > 0) {
      final now = DateTime.now();
      final deadline = goal.deadline!;
      // Simple approximate months calculation
      final monthsLeft =
          ((deadline.year - now.year) * 12 + deadline.month - now.month).clamp(
            1,
            1000,
          );
      monthlyAmount = remaining / monthsLeft;
      suggestionText =
          'Tiết kiệm ${currencyFormat.format(monthlyAmount)}/tháng';
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
                value: timeText,
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
                colors: [
                  themeColor.withOpacity(0.1),
                  themeColor.withOpacity(0.05),
                ],
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
                  child: Icon(
                    LucideIcons.lightbulb,
                    size: 20,
                    color: themeColor,
                  ),
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
                    color: (isDeposit ? AppColors.success : AppColors.warning)
                        .withOpacity(0.1),
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
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat(
                        'dd/MM/yyyy HH:mm',
                      ).format(transaction.createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (transaction.note != null &&
                        transaction.note!.isNotEmpty)
                      Text(
                        transaction.note!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
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
}
