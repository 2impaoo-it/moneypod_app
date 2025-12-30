import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../main.dart';
import '../utils/currency_input_formatter.dart';
import '../bloc/create_wallet/create_wallet_bloc.dart';
import '../bloc/create_wallet/create_wallet_event.dart';
import '../bloc/create_wallet/create_wallet_state.dart';
import '../repositories/wallet_repository.dart';

/// Màn hình tạo ví mới với Material Design 3
class CreateWalletScreen extends StatelessWidget {
  const CreateWalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          CreateWalletBloc(walletRepository: WalletRepository()),
      child: const _CreateWalletContent(),
    );
  }
}

class _CreateWalletContent extends StatefulWidget {
  const _CreateWalletContent();

  @override
  State<_CreateWalletContent> createState() => _CreateWalletContentState();
}

class _CreateWalletContentState extends State<_CreateWalletContent> {
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  final _nameFocusNode = FocusNode();
  final _balanceFocusNode = FocusNode();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Reset state khi mở màn hình để tránh cache
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CreateWalletBloc>().add(const ResetCreateWallet());
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _nameFocusNode.dispose();
    _balanceFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.x, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Thêm ví mới',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<CreateWalletBloc, CreateWalletState>(
        listener: (context, state) {
          // Xử lý khi tạo thành công
          if (state.status == CreateWalletStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tạo ví thành công!'),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
            Navigator.pop(context, true); // Trả về true để reload dashboard
          }

          // Xử lý khi có lỗi
          if (state.status == CreateWalletStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Có lỗi xảy ra'),
                backgroundColor: AppColors.danger,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Card
                    _buildHeaderCard(),
                    const SizedBox(height: 24),

                    // Form Card
                    _buildFormCard(context, state, currencyFormat),
                    const SizedBox(height: 24),

                    // Action Buttons
                    _buildActionButtons(context, state),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Header card với icon và description
  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.primary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              LucideIcons.wallet,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tạo ví mới',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Quản lý tài chính của bạn tốt hơn',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Form card chứa các input fields
  Widget _buildFormCard(
    BuildContext context,
    CreateWalletState state,
    NumberFormat currencyFormat,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section: Thông tin ví
            _buildSectionTitle('Thông tin ví'),
            const SizedBox(height: 16),

            // Wallet Name Field
            _buildNameField(context),
            const SizedBox(height: 20),

            // Balance Field
            _buildBalanceField(context, currencyFormat),
            const SizedBox(height: 16),

            // Helper text
            Text(
              'Bạn có thể thay đổi số dư sau khi tạo ví',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMuted.withOpacity(0.7),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Section title
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: 0.5,
      ),
    );
  }

  /// Name input field
  Widget _buildNameField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(LucideIcons.tag, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text(
              'Tên ví',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '*',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.danger,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nameController,
          focusNode: _nameFocusNode,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Ví tiền mặt, Ví ngân hàng, ...',
            hintStyle: TextStyle(
              color: AppColors.textMuted.withOpacity(0.5),
              fontWeight: FontWeight.normal,
            ),
            filled: true,
            fillColor: AppColors.background,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.textMuted.withOpacity(0.1),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.danger, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.danger, width: 2),
            ),
          ),
          // Server sẽ xử lý validation chi tiết
          validator: (value) {
            if (value?.trim().isEmpty ?? true) {
              return 'Vui lòng nhập tên ví';
            }
            return null;
          },
          onChanged: (value) {
            context.read<CreateWalletBloc>().add(WalletNameChanged(value));
          },
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) {
            _balanceFocusNode.requestFocus();
          },
        ),
      ],
    );
  }

  /// Balance input field
  Widget _buildBalanceField(BuildContext context, NumberFormat currencyFormat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(LucideIcons.dollarSign, size: 16, color: AppColors.primary),
            SizedBox(width: 8),
            Text(
              'Số dư ban đầu',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _balanceController,
          focusNode: _balanceFocusNode,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            CurrencyInputFormatter(),
          ],
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: '0',
            hintStyle: TextStyle(
              color: AppColors.textMuted.withOpacity(0.5),
              fontWeight: FontWeight.normal,
            ),
            suffixText: '₫',
            suffixStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
            filled: true,
            fillColor: AppColors.background,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.textMuted.withOpacity(0.1),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.danger, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.danger, width: 2),
            ),
          ),
          // Server sẽ xử lý validation chi tiết về giá trị
          validator: (value) {
            final balance = parseCurrency(value ?? '');
            if (balance == null) {
              return 'Vui lòng nhập số hợp lệ';
            }
            // Các validation khác (< 0, max value, etc.) do server xử lý
            return null;
          },
          onChanged: (value) {
            final balance = parseCurrency(value) ?? 0.0;
            context.read<CreateWalletBloc>().add(WalletBalanceChanged(balance));
          },
          textInputAction: TextInputAction.done,
        ),
      ],
    );
  }

  /// Action buttons
  Widget _buildActionButtons(BuildContext context, CreateWalletState state) {
    final isLoading = state.status == CreateWalletStatus.loading;

    return Column(
      children: [
        // Create Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: isLoading
                ? null
                : () {
                    // Gửi trực tiếp lên server, server sẽ validate
                    context.read<CreateWalletBloc>().add(
                      const CreateWalletSubmitted(),
                    );
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shadowColor: AppColors.primary.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
            ),
            child: isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.check, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Tạo ví',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 12),

        // Cancel Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: isLoading ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: BorderSide(
                color: AppColors.textMuted.withOpacity(0.3),
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Hủy',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
