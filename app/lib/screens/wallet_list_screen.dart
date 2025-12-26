import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import '../bloc/wallet_list/wallet_list_bloc.dart';
import '../bloc/wallet_list/wallet_list_event.dart';
import '../bloc/wallet_list/wallet_list_state.dart';
import '../repositories/wallet_repository.dart';
import '../models/wallet.dart';

/// Màn hình hiển thị danh sách ví
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

class _WalletListView extends StatelessWidget {
  const _WalletListView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
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
            icon: const Icon(LucideIcons.refreshCw, color: AppColors.primary),
            onPressed: () {
              context.read<WalletListBloc>().add(const RefreshWalletList());
            },
          ),
        ],
      ),
      body: BlocBuilder<WalletListBloc, WalletListState>(
        builder: (context, state) {
          if (state is WalletListLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            );
          }

          if (state is WalletListError) {
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
                    Text(
                      'Có lỗi xảy ra',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
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

          if (state is WalletListLoaded) {
            if (state.wallets.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
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
                  return _WalletCard(wallet: wallet);
                },
              ),
            );
          }

          return const SizedBox();
        },
      ),
    );
  }
}

/// Widget hiển thị thẻ ví
class _WalletCard extends StatelessWidget {
  final Wallet wallet;

  const _WalletCard({required this.wallet});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###', 'vi_VN');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // TODO: Navigate đến chi tiết ví
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Icon + Name
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        LucideIcons.wallet,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        wallet.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Icon(
                      LucideIcons.chevronRight,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Số dư
                const Text(
                  'Số dư',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Text(
                  '${formatter.format(wallet.balance)} đ',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),

                // Thông tin thêm
                Row(
                  children: [
                    const Icon(
                      LucideIcons.calendar,
                      size: 14,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Tạo lúc: ${DateFormat('dd/MM/yyyy').format(wallet.createdAt)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
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
}
