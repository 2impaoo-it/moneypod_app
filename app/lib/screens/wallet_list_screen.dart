import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../bloc/wallet_list/wallet_list_bloc.dart';
import '../bloc/wallet_list/wallet_list_event.dart';
import '../bloc/wallet_list/wallet_list_state.dart';
import '../bloc/settings/settings_cubit.dart';
import '../models/wallet.dart';
import '../repositories/wallet_repository.dart';
import '../main.dart';
import '../utils/popup_notification.dart';
import 'transactions_screen.dart';

class WalletListScreen extends StatelessWidget {
  const WalletListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          WalletListBloc(walletRepository: WalletRepository())
            ..add(const LoadWalletList()),
      child: const _WalletListView(),
    );
  }
}

class _WalletListView extends StatefulWidget {
  const _WalletListView();

  @override
  State<_WalletListView> createState() => _WalletListViewState();
}

class _WalletListViewState extends State<_WalletListView> {
  // Use SettingsCubit for global state

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, bool>(
      builder: (context, isBalanceVisible) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                LucideIcons.arrowLeft,
                color: AppColors.textPrimary,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Danh sách ví',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  isBalanceVisible ? LucideIcons.eye : LucideIcons.eyeOff,
                  color: AppColors.textPrimary,
                ),
                onPressed: () {
                  context.read<SettingsCubit>().toggleBalanceVisibility();
                },
              ),
              IconButton(
                icon: const Icon(
                  LucideIcons.refreshCw,
                  color: AppColors.primary,
                ),
                onPressed: () {
                  context.read<WalletListBloc>().add(const RefreshWalletList());
                },
              ),
            ],
          ),
          body: BlocConsumer<WalletListBloc, WalletListState>(
            listener: (context, state) {
              if (state.status == WalletStatus.failure &&
                  state.errorMessage != null) {
                PopupNotification.showError(context, state.errorMessage!);
              }
            },
            builder: (context, state) {
              if (state.status == WalletStatus.loading &&
                  state.wallets.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                );
              }

              if (state.status == WalletStatus.failure &&
                  state.wallets.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          LucideIcons.alertCircle,
                          size: 64,
                          color: AppColors.danger,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Có lỗi xảy ra',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.errorMessage ?? 'Lỗi không xác định',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            context.read<WalletListBloc>().add(
                              const LoadWalletList(),
                            );
                          },
                          icon: const Icon(LucideIcons.refreshCw, size: 20),
                          label: const Text('Thử lại'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (state.wallets.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.wallet,
                          size: 64,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Chưa có ví nào',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tạo ví đầu tiên để bắt đầu',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  context.read<WalletListBloc>().add(const RefreshWalletList());
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.wallets.length,
                  itemBuilder: (context, index) {
                    final wallet = state.wallets[index];
                    return _WalletCard(
                      wallet: wallet,
                      isBalanceVisible: isBalanceVisible,
                      walletListBloc: context.read<WalletListBloc>(),
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _WalletCard extends StatelessWidget {
  final Wallet wallet;
  final bool isBalanceVisible;
  final WalletListBloc walletListBloc;

  const _WalletCard({
    required this.wallet,
    required this.isBalanceVisible,
    required this.walletListBloc,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cardColor, cardColor.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cardColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TransactionsScreen(walletId: wallet.id),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            LucideIcons.wallet,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          wallet.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(
                        LucideIcons.moreVertical,
                        color: Colors.white,
                      ),
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showEditSheet(context);
                        } else if (value == 'delete') {
                          _showDeleteSheet(context);
                        }
                      },
                      itemBuilder: (BuildContext context) => [
                        const PopupMenuItem<String>(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.edit3,
                                size: 18,
                                color: AppColors.textPrimary,
                              ),
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
                                'Xóa ví',
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
                const Text(
                  'Số dư',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  isBalanceVisible
                      ? NumberFormat.currency(
                          locale: 'vi_VN',
                          symbol: 'đ',
                        ).format(wallet.balance)
                      : '******',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(
                      LucideIcons.calendar,
                      size: 14,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Tạo lúc: ${DateFormat('dd/MM/yyyy').format(wallet.createdAt)}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BlocProvider.value(
        value: walletListBloc,
        child: _EditWalletSheet(wallet: wallet),
      ),
    );
  }

  void _showDeleteSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => BlocProvider.value(
        value: walletListBloc,
        child: _DeleteWalletSheet(wallet: wallet),
      ),
    );
  }
}

class _EditWalletSheet extends StatefulWidget {
  final Wallet wallet;
  const _EditWalletSheet({required this.wallet});

  @override
  State<_EditWalletSheet> createState() => _EditWalletSheetState();
}

class _EditWalletSheetState extends State<_EditWalletSheet> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.wallet.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<WalletListBloc, WalletListState>(
      listener: (context, state) {
        if (state.status == WalletStatus.success) {
          Navigator.pop(context);
          PopupNotification.showSuccess(context, 'Cập nhật ví thành công');
        } else if (state.status == WalletStatus.failure) {
          // If update failed, we might want to stay on sheet or close it.
          // Usually better to stay so user can retry.
          // For now, let's show error on the sheet or use the global listener.
          // Since we are listening in the sheet, let's just show an error.
          // BUT the sheet might be masking the main screen error popup.
          // Let's do nothing and let the user try again, the button will become active again.
        }
      },
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Chỉnh sửa ví',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    LucideIcons.x,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Tên ví',
                prefixIcon: const Icon(LucideIcons.wallet),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            BlocBuilder<WalletListBloc, WalletListState>(
              builder: (context, state) {
                final isLoading = state.status == WalletStatus.loading;

                return ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          final name = _nameController.text.trim();
                          if (name.isNotEmpty) {
                            context.read<WalletListBloc>().add(
                              UpdateWalletRequested(
                                id: widget.wallet.id,
                                name: name,
                                currency: widget.wallet.currency,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Text(
                          'Lưu thay đổi',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DeleteWalletSheet extends StatelessWidget {
  final Wallet wallet;
  const _DeleteWalletSheet({required this.wallet});

  @override
  Widget build(BuildContext context) {
    return BlocListener<WalletListBloc, WalletListState>(
      listener: (context, state) {
        if (state.status == WalletStatus.success) {
          Navigator.pop(context);
          PopupNotification.showSuccess(context, 'Đã xóa ví thành công');
        }
      },
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.alertTriangle,
                size: 32,
                color: AppColors.danger,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Xóa ví',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text.rich(
              TextSpan(
                text: 'Bạn có chắc chắn muốn xóa ví ',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
                children: [
                  TextSpan(
                    text: wallet.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const TextSpan(
                    text: ' không? Hành động này không thể hoàn tác.',
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      foregroundColor: AppColors.textPrimary,
                    ),
                    child: const Text('Hủy'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: BlocBuilder<WalletListBloc, WalletListState>(
                    builder: (context, state) {
                      final isLoading = state.status == WalletStatus.loading;
                      return ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                context.read<WalletListBloc>().add(
                                  DeleteWalletRequested(wallet.id),
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.danger,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Xóa',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
