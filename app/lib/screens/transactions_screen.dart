import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/transaction/transaction_bloc.dart';
import '../bloc/transaction/transaction_state.dart';
import '../bloc/transaction/transaction_event.dart';
import '../models/transaction.dart';
import '../main.dart'; // Import để lấy AppColors

class TransactionsScreen extends StatefulWidget {
  final String? walletId; // Optional walletId (nếu null thì hiện tất cả)

  const TransactionsScreen({super.key, this.walletId});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  // 1. Quản lý state cho Filter - khớp với danh mục trong modal
  String _selectedFilter = "Tất cả";
  final List<String> _filters = [
    "Tất cả",
    "Ăn uống",
    "Di chuyển",
    "Mua sắm",
    "Giải trí",
    "Hóa đơn",
    "Lương",
    "Sức khỏe",
    "Khác",
  ];

  @override
  void initState() {
    super.initState();
    // Gọi API khi mở screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionBloc>().add(
        TransactionLoadRequested(walletId: widget.walletId),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. HEADER SECTION ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  if (widget.walletId != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(20),
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(LucideIcons.arrowLeft, size: 24),
                        ),
                      ),
                    ),
                  Text(
                    widget.walletId != null ? "Lịch sử ví" : "Giao dịch",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            // --- 2. SEARCH BAR ---
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Tìm kiếm giao dịch...",
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: AppColors.textMuted,
                    ),
                    prefixIcon: Icon(
                      LucideIcons.search,
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),

            // --- 3. FILTER CHIPS ---
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
              child: Row(
                children: _filters.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedFilter = filter;
                        });
                        // Reload from API if needed
                        context.read<TransactionBloc>().add(
                          TransactionLoadRequested(),
                        );
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          filter,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // --- 4. TRANSACTIONS LIST ---
            Expanded(
              child: BlocBuilder<TransactionBloc, TransactionState>(
                builder: (context, state) {
                  if (state is TransactionLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is TransactionLoaded) {
                    // Filter transactions - so sánh với category đã được chuẩn hóa
                    final filtered = _selectedFilter == "Tất cả"
                        ? state.transactions
                        : state.transactions
                              .where(
                                (tx) =>
                                    _getCategoryDisplay(tx.category) ==
                                    _selectedFilter,
                              )
                              .toList();
                    final grouped = <String, List<Transaction>>{};
                    for (var tx in filtered) {
                      final dateKey = DateFormat('dd/MM/yyyy').format(tx.date);
                      grouped.putIfAbsent(dateKey, () => []).add(tx);
                    }
                    if (grouped.isEmpty) {
                      return const Center(child: Text('Không có giao dịch.'));
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: grouped.keys.length,
                      itemBuilder: (context, index) {
                        final dateKey = grouped.keys.elementAt(index);
                        final transactions = grouped[dateKey]!;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDateHeader(dateKey),
                            ...transactions.map(
                              (tx) => _buildTransactionItem(tx),
                            ),
                            const SizedBox(height: 8),
                          ],
                        );
                      },
                    );
                  } else if (state is TransactionError) {
                    return Center(child: Text('Lỗi: {state.message}'));
                  } else {
                    return const SizedBox.shrink();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildDateHeader(String dateKey) {
    String displayDate;
    switch (dateKey) {
      case 'today':
        displayDate = "Hôm nay";
        break;
      case 'yesterday':
        displayDate = "Hôm qua";
        break;
      default:
        displayDate = dateKey;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        displayDate,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary, // slate-500
        ),
      ),
    );
  }

  Widget _buildTransactionItem(Transaction tx) {
    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );
    final amount = tx.amount;
    final isExpense = tx.isExpense;
    final style = _getCategoryStyle(tx.category);

    return InkWell(
      onTap: () => _showTransactionDetail(tx),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // User Avatar hoặc Category Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: style.bgColor,
                borderRadius: BorderRadius.circular(22),
              ),
              child: tx.userAvatar != null && tx.userAvatar!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Image.network(
                        tx.userAvatar!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Icon(style.icon, color: style.iconColor, size: 20),
                      ),
                    )
                  : Icon(style.icon, color: style.iconColor, size: 20),
            ),

            const SizedBox(width: 12),

            // Content Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tên ví
                  Text(
                    tx.walletName ?? 'Ví chưa xác định',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Tiêu đề giao dịch
                  Text(
                    tx.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        tx.hashtag ?? '',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          "•",
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      Text(
                        DateFormat('HH:mm').format(tx.date),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Amount Column
            Text(
              "${isExpense ? '-' : '+'}${currencyFormat.format(amount.abs())}",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isExpense ? AppColors.danger : AppColors.success,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- HELPER METHODS FOR STYLING ---

  String _getCategoryDisplay(String category) {
    // Map cả tiếng Việt và tiếng Anh
    final lowerCategory = category.toLowerCase();
    if (lowerCategory.contains('ăn') ||
        lowerCategory.contains('food') ||
        lowerCategory.contains('ăn uống')) {
      return 'Ăn uống';
    } else if (lowerCategory.contains('di chuyển') ||
        lowerCategory.contains('transport')) {
      return 'Di chuyển';
    } else if (lowerCategory.contains('mua sắm') ||
        lowerCategory.contains('shopping')) {
      return 'Mua sắm';
    } else if (lowerCategory.contains('giải trí') ||
        lowerCategory.contains('entertainment')) {
      return 'Giải trí';
    } else if (lowerCategory.contains('lương') ||
        lowerCategory.contains('salary')) {
      return 'Lương';
    } else if (lowerCategory.contains('hóa đơn') ||
        lowerCategory.contains('bill')) {
      return 'Hóa đơn';
    } else if (lowerCategory.contains('sức khỏe') ||
        lowerCategory.contains('health')) {
      return 'Sức khỏe';
    }
    return 'Khác';
  }

  _CategoryStyle _getCategoryStyle(String category) {
    final lowerCategory = category.toLowerCase();

    if (lowerCategory.contains('ăn') ||
        lowerCategory.contains('food') ||
        lowerCategory.contains('ăn uống')) {
      return _CategoryStyle(
        bgColor: const Color(0xFFCCFBF1), // teal-100
        iconColor: const Color(0xFF0D9488), // teal-600
        icon: LucideIcons.utensils,
      );
    } else if (lowerCategory.contains('di chuyển') ||
        lowerCategory.contains('transport')) {
      return _CategoryStyle(
        bgColor: const Color(0xFFDBEAFE), // blue-100
        iconColor: const Color(0xFF2563EB), // blue-600
        icon: LucideIcons.car,
      );
    } else if (lowerCategory.contains('mua sắm') ||
        lowerCategory.contains('shopping')) {
      return _CategoryStyle(
        bgColor: const Color(0xFFFCE7F3), // pink-100
        iconColor: const Color(0xFFDB2777), // pink-600
        icon: LucideIcons.shoppingBag,
      );
    } else if (lowerCategory.contains('giải trí') ||
        lowerCategory.contains('entertainment')) {
      return _CategoryStyle(
        bgColor: const Color(0xFFF3E8FF), // purple-100
        iconColor: const Color(0xFF9333EA), // purple-600
        icon: LucideIcons.gamepad2,
      );
    } else if (lowerCategory.contains('lương') ||
        lowerCategory.contains('salary')) {
      return _CategoryStyle(
        bgColor: const Color(0xFFDCFCE7), // green-100
        iconColor: const Color(0xFF16A34A), // green-600
        icon: LucideIcons.wallet,
      );
    } else if (lowerCategory.contains('hóa đơn') ||
        lowerCategory.contains('bill')) {
      return _CategoryStyle(
        bgColor: const Color(0xFFFFEDD5), // orange-100
        iconColor: const Color(0xFFEA580C), // orange-600
        icon: LucideIcons.fileText,
      );
    } else if (lowerCategory.contains('sức khỏe') ||
        lowerCategory.contains('health')) {
      return _CategoryStyle(
        bgColor: const Color(0xFFFEE2E2), // red-100
        iconColor: const Color(0xFFDC2626), // red-600
        icon: LucideIcons.heart,
      );
    }

    return _CategoryStyle(
      bgColor: const Color(0xFFF3F4F6), // gray-100
      iconColor: const Color(0xFF4B5563), // gray-600
      icon: LucideIcons.moreHorizontal,
    );
  }

  // Hiển thị chi tiết transaction
  void _showTransactionDetail(Transaction tx) {
    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );
    final isExpense = tx.isExpense;
    final style = _getCategoryStyle(tx.category);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: style.bgColor,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: tx.userAvatar != null && tx.userAvatar!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: Image.network(
                            tx.userAvatar!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              style.icon,
                              color: style.iconColor,
                              size: 28,
                            ),
                          ),
                        )
                      : Icon(style.icon, color: style.iconColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx.userName ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(tx.date),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(LucideIcons.x),
                ),
              ],
            ),

            const Divider(height: 32),

            // Transaction Info
            _buildDetailRow(
              'Loại giao dịch',
              isExpense ? 'Chi tiêu' : 'Thu nhập',
            ),
            _buildDetailRow('Danh mục', _getCategoryDisplay(tx.category)),
            _buildDetailRow(
              'Số tiền',
              "${isExpense ? '-' : '+'}${currencyFormat.format(tx.amount.abs())}",
              valueColor: isExpense ? AppColors.danger : AppColors.success,
            ),
            if (tx.hashtag != null && tx.hashtag!.isNotEmpty)
              _buildDetailRow('Hashtag', tx.hashtag!),
            if (tx.title.isNotEmpty) _buildDetailRow('Ghi chú', tx.title),

            // Proof Image
            if (tx.proofImage != null && tx.proofImage!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Hình ảnh minh chứng',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  tx.proofImage!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 150,
                    color: AppColors.background,
                    child: const Center(
                      child: Icon(
                        LucideIcons.imageOff,
                        size: 48,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryStyle {
  final Color bgColor;
  final Color iconColor;
  final IconData icon;

  _CategoryStyle({
    required this.bgColor,
    required this.iconColor,
    required this.icon,
  });
}
