import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../utils/popup_notification.dart';
import '../main.dart';
import '../bloc/bill_scan/bill_scan_bloc.dart';
import '../bloc/bill_scan/bill_scan_event.dart';
import '../bloc/bill_scan/bill_scan_state.dart';
import '../repositories/bill_scan_repository.dart';

class BillScanScreen extends StatelessWidget {
  const BillScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => BillScanBloc(repository: BillScanRepository()),
      child: const _BillScanContent(),
    );
  }
}

class _BillScanContent extends StatelessWidget {
  const _BillScanContent();

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
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Quét Bill',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<BillScanBloc, BillScanState>(
        listener: (context, state) {
          if (state is BillScanFailure) {
            PopupNotification.showError(context, state.error);
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: _buildContent(context, state, currencyFormat),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildActionButtons(context, state),
                  if (state is! BillScanSuccess) const SizedBox(height: 60),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    BillScanState state,
    NumberFormat currencyFormat,
  ) {
    if (state is BillScanLoading) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Đang phân tích hóa đơn...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Vui lòng đợi trong giây lát',
            style: TextStyle(fontSize: 14, color: AppColors.textMuted),
          ),
        ],
      );
    }

    if (state is BillScanSuccess) {
      return _buildSuccessCard(state, currencyFormat);
    }

    // BillScanInitial or other states
    return _buildInitialContent();
  }

  Widget _buildInitialContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Icon(
            LucideIcons.scanLine,
            size: 80,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Quét hóa đơn của bạn',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'Chụp ảnh hóa đơn hoặc chọn từ thư viện để AI tự động phân tích và thêm giao dịch',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessCard(BillScanSuccess state, NumberFormat currencyFormat) {
    return _EditableBillCard(
      result: state.result,
      currencyFormat: currencyFormat,
    );
  }

  Widget _buildActionButtons(BuildContext context, BillScanState state) {
    if (state is BillScanSuccess) {
      // Không cần action buttons vì _EditableBillCard đã có nút "Thêm giao dịch"
      return const SizedBox.shrink();
    }

    // Initial or Loading state
    return Column(
      children: [
        // Nút quét bằng camera
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: state is BillScanLoading
                ? null
                : () {
                    context.read<BillScanBloc>().add(
                      const ScanBillFromCamera(),
                    );
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.camera),
                SizedBox(width: 12),
                Text(
                  'Chụp ảnh hóa đơn',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Nút chọn từ thư viện
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: state is BillScanLoading
                ? null
                : () {
                    context.read<BillScanBloc>().add(
                      const ScanBillFromGallery(),
                    );
                  },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.image),
                SizedBox(width: 12),
                Text(
                  'Chọn từ thư viện',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Widget mới để cho phép chỉnh sửa thông tin bill
class _EditableBillCard extends StatefulWidget {
  final dynamic result;
  final NumberFormat currencyFormat;

  const _EditableBillCard({required this.result, required this.currencyFormat});

  @override
  State<_EditableBillCard> createState() => _EditableBillCardState();
}

class _EditableBillCardState extends State<_EditableBillCard> {
  late TextEditingController _merchantController;
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late DateTime _selectedDate;
  late String _selectedCategory;
  bool _isSaving = false;

  final List<String> _categories = [
    'Ăn uống',
    'Di chuyển',
    'Mua sắm',
    'Giải trí',
    'Y tế',
    'Giáo dục',
    'Lương',
    'Khác',
  ];

  // Map category từ tiếng Anh sang tiếng Việt
  String _mapCategoryToVietnamese(String category) {
    final Map<String, String> categoryMap = {
      'food': 'Ăn uống',
      'transportation': 'Di chuyển',
      'shopping': 'Mua sắm',
      'entertainment': 'Giải trí',
      'health': 'Y tế',
      'education': 'Giáo dục',
      'salary': 'Lương',
      'other': 'Khác',
    };

    // Chuyển về lowercase để so sánh
    final categoryLower = category.toLowerCase().trim();

    // Tìm trong map
    if (categoryMap.containsKey(categoryLower)) {
      return categoryMap[categoryLower]!;
    }

    // Nếu đã là tiếng Việt và có trong list thì giữ nguyên
    if (_categories.contains(category)) {
      return category;
    }

    // Mặc định trả về "Khác"
    return 'Khác';
  }

  @override
  void initState() {
    super.initState();
    _merchantController = TextEditingController(text: widget.result.merchant);
    _amountController = TextEditingController(
      text: widget.result.amount.toStringAsFixed(0),
    );
    _noteController = TextEditingController(text: widget.result.note ?? '');
    _selectedDate = widget.result.date;
    // Map category từ server sang tiếng Việt
    _selectedCategory = _mapCategoryToVietnamese(widget.result.category);
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveTransaction() async {
    // Validate
    if (_merchantController.text.trim().isEmpty) {
      PopupNotification.showError(context, 'Vui lòng nhập tên cửa hàng');
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      PopupNotification.showError(context, 'Vui lòng nhập số tiền hợp lệ');
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Gửi data lên server
      final repository = BillScanRepository();
      await repository.saveTransaction(
        merchant: _merchantController.text.trim(),
        amount: amount,
        date: _selectedDate,
        category: _selectedCategory,
        note: _noteController.text.trim(),
      );

      if (!mounted) return;

      // Thành công
      PopupNotification.showSuccess(context, 'Thêm giao dịch thành công!');

      // Quay về màn hình trước
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      PopupNotification.showError(context, 'Lỗi: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Success Header Card
          _buildSuccessHeader(),
          const SizedBox(height: 24),

          // Form Card với Material Design 3
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
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
                  // Section: Thông tin cơ bản
                  _buildSectionTitle('Thông tin cơ bản'),
                  const SizedBox(height: 16),

                  // Merchant Field
                  _buildModernTextField(
                    controller: _merchantController,
                    label: 'Tên cửa hàng',
                    icon: LucideIcons.store,
                    hintText: 'Nhập tên cửa hàng',
                    validator: (value) {
                      if (value?.trim().isEmpty ?? true) {
                        return 'Vui lòng nhập tên cửa hàng';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Amount Field
                  _buildModernTextField(
                    controller: _amountController,
                    label: 'Số tiền',
                    icon: LucideIcons.dollarSign,
                    hintText: '0',
                    keyboardType: TextInputType.number,
                    suffixText: '₫',
                    validator: (value) {
                      final amount = double.tryParse(value ?? '');
                      if (amount == null || amount <= 0) {
                        return 'Số tiền phải lớn hơn 0';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Section: Thời gian & Phân loại
                  _buildSectionTitle('Thời gian & Phân loại'),
                  const SizedBox(height: 16),

                  // Date Picker
                  _buildModernDatePicker(
                    label: 'Ngày giao dịch',
                    icon: LucideIcons.calendar,
                    date: _selectedDate,
                    onTap: () => _selectDate(context),
                  ),
                  const SizedBox(height: 20),

                  // Category Dropdown
                  _buildModernDropdown(
                    label: 'Danh mục',
                    icon: LucideIcons.tag,
                    value: _selectedCategory,
                    items: _categories,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedCategory = value);
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  // Section: Ghi chú
                  _buildSectionTitle('Ghi chú (tuỳ chọn)'),
                  const SizedBox(height: 16),

                  // Note Field
                  _buildModernTextField(
                    controller: _noteController,
                    label: 'Ghi chú',
                    icon: LucideIcons.messageSquare,
                    hintText: 'Thêm ghi chú cho giao dịch này...',
                    maxLines: 4,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Action Buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  /// Success Header với icon và title
  Widget _buildSuccessHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.success.withValues(alpha: 0.1),
            AppColors.success.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              LucideIcons.checkCircle,
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
                  'Quét thành công!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Xem và chỉnh sửa thông tin trước khi lưu',
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

  /// Section Title
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

  /// Modern TextField với Material Design 3
  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hintText,
    TextInputType? keyboardType,
    String? suffixText,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: AppColors.textMuted.withValues(alpha: 0.5),
              fontWeight: FontWeight.normal,
            ),
            suffixText: suffixText,
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
                color: AppColors.textMuted.withValues(alpha: 0.1),
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
          ),
          validator: validator,
        ),
      ],
    );
  }

  /// Modern Date Picker Field
  Widget _buildModernDatePicker({
    required String label,
    required IconData icon,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.textMuted.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('dd/MM/yyyy').format(date),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                Icon(
                  LucideIcons.chevronDown,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Modern Dropdown Field
  Widget _buildModernDropdown({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          items: items.map((category) {
            return DropdownMenuItem(value: category, child: Text(category));
          }).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
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
                color: AppColors.textMuted.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
          icon: const Icon(
            LucideIcons.chevronDown,
            size: 20,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  /// Action Buttons
  Widget _buildActionButtons() {
    return Column(
      children: [
        // Save Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveTransaction,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shadowColor: AppColors.primary.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isSaving
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
                        'Thêm giao dịch',
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

        // Reset Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: _isSaving
                ? null
                : () {
                    context.read<BillScanBloc>().add(const ResetBillScan());
                  },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: BorderSide(
                color: AppColors.textMuted.withValues(alpha: 0.3),
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.scanLine, size: 20),
                SizedBox(width: 10),
                Text(
                  'Quét lại',
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
      ],
    );
  }
}
