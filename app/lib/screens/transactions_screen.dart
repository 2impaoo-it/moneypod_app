import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/transaction/transaction_bloc.dart';
import '../bloc/transaction/transaction_state.dart';
import '../bloc/transaction/transaction_event.dart';
import '../models/transaction.dart';

import '../widgets/transaction_item.dart';
import '../widgets/transaction_detail_modal.dart';
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
    "Thu nợ",
    "Trả nợ",
    "Khác",
  ];

  // 2. Quản lý state cho Sort
  String _sortOrder =
      'date_desc'; // date_desc, date_asc, amount_desc, amount_asc, wallet

  // 3. Quản lý state cho Search
  String _searchQuery = '';

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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
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
                  // Sort Action
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      setState(() {
                        _sortOrder = value;
                      });
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'date_desc',
                        child: Text('Mới nhất trước'),
                      ),
                      const PopupMenuItem(
                        value: 'date_asc',
                        child: Text('Cũ nhất trước'),
                      ),
                      const PopupMenuItem(
                        value: 'amount_desc',
                        child: Text('Số tiền cao nhất'),
                      ),
                      const PopupMenuItem(
                        value: 'amount_asc',
                        child: Text('Số tiền thấp nhất'),
                      ),
                      const PopupMenuItem(
                        value: 'wallet',
                        child: Text('Theo ví'),
                      ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.textMuted.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.arrowUpDown,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getSortLabel(_sortOrder),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
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
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: "Tìm kiếm theo ghi chú...",
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
                    // Filter by category
                    var filtered = _selectedFilter == "Tất cả"
                        ? state.transactions
                        : state.transactions
                              .where(
                                (tx) =>
                                    _getCategoryDisplay(tx.category) ==
                                    _selectedFilter,
                              )
                              .toList();

                    // Filter by search query (note field)
                    if (_searchQuery.isNotEmpty) {
                      filtered = filtered.where((tx) {
                        final title = tx.title.toLowerCase();
                        final category = tx.category.toLowerCase();
                        final walletName = tx.walletName?.toLowerCase() ?? '';
                        return title.contains(_searchQuery) ||
                            category.contains(_searchQuery) ||
                            walletName.contains(_searchQuery);
                      }).toList();
                    }

                    // Sort
                    filtered.sort((a, b) {
                      switch (_sortOrder) {
                        case 'date_asc':
                          return a.date.compareTo(b.date);
                        case 'amount_desc':
                          return b.amount.compareTo(a.amount);
                        case 'amount_asc':
                          return a.amount.compareTo(b.amount);
                        case 'wallet':
                          return (a.walletName ?? '').compareTo(
                            b.walletName ?? '',
                          );
                        case 'date_desc':
                        default:
                          return b.date.compareTo(a.date);
                      }
                    });

                    // Grouping Logic
                    // Only group by date if sorting by Date
                    final bool useDateGrouping =
                        _sortOrder == 'date_desc' || _sortOrder == 'date_asc';

                    if (!useDateGrouping) {
                      // Flat List for Amount/Wallet Sort
                      if (filtered.isEmpty) {
                        return const Center(child: Text('Không có giao dịch.'));
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final tx = filtered[index];
                          return TransactionItem(
                            transaction: tx,
                            onTap: () => _showTransactionDetail(tx),
                          );
                        },
                      );
                    }

                    // Group by Date
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
                    return Center(child: Text('Lỗi: ${state.message}'));
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

  String _getSortLabel(String sort) {
    switch (sort) {
      case 'date_asc':
        return 'Cũ nhất';
      case 'amount_desc':
        return 'Cao nhất';
      case 'amount_asc':
        return 'Thấp nhất';
      case 'wallet':
        return 'Theo ví';
      case 'date_desc':
      default:
        return 'Mới nhất';
    }
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
    TransactionDetailModal.show(context, tx);
  }
}
