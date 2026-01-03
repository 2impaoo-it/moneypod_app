import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../repositories/group_repository.dart';
import '../repositories/wallet_repository.dart';
import '../utils/popup_notification.dart';
import '../models/wallet.dart';

class DebtPaymentScreen extends StatefulWidget {
  final String debtId;
  final String creditorName;
  final String creditorAvatar;
  final int amount;
  final String description;
  final String groupName;
  final String? existingProofImageUrl;

  const DebtPaymentScreen({
    Key? key,
    required this.debtId,
    required this.creditorName,
    required this.creditorAvatar,
    required this.amount,
    required this.description,
    required this.groupName,
    this.existingProofImageUrl,
  }) : super(key: key);

  @override
  State<DebtPaymentScreen> createState() => _DebtPaymentScreenState();
}

class _DebtPaymentScreenState extends State<DebtPaymentScreen> {
  final GroupRepository _groupRepository = GroupRepository();
  final WalletRepository _walletRepository = WalletRepository();
  final TextEditingController _noteController = TextEditingController();

  List<Wallet> _wallets = [];
  Wallet? _selectedWallet;
  bool _isLoading = false;
  bool _isLoadingWallets = true;

  @override
  void initState() {
    super.initState();
    _loadWallets();
  }

  Future<void> _loadWallets() async {
    try {
      final wallets = await _walletRepository.getWallets();
      setState(() {
        _wallets = wallets;
        _isLoadingWallets = false;
        if (_wallets.isNotEmpty) {
          _selectedWallet = _wallets.first;
        }
      });
    } catch (e) {
      setState(() => _isLoadingWallets = false);
      PopupNotification.showError(context, 'Lỗi tải ví: $e');
    }
  }

  Future<void> _submitPayment() async {
    if (_selectedWallet == null) {
      PopupNotification.showError(context, 'Vui lòng chọn ví để thanh toán');
      return;
    }

    // Kiểm tra số dư ví
    if (_selectedWallet!.balance < widget.amount) {
      PopupNotification.showError(
        context,
        'Số dư ví không đủ. Cần ${_formatCurrency(widget.amount)}, có ${_formatCurrency(_selectedWallet!.balance.toInt())}',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Gọi API đánh dấu đã trả nợ với wallet ID và ghi chú
      await _groupRepository.markDebtPaid(
        widget.debtId,
        walletId: _selectedWallet!.id,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );

      if (!mounted) return;

      PopupNotification.showSuccess(
        context,
        'Đã gửi xác nhận thanh toán. Chờ chủ nợ xác nhận.',
      );

      Navigator.pop(context, true); // Trả về true để refresh
    } catch (e) {
      if (!mounted) return;
      PopupNotification.showError(context, 'Lỗi: ${e.toString()}');
      setState(() => _isLoading = false);
    }
  }

  String _formatCurrency(int amount) {
    final str = amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return '$str ₫';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.slate900),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Thanh toán nợ',
          style: TextStyle(
            color: AppColors.slate900,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoadingWallets
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thông tin chủ nợ
                  _buildCreditorInfo(),
                  const SizedBox(height: 16),

                  // Thông tin khoản nợ
                  _buildDebtInfo(),
                  const SizedBox(height: 16),

                  // Chọn ví
                  _buildWalletSelector(),
                  const SizedBox(height: 16),

                  // Ghi chú
                  _buildNoteSection(),
                  const SizedBox(height: 16),

                  // Hình ảnh minh chứng
                  _buildProofImageSection(),
                  const SizedBox(height: 24),

                  // Nút thanh toán
                  _buildPaymentButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildCreditorInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.slate200,
            backgroundImage:
                widget.creditorAvatar.isNotEmpty &&
                    widget.creditorAvatar.startsWith('http')
                ? NetworkImage(widget.creditorAvatar)
                : null,
            child:
                widget.creditorAvatar.isEmpty ||
                    !widget.creditorAvatar.startsWith('http')
                ? Text(
                    widget.creditorName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 18,
                      color: AppColors.slate700,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chủ nợ',
                  style: TextStyle(fontSize: 12, color: AppColors.slate500),
                ),
                Text(
                  widget.creditorName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebtInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(
            'Số tiền',
            _formatCurrency(widget.amount),
            isHighlight: true,
          ),
          const Divider(height: 24),
          _buildInfoRow('Mô tả', widget.description),
          const Divider(height: 24),
          _buildInfoRow('Nhóm', widget.groupName),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, color: AppColors.slate500),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: isHighlight ? 18 : 14,
              fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w500,
              color: isHighlight ? AppColors.red500 : AppColors.slate900,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWalletSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chọn ví thanh toán',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.slate900,
            ),
          ),
          const SizedBox(height: 12),
          if (_wallets.isEmpty)
            const Text(
              'Bạn chưa có ví nào. Vui lòng tạo ví trước.',
              style: TextStyle(color: AppColors.slate500, fontSize: 14),
            )
          else
            ..._wallets.map((wallet) => _buildWalletOption(wallet)),
        ],
      ),
    );
  }

  Widget _buildWalletOption(Wallet wallet) {
    final isSelected = _selectedWallet?.id == wallet.id;
    final hasEnoughBalance = wallet.balance >= widget.amount;

    return GestureDetector(
      onTap: hasEnoughBalance
          ? () {
              setState(() {
                _selectedWallet = wallet;
              });
            }
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.blue50 : AppColors.slate50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.blue500 : AppColors.slate200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppColors.blue500 : AppColors.slate400,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    wallet.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: hasEnoughBalance
                          ? AppColors.slate900
                          : AppColors.slate400,
                    ),
                  ),
                  Text(
                    _formatCurrency(wallet.balance.toInt()),
                    style: TextStyle(
                      fontSize: 13,
                      color: hasEnoughBalance
                          ? AppColors.slate600
                          : AppColors.red500,
                    ),
                  ),
                ],
              ),
            ),
            if (!hasEnoughBalance)
              const Text(
                'Không đủ',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.red500,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ghi chú (không bắt buộc)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.slate900,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Nhập ghi chú của bạn...',
              hintStyle: const TextStyle(color: AppColors.slate400),
              filled: true,
              fillColor: AppColors.slate50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProofImageSection() {
    // Chỉ hiển thị nếu có hình ảnh bill từ expense
    if (widget.existingProofImageUrl == null ||
        widget.existingProofImageUrl!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hình ảnh hoá đơn',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.slate900,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              widget.existingProofImageUrl!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppColors.slate100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.image_not_supported,
                      size: 40,
                      color: AppColors.slate400,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.blue500,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Xác nhận đã trả',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
