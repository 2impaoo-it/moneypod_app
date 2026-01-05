import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../utils/category_helper.dart';
import '../../main.dart'; // For AppColors
import 'budget_amount_screen.dart';

import '../../models/transaction.dart';

class CreateBudgetScreen extends StatefulWidget {
  final List<Transaction>? transactions;

  const CreateBudgetScreen({super.key, this.transactions});

  @override
  State<CreateBudgetScreen> createState() => _CreateBudgetScreenState();
}

class _CreateBudgetScreenState extends State<CreateBudgetScreen> {
  String? _selectedCategory;
  bool _isTotalMonthly = false;

  // Simulate grouping similar to filter dialog
  final Map<String, List<String>> _expenseGroups = {
    'Chi tiêu - sinh hoạt': ['Chợ, siêu thị', 'Ăn uống', 'Di chuyển'],
    'Chi phí phát sinh': [
      'Mua sắm',
      'Giải trí',
      'Làm đẹp',
      'Sức khỏe',
      'Từ thiện',
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Tạo ngân sách",
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Text
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Chọn danh mục chi tiêu",
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Bạn sẽ được thông báo khi chi tiêu danh mục đạt tới giới hạn",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Robot Image Placeholder
                Image.asset(
                  'assets/images/mascot_pointing.png', // Assuming asset exists
                  height: 80,
                  errorBuilder: (c, o, s) => const Icon(
                    LucideIcons.bot,
                    size: 60,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                // Option: Total Monthly
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _isTotalMonthly = true;
                        _selectedCategory = null;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Tổng chi tiêu trong tháng",
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  "Áp dụng cho tất cả khoản chi",
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              LucideIcons.coins,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            _isTotalMonthly
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Grouped Categories
                for (var entry in _expenseGroups.entries)
                  _buildGroup(entry.key, entry.value),
              ],
            ),
          ),

          // Bottom Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
            ),
            child: SafeArea(
              child: ElevatedButton(
                onPressed: (_selectedCategory != null || _isTotalMonthly)
                    ? () async {
                        final navigator = Navigator.of(context);
                        final result = await navigator.push(
                          MaterialPageRoute(
                            builder: (_) => BudgetAmountScreen(
                              categoryName: _isTotalMonthly
                                  ? "Tổng chi tiêu"
                                  : _selectedCategory!,
                              isTotal: _isTotalMonthly,
                              transactions:
                                  widget.transactions, // Pass transactions
                            ),
                          ),
                        );

                        if (!mounted) return;

                        if (result == true) {
                          navigator.pop(
                            true,
                          ); // Return success to refresh report
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.textMuted.withValues(
                    alpha: 0.3,
                  ),
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  "Tiếp tục",
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroup(String title, List<String> categories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8, top: 8),
          child: Text(
            title.toUpperCase(),
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: categories.asMap().entries.map((entry) {
              final isLast = entry.key == categories.length - 1;
              return Column(
                children: [
                  _buildRadioItem(entry.value),
                  if (!isLast)
                    Divider(
                      height: 1,
                      color: Colors.grey.shade100,
                      indent: 64,
                      endIndent: 16,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildRadioItem(String category) {
    final color = CategoryHelper.getColor(category);
    final isSelected = _selectedCategory == category;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedCategory = category;
          _isTotalMonthly = false;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                CategoryHelper.getIcon(category),
                color: color,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                category,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppColors.primary : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}
