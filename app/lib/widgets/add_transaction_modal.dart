import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../repositories/transaction_repository.dart';
import '../repositories/wallet_repository.dart';

import '../models/wallet.dart';
import '../utils/currency_input_formatter.dart';
import '../utils/popup_notification.dart';

// Copy lại AppColors để đảm bảo file chạy độc lập
class ModalColors {
  static const Color teal500 = Color(0xFF14B8A6);
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate900 = Color(0xFF0F172A);
  static const Color red100 = Color(0xFFFEE2E2);
  static const Color red600 = Color(0xFFDC2626);
  static const Color green100 = Color(0xFFDCFCE7);
  static const Color green600 = Color(0xFF16A34A);
}

class AddTransactionModal extends StatefulWidget {
  const AddTransactionModal({super.key});

  @override
  State<AddTransactionModal> createState() => _AddTransactionModalState();
}

class _AddTransactionModalState extends State<AddTransactionModal> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TransactionRepository _transactionRepo = TransactionRepository();
  final WalletRepository _walletRepo = WalletRepository();

  bool _isExpense = true;
  int _selectedCategoryIndex = 0;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  List<Wallet> _wallets = [];
  String? _selectedWalletId;
  bool _isLoadingWallets = true;

  // Group Splitting logic

  // Mock Categories Data
  final List<Map<String, dynamic>> _categories = [
    {'name': 'Ăn uống', 'icon': Icons.restaurant, 'color': Colors.teal},
    {'name': 'Di chuyển', 'icon': Icons.directions_car, 'color': Colors.blue},
    {'name': 'Mua sắm', 'icon': Icons.shopping_bag, 'color': Colors.pink},
    {'name': 'Giải trí', 'icon': Icons.gamepad, 'color': Colors.purple},
    {'name': 'Hóa đơn', 'icon': Icons.description, 'color': Colors.orange},
    {
      'name': 'Lương',
      'icon': Icons.account_balance_wallet,
      'color': Colors.green,
    },
    {'name': 'Sức khỏe', 'icon': Icons.favorite, 'color': Colors.red},
    {'name': 'Khác', 'icon': Icons.more_horiz, 'color': Colors.grey},
  ];

  @override
  void initState() {
    super.initState();
    _loadWallets();
  }

  Future<void> _loadWallets() async {
    try {
      final wallets = await _walletRepo.getWallets();
      if (mounted) {
        setState(() {
          _wallets = wallets;
          _isLoadingWallets = false;
          if (wallets.isNotEmpty) {
            _selectedWalletId = wallets[0].id;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingWallets = false);
        PopupNotification.showError(context, 'Lỗi khi tải ví: $e');
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _handleSave() async {
    // Validate input
    if (_amountController.text.trim().isEmpty) {
      PopupNotification.showError(context, 'Vui lòng nhập số tiền');
      return;
    }

    final amount = parseCurrency(_amountController.text);
    if (amount == null || amount <= 0) {
      PopupNotification.showError(context, 'Số tiền không hợp lệ');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Create Personal Transaction
      if (_selectedWalletId == null) {
        throw Exception('Vui lòng chọn ví');
      }
      await _transactionRepo.createTransaction(
        walletId: _selectedWalletId!,
        amount: amount,
        category: _categories[_selectedCategoryIndex]['name'],
        type: _isExpense ? 'expense' : 'income',
        note: _noteController.text.trim(),
      );

      if (mounted) {
        await PopupNotification.showSuccess(context, 'Lưu thành công!');
        if (mounted) Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        PopupNotification.showError(
          context,
          'Lỗi: ${e.toString().replaceAll('Exception: ', '')}',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: ModalColors.teal500),
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

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // a) Handle Bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: ModalColors.slate300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // b) Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Thêm giao dịch",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: ModalColors.slate900,
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(Icons.close, color: ModalColors.slate500),
                    ),
                  ),
                ],
              ),
            ),

            // c) Amount Input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  CurrencyInputFormatter(),
                ],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: _isExpense ? ModalColors.red600 : ModalColors.green600,
                ),
                decoration: InputDecoration(
                  hintText: '0 ₫',
                  hintStyle: const TextStyle(color: ModalColors.slate300),
                  border: InputBorder.none,
                  prefixText: _isExpense ? '- ' : '+ ',
                  prefixStyle: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: _isExpense
                        ? ModalColors.red600
                        : ModalColors.green600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // f) Wallet Selector (Only if Personal)
            if (_isLoadingWallets)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: CircularProgressIndicator(),
              )
            else if (_wallets.isEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ModalColors.red100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Bạn chưa có ví nào. Vui lòng tạo ví trước!',
                  style: TextStyle(color: ModalColors.red600),
                  textAlign: TextAlign.center,
                ),
              )
            else
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: ModalColors.slate50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedWalletId,
                    isExpanded: true,
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: ModalColors.slate400,
                    ),
                    hint: const Text('Chọn ví'),
                    items: _wallets.map((wallet) {
                      return DropdownMenuItem<String>(
                        value: wallet.id,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.account_balance_wallet,
                              size: 20,
                              color: ModalColors.teal500,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                wallet.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Text(
                              NumberFormat.currency(
                                locale: 'vi_VN',
                                symbol: '₫',
                                decimalDigits: 0,
                              ).format(wallet.balance),
                              style: const TextStyle(
                                fontSize: 12,
                                color: ModalColors.slate500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedWalletId = value;
                      });
                    },
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // g) Transaction Type Toggle
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: ModalColors.slate50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  _buildTypeButton("Chi tiêu", true),
                  _buildTypeButton("Thu nhập", false),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // h) Category Selector (Grid)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  return _buildCategoryItem(index);
                },
              ),
            ),

            const SizedBox(height: 20),

            // i) Note Input
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: ModalColors.slate50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _noteController,
                decoration: const InputDecoration(
                  icon: Icon(Icons.edit, color: ModalColors.slate400, size: 20),
                  hintText: "Ghi chú... (VD: #caphe)",
                  hintStyle: TextStyle(
                    color: ModalColors.slate400,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // j) Date Picker
            InkWell(
              onTap: _pickDate,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: ModalColors.slate50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      color: ModalColors.slate400,
                      size: 20,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      DateFormat('dd/MM/yyyy').format(_selectedDate),
                      style: const TextStyle(
                        fontSize: 14,
                        color: ModalColors.slate900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // k) Save Button
            Container(
              width: double.infinity,
              height: 52,
              margin: const EdgeInsets.all(20),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ModalColors.teal500,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "Lưu giao dịch",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeButton(String title, bool isExpenseBtn) {
    final isSelected = _isExpense == isExpenseBtn;
    final bgColor = isSelected
        ? (isExpenseBtn ? ModalColors.red100 : ModalColors.green100)
        : Colors.transparent;
    final textColor = isSelected
        ? (isExpenseBtn ? ModalColors.red600 : ModalColors.green600)
        : ModalColors.slate400;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _isExpense = isExpenseBtn;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryItem(int index) {
    final cat = _categories[index];
    final isSelected = _selectedCategoryIndex == index;
    final color = cat['color'] as Color;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategoryIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: isSelected
            ? Matrix4.diagonal3Values(1.05, 1.05, 1.0)
            : Matrix4.identity(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
                border: isSelected
                    ? Border.all(color: ModalColors.teal500, width: 2)
                    : null,
              ),
              child: Icon(cat['icon'], color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              cat['name'],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? ModalColors.slate900 : ModalColors.slate500,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
