import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../main.dart'; // Import để lấy AppColors

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  // 1. Quản lý state cho Filter
  String _selectedFilter = "Tất cả";
  final List<String> _filters = [
    "Tất cả",
    "#ănuống",
    "#caphe",
    "#xebus",
    "#luong",
    "#muasam",
    "#giaitri",
  ];

  // 2. Mock Data
  final List<Map<String, dynamic>> _rawTransactions = [
    // Hôm nay
    {
      "id": 1,
      "title": "Phở Thìn",
      "category": "food",
      "hashtag": "#ănuống",
      "amount": -55000,
      "time": "08:30",
      "date": "today",
    },
    {
      "id": 2,
      "title": "Grab đi làm",
      "category": "transport",
      "hashtag": "#xebus",
      "amount": -32000,
      "time": "07:15",
      "date": "today",
    },
    {
      "id": 3,
      "title": "The Coffee House",
      "category": "food",
      "hashtag": "#caphe",
      "amount": -45000,
      "time": "14:00",
      "date": "today",
    },
    // Hôm qua
    {
      "id": 4,
      "title": "Lương tháng 1",
      "category": "salary",
      "hashtag": "#luong",
      "amount": 15000000,
      "time": "09:00",
      "date": "yesterday",
    },
    {
      "id": 5,
      "title": "Shopee - Áo thun",
      "category": "shopping",
      "hashtag": "#muasam",
      "amount": -250000,
      "time": "20:30",
      "date": "yesterday",
    },
    // 15/01/2025
    {
      "id": 6,
      "title": "Netflix",
      "category": "entertainment",
      "hashtag": "#giaitri",
      "amount": -70000,
      "time": "00:00",
      "date": "15/01/2025",
    },
    {
      "id": 7,
      "title": "Cơm trưa",
      "category": "food",
      "hashtag": "#ănuống",
      "amount": -35000,
      "time": "12:00",
      "date": "15/01/2025",
    },
  ];

  // 3. Helper: Group data by Date
  Map<String, List<Map<String, dynamic>>> get _groupedTransactions {
    // Lọc dữ liệu trước khi group
    final filteredList = _selectedFilter == "Tất cả"
        ? _rawTransactions
        : _rawTransactions
              .where((tx) => tx['hashtag'] == _selectedFilter)
              .toList();

    Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var tx in filteredList) {
      final dateKey = tx['date'] as String;
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(tx);
    }
    return grouped;
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
              child: Text(
                "Giao dịch",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),

            // --- 2. SEARCH BAR ---
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ), // vertical reduced for TextField alignment
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
                              : Colors.grey.shade100, // teal-500 or slate-100
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
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _groupedTransactions.keys.length,
                itemBuilder: (context, index) {
                  final dateKey = _groupedTransactions.keys.elementAt(index);
                  final transactions = _groupedTransactions[dateKey]!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date Header
                      _buildDateHeader(dateKey),

                      // List Items in this group
                      ...transactions.map((tx) => _buildTransactionItem(tx)),

                      const SizedBox(height: 8),
                    ],
                  );
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

  Widget _buildTransactionItem(Map<String, dynamic> tx) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final amount = tx['amount'] as int;
    final isExpense = amount < 0;

    // Mapping style based on category
    final style = _getCategoryStyle(tx['category']);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        // Có thể thêm shadow nhẹ nếu muốn nổi khối hơn
      ),
      child: Row(
        children: [
          // a) Category Icon Circle
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: style.bgColor,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(style.icon, color: style.iconColor, size: 20),
          ),

          const SizedBox(width: 12),

          // b) Content Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx['title'],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      tx['hashtag'],
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primaryDark, // teal-600
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        "•",
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    Text(
                      tx['time'],
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // c) Amount Column
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${isExpense ? '' : '+'}${currencyFormat.format(amount)}",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isExpense ? AppColors.danger : AppColors.success,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _getCategoryDisplay(tx['category']),
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- HELPER METHODS FOR STYLING ---

  String _getCategoryDisplay(String category) {
    switch (category) {
      case 'food':
        return 'Ăn uống';
      case 'transport':
        return 'Di chuyển';
      case 'shopping':
        return 'Mua sắm';
      case 'entertainment':
        return 'Giải trí';
      case 'salary':
        return 'Lương';
      default:
        return 'Khác';
    }
  }

  _CategoryStyle _getCategoryStyle(String category) {
    switch (category) {
      case 'food':
        return _CategoryStyle(
          bgColor: const Color(0xFFCCFBF1), // teal-100
          iconColor: const Color(0xFF0D9488), // teal-600
          icon: LucideIcons.utensils,
        );
      case 'transport':
        return _CategoryStyle(
          bgColor: const Color(0xFFDBEAFE), // blue-100
          iconColor: const Color(0xFF2563EB), // blue-600
          icon: LucideIcons.car,
        );
      case 'shopping':
        return _CategoryStyle(
          bgColor: const Color(0xFFFCE7F3), // pink-100
          iconColor: const Color(0xFFDB2777), // pink-600
          icon: LucideIcons.shoppingBag,
        );
      case 'entertainment':
        return _CategoryStyle(
          bgColor: const Color(0xFFF3E8FF), // purple-100
          iconColor: const Color(0xFF9333EA), // purple-600
          icon: LucideIcons.gamepad2,
        );
      case 'salary':
        return _CategoryStyle(
          bgColor: const Color(0xFFDCFCE7), // green-100
          iconColor: const Color(0xFF16A34A), // green-600
          icon: LucideIcons.wallet,
        );
      default:
        return _CategoryStyle(
          bgColor: const Color(0xFFF3F4F6), // gray-100
          iconColor: const Color(0xFF4B5563), // gray-600
          icon: LucideIcons.moreHorizontal,
        );
    }
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
