import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../main.dart';
import '../models/wallet.dart';
import '../repositories/wallet_repository.dart';
import '../utils/popup_notification.dart';
import '../utils/currency_input_formatter.dart';

/// Màn hình chuyển tiền giữa các ví
class TransferMoneyScreen extends StatefulWidget {
  const TransferMoneyScreen({super.key});

  @override
  State<TransferMoneyScreen> createState() => _TransferMoneyScreenState();
}

class _TransferMoneyScreenState extends State<TransferMoneyScreen> {
  final WalletRepository _walletRepository = WalletRepository();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  List<Wallet> _wallets = [];
  Wallet? _fromWallet;
  Wallet? _toWallet;
  bool _isLoading = true;
  bool _isTransferring = false;

  final currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _loadWallets();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadWallets() async {
    try {
      final wallets = await _walletRepository.getWallets();
      setState(() {
        _wallets = wallets;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        PopupNotification.showError(context, 'Không thể tải danh sách ví');
      }
    }
  }

  Future<void> _handleTransfer() async {
    debugPrint('🔵 Transfer button pressed');

    // Validate
    if (_fromWallet == null) {
      debugPrint('❌ From wallet is null');
      PopupNotification.showWarning(context, 'Vui lòng chọn ví nguồn');
      return;
    }

    if (_toWallet == null) {
      debugPrint('❌ To wallet is null');
      PopupNotification.showWarning(context, 'Vui lòng chọn ví đích');
      return;
    }

    if (_amountController.text.isEmpty) {
      debugPrint('❌ Amount is empty');
      PopupNotification.showWarning(context, 'Vui lòng nhập số tiền');
      return;
    }

    final amount = double.tryParse(
      _amountController.text.replaceAll('.', '').replaceAll(',', ''),
    );
    debugPrint('💰 Parsed amount: $amount');

    if (amount == null || amount <= 0) {
      debugPrint('❌ Invalid amount');
      PopupNotification.showWarning(context, 'Số tiền không hợp lệ');
      return;
    }

    if (amount > _fromWallet!.balance) {
      debugPrint('❌ Insufficient balance: $amount > ${_fromWallet!.balance}');
      PopupNotification.showWarning(context, 'Số dư ví nguồn không đủ');
      return;
    }

    debugPrint('✅ All validations passed. Starting transfer...');
    debugPrint('📝 From: ${_fromWallet!.name} (${_fromWallet!.id})');
    debugPrint('📝 To: ${_toWallet!.name} (${_toWallet!.id})');
    debugPrint('📝 Amount: $amount');
    debugPrint('📝 Note: ${_noteController.text}');

    setState(() {
      _isTransferring = true;
    });

    try {
      await _walletRepository.transferBetweenWallets(
        fromWalletId: _fromWallet!.id,
        toWalletId: _toWallet!.id,
        amount: amount,
        note: _noteController.text,
      );

      debugPrint('✅ Transfer successful');
      if (mounted) {
        await PopupNotification.showSuccess(context, 'Chuyển tiền thành công!');
        if (mounted) {
          Navigator.pop(context, true); // Trả về true để refresh
        }
      }
    } catch (e) {
      debugPrint('❌ Transfer failed: $e');
      if (mounted) {
        await PopupNotification.showError(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTransferring = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        resizeToAvoidBottomInset: true,
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
            'Chuyển tiền giữa các ví',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _wallets.length < 2
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      LucideIcons.wallet,
                      size: 64,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Bạn cần có ít nhất 2 ví\nđể thực hiện chuyển tiền',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Ví nguồn
                          const Text(
                            'Từ ví',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildWalletSelector(
                            selectedWallet: _fromWallet,
                            wallets: _wallets,
                            onChanged: (wallet) {
                              setState(() {
                                _fromWallet = wallet;
                                // Nếu chọn trùng với ví đích, clear ví đích
                                if (_toWallet?.id == wallet?.id) {
                                  _toWallet = null;
                                }
                              });
                            },
                          ),

                          const SizedBox(height: 24),

                          // Icon mũi tên
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                LucideIcons.arrowDown,
                                color: AppColors.primary,
                                size: 24,
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Ví đích
                          const Text(
                            'Đến ví',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildWalletSelector(
                            selectedWallet: _toWallet,
                            wallets: _wallets
                                .where((w) => w.id != _fromWallet?.id)
                                .toList(),
                            onChanged: (wallet) {
                              setState(() {
                                _toWallet = wallet;
                              });
                            },
                          ),

                          const SizedBox(height: 32),

                          // Số tiền
                          const Text(
                            'Số tiền chuyển',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              CurrencyInputFormatter(),
                            ],
                            decoration: InputDecoration(
                              hintText: '0',
                              suffixText: '₫',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Ghi chú
                          const Text(
                            'Ghi chú (tùy chọn)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _noteController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: 'Thêm ghi chú...',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.all(16),
                            ),
                          ),

                          const SizedBox(height: 20), // Giảm spacing cuối
                        ],
                      ),
                    ),
                  ),

                  // Nút chuyển tiền fixed ở bottom
                  SafeArea(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isTransferring ? null : _handleTransfer,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: AppColors.primary
                                .withValues(alpha: 0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isTransferring
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Chuyển tiền',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildWalletSelector({
    required Wallet? selectedWallet,
    required List<Wallet> wallets,
    required ValueChanged<Wallet?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonFormField<Wallet>(
        initialValue: selectedWallet,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        hint: const Text('Chọn ví'),
        isExpanded: true,
        items: wallets.map((wallet) {
          return DropdownMenuItem<Wallet>(
            value: wallet,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    LucideIcons.wallet,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    wallet.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  currencyFormat.format(wallet.balance),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
