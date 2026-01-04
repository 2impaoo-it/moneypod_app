import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../utils/category_helper.dart';
import '../../main.dart';

class FilterTransactionDialog extends StatefulWidget {
  const FilterTransactionDialog({super.key});

  @override
  State<FilterTransactionDialog> createState() =>
      _FilterTransactionDialogState();
}

class _FilterTransactionDialogState extends State<FilterTransactionDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Set<String> _selectedCategories = {};

  // Group definitions matching the updated design
  final Map<String, List<String>> _expenseGroups = {
    'Chi tiêu - sinh hoạt': ['Chợ, siêu thị', 'Ăn uống', 'Di chuyển'],
    'Chi phí phát sinh': [
      'Mua sắm',
      'Giải trí',
      'Làm đẹp',
      'Sức khỏe',
      'Từ thiện',
    ],
    'Chi phí cố định': ['Hóa đơn', 'Nhà cửa', 'Người thân'],
  };

  final Map<String, List<String>> _incomeGroups = {
    'Thu nhập': ['Lương', 'Thưởng', 'Khác'],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Spacer(),
                Text(
                  "Sắp xếp",
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(LucideIcons.x),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Tìm kiếm",
                hintStyle: GoogleFonts.inter(color: Colors.grey),
                prefixIcon: const Icon(LucideIcons.search, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Tab Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                    ),
                  ],
                ),
                labelColor: AppColors.danger, // Chi tiêu: Red/Pink
                unselectedLabelColor: Colors.grey,
                labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
                unselectedLabelStyle: GoogleFonts.inter(
                  fontWeight: FontWeight.normal,
                ),
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(LucideIcons.arrowDownLeft, size: 16),
                        SizedBox(width: 8),
                        Text("Chi tiêu"),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(LucideIcons.arrowUpRight, size: 16),
                        SizedBox(width: 8),
                        Text("Thu nhập"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCategoryList(_expenseGroups, Colors.orange),
                _buildCategoryList(_incomeGroups, Colors.green),
              ],
            ),
          ),

          // Footer Buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedCategories.clear();
                      });
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.grey[100],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Xoá bộ lọc",
                      style: GoogleFonts.inter(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () =>
                        Navigator.pop(context, _selectedCategories),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.danger,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      "Áp dụng",
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList(
    Map<String, List<String>> groups,
    Color themeColor,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (var entry in groups.entries)
          _buildCategoryGroup(entry.key, entry.value, themeColor),
      ],
    );
  }

  Widget _buildCategoryGroup(
    String title,
    List<String> categories,
    Color themeColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  title.contains('sinh hoạt')
                      ? LucideIcons.receipt
                      : (title.contains('phát sinh')
                            ? LucideIcons.layers
                            : (title.contains('cố định')
                                  ? LucideIcons.home
                                  : LucideIcons.trendingUp)),
                  size: 16,
                  color: themeColor,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: themeColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  final allSelected = categories.every(
                    (cat) => _selectedCategories.contains(cat),
                  );
                  if (allSelected) {
                    _selectedCategories.removeAll(categories);
                  } else {
                    _selectedCategories.addAll(categories);
                  }
                });
              },
              child: Text(
                "Chọn",
                style: GoogleFonts.inter(
                  color: AppColors.danger,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: categories.map((cat) {
            final isSelected = _selectedCategories.contains(cat);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedCategories.remove(cat);
                  } else {
                    _selectedCategories.add(cat);
                  }
                });
              },
              child: SizedBox(
                width: (MediaQuery.of(context).size.width - 64) / 3,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: CategoryHelper.getBackgroundColor(cat),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            CategoryHelper.getIcon(cat),
                            size: 24,
                            color: CategoryHelper.getColor(cat),
                          ),
                        ),
                        if (isSelected)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                LucideIcons.check,
                                size: 10,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      cat,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textPrimary,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
