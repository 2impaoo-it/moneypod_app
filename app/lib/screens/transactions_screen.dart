import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/transaction/transaction_bloc.dart';
import '../bloc/transaction/transaction_state.dart';
import '../bloc/transaction/transaction_event.dart';
import '../models/transaction.dart';
import '../utils/category_helper.dart'; // Import Category Helper
import '../widgets/transaction_item.dart';
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
                      color: Colors.black.withValues(alpha: 0.05),
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
                      final now = DateTime.now();
                      final today = DateFormat('dd/MM/yyyy').format(now);
                      final yesterday = DateFormat(
                        'dd/MM/yyyy',
                      ).format(now.subtract(const Duration(days: 1)));

                      String key = dateKey;
                      if (dateKey == today) {
                        key = 'today';
                      } else if (dateKey == yesterday) {
                        key = 'yesterday';
                      }

                      grouped.putIfAbsent(key, () => []).add(tx);
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
                              (tx) => TransactionItem(
                                transaction: tx,
                                onTap: () => _showTransactionDetail(tx),
                              ),
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

  // --- HELPER METHODS FOR STYLING ---

  String _getCategoryDisplay(String category) {
    // Helper to map complex category names if needed, or just return as is
    return category; // implementation can be refined if grouping needed
  }

  // Hiển thị chi tiết transaction
  void _showTransactionDetail(Transaction tx) {
    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );
    final isExpense = tx.isExpense;
    final categoryColor = CategoryHelper.getColor(tx.category);
    final backgroundColor = CategoryHelper.getBackgroundColor(tx.category);

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
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Icon(
                    CategoryHelper.getIcon(tx.category),
                    color: categoryColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx.category,
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
            _buildDetailRow('Danh mục', tx.category),
            _buildDetailRow(
              'Số tiền',
              "${isExpense ? '-' : '+'}${currencyFormat.format(tx.amount.abs())}",
              valueColor: isExpense ? AppColors.danger : AppColors.success,
            ),
            if (tx.title.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'Ghi chú',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Text(
                tx.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (tx.walletName != null) _buildDetailRow('Ví', tx.walletName!),

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
                  errorBuilder: (context, error, stackTrace) => Container(
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
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
