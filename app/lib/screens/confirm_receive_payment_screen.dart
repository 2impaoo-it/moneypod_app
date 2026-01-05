import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../repositories/group_repository.dart';
import '../repositories/wallet_repository.dart';
import '../utils/popup_notification.dart';
import 'package:go_router/go_router.dart';
import '../models/wallet.dart';

class ConfirmReceivePaymentScreen extends StatefulWidget {
  final String debtId;
  final String debtorName;
  final String debtorAvatar;
  final int amount;
  final String description;
  final String groupName;
  final String? paymentDate;
  final String? paymentNote;
  final String? proofImageUrl;
  final bool isPaid;
  final String? receivedWalletId;

  const ConfirmReceivePaymentScreen({
    super.key,
    required this.debtId,
    required this.debtorName,
    required this.debtorAvatar,
    required this.amount,
    required this.description,
    required this.groupName,
    this.paymentDate,
    this.paymentNote,
    this.proofImageUrl,
    this.isPaid = false,
    this.receivedWalletId,
  });

  @override
  State<ConfirmReceivePaymentScreen> createState() =>
      _ConfirmReceivePaymentScreenState();
}

class _ConfirmReceivePaymentScreenState
    extends State<ConfirmReceivePaymentScreen> {
  final GroupRepository _groupRepository = GroupRepository();
  final WalletRepository _walletRepository = WalletRepository();

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

        // Nếu đã paid, chọn ví đã nhận tiền
        if (widget.isPaid && widget.receivedWalletId != null) {
          _selectedWallet = _wallets.firstWhere(
            (w) => w.id == widget.receivedWalletId,
            orElse: () => _wallets.isNotEmpty ? _wallets.first : null as Wallet,
          );
        } else if (_wallets.isNotEmpty) {
          _selectedWallet = _wallets.first;
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingWallets = false);
        PopupNotification.showError(context, 'Lỗi tải ví: $e');
      }
    }
  }

  Future<void> _confirmReceivePayment() async {
    if (_selectedWallet == null) {
      PopupNotification.showError(context, 'Vui lòng chọn ví để nhận tiền');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Gọi API xác nhận đã nhận tiền
      await _groupRepository.confirmReceivePayment(
        widget.debtId,
        walletId: _selectedWallet!.id,
      );

      if (!mounted) return;

      setState(() => _isLoading = false);

      // Pop trước khi show notification
      Navigator.pop(context, true);

      // Show notification sau khi pop
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          PopupNotification.showSuccess(
            context,
            'Đã xác nhận nhận tiền thành công',
          );
        }
      });
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
      resizeToAvoidBottomInset: true,
      extendBody: false,
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.slate900),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Xác nhận nhận tiền',
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
                  // Thông tin người nợ
                  _buildDebtorInfo(),
                  const SizedBox(height: 16),

                  // Thông tin khoản nợ
                  _buildDebtInfo(),
                  const SizedBox(height: 16),

                  // Thông tin thanh toán
                  if (widget.paymentDate != null || widget.paymentNote != null)
                    _buildPaymentInfo(),
                  if (widget.paymentDate != null || widget.paymentNote != null)
                    const SizedBox(height: 16),

                  // Chọn ví nhận tiền
                  _buildWalletSelector(),
                  const SizedBox(height: 16),

                  // Hình ảnh minh chứng
                  _buildProofImageSection(),
                  const SizedBox(height: 24),

                  // Nút xác nhận
                  _buildConfirmButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildDebtorInfo() {
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
            backgroundColor: AppColors.primary.withOpacity(0.1),
            backgroundImage:
                (widget.debtorAvatar.isNotEmpty &&
                    widget.debtorAvatar.startsWith('http'))
                ? NetworkImage(widget.debtorAvatar)
                : null,
            child:
                (widget.debtorAvatar.isEmpty ||
                    !widget.debtorAvatar.startsWith('http'))
                ? Text(
                    widget.debtorName.isNotEmpty
                        ? widget.debtorName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 20,
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Text(
            widget.debtorName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.slate900,
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
          const Text(
            'Thông tin khoản nợ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.slate900,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            'Số tiền',
            _formatCurrency(widget.amount),
            isHighlight: true,
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Mô tả', widget.description),
          const SizedBox(height: 12),
          _buildInfoRow('Nhóm', widget.groupName),
        ],
      ),
    );
  }

  Widget _buildPaymentInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.blue50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.blue500.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: AppColors.blue600),
              const SizedBox(width: 8),
              const Text(
                'Thông tin thanh toán',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.blue600,
                ),
              ),
            ],
          ),
          if (widget.paymentDate != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              'Thời gian xác nhận',
              _formatDateTime(widget.paymentDate!),
            ),
          ],
          if (widget.paymentNote != null && widget.paymentNote!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoRow('Ghi chú', widget.paymentNote!),
          ],
        ],
      ),
    );
  }

  String _formatDateTime(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime.toLocal());
    } catch (e) {
      return dateTimeStr;
    }
  }

  Widget _buildInfoRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
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
              color: isHighlight ? AppColors.teal500 : AppColors.slate900,
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
          Row(
            children: [
              const Text(
                'Chọn ví nhận tiền',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.slate900,
                ),
              ),
              if (widget.isPaid) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.green100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Đã xác nhận',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.green700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          if (_wallets.isEmpty)
            const Text(
              'Không có ví nào. Vui lòng tạo ví trước.',
              style: TextStyle(color: AppColors.red500),
            )
          else if (widget.isPaid)
            // Chỉ hiển thị ví đã chọn khi đã paid
            ..._wallets.where((w) => w.id == _selectedWallet?.id).map((wallet) {
              final isSelected = _selectedWallet?.id == wallet.id;
              return GestureDetector(
                onTap: widget.isPaid
                    ? null
                    : () => setState(() => _selectedWallet = wallet),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.1)
                        : AppColors.slate50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.slate900,
                    ),
                  ),
                  Text(
                    _formatCurrency(wallet.balance.toInt()),
                    style: TextStyle(fontSize: 12, color: AppColors.slate600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProofImageSection() {
    // Chỉ hiển thị nếu có hình ảnh bill từ expense
    if (widget.proofImageUrl == null || widget.proofImageUrl!.isEmpty) {
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
              widget.proofImageUrl!,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 200,
                color: AppColors.slate100,
                child: const Center(
                  child: Icon(
                    Icons.broken_image,
                    size: 48,
                    color: AppColors.slate400,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton() {
    // Nếu đã paid, hiển thị trạng thái đã xác nhận
    if (widget.isPaid) {
      return Column(
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.green100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.green300),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: AppColors.green700,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Bạn đã xác nhận nhận tiền cho khoản nợ này',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.green700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green500,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: AppColors.green500,
              ),
              child: const Text(
                '✓ Đã xác nhận nhận tiền',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Chỉ cho phép xác nhận khi người nợ đã gửi lệnh trả tiền (có paymentDate)
    final bool canConfirm =
        widget.paymentDate != null && widget.paymentDate!.isNotEmpty;

    return Column(
      children: [
        if (!canConfirm)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warning.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.warning, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Chờ người nợ gửi xác nhận thanh toán',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.warning,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (_isLoading || !canConfirm)
                ? null
                : _confirmReceivePayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: canConfirm
                  ? AppColors.primary
                  : AppColors.slate300,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              disabledBackgroundColor: AppColors.slate300,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    canConfirm ? 'Xác nhận đã nhận tiền' : 'Chưa thể xác nhận',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
