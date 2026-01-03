import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // Import Bloc
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../main.dart'; // For AppColors
import '../../utils/category_helper.dart';

import '../../models/transaction.dart';
import '../../bloc/budget/budget_bloc.dart'; // Import BudgetBloc
import '../../bloc/budget/budget_event.dart';
import '../../bloc/budget/budget_state.dart';

class BudgetAmountScreen extends StatefulWidget {
  final String categoryName;
  final bool isTotal;
  final List<Transaction>? transactions;

  const BudgetAmountScreen({
    super.key,
    required this.categoryName,
    this.isTotal = false,
    this.transactions,
  });

  @override
  State<BudgetAmountScreen> createState() => _BudgetAmountScreenState();
}

class _BudgetAmountScreenState extends State<BudgetAmountScreen> {
  final TextEditingController _amountController = TextEditingController();
  bool _isFormValid = false;
  late List<FlSpot> _yearlySpots;
  double _averageSpending = 0;
  double _maxSpending = 1000000;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_validateForm);
    _calculateRealData();
  }

  void _validateForm() {
    setState(() {
      _isFormValid = _amountController.text.isNotEmpty;
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _calculateRealData() {
    if (widget.transactions == null || widget.transactions!.isEmpty) {
      _generateMockData();
      return;
    }

    final now = DateTime.now();
    final Map<int, double> monthlySpending = {};

    final releventTxs = widget.transactions!.where((t) {
      if (t.type != 'expense') return false;
      if (widget.isTotal) return true;
      return t.category == widget.categoryName;
    }).toList();

    if (releventTxs.isEmpty) {
      _generateMockData();
      return;
    }

    for (int i = 0; i < 6; i++) {
      final monthDate = DateTime(now.year, now.month - i);
      final monthKey = monthDate.month;
      monthlySpending[monthKey] = 0;

      for (var t in releventTxs) {
        if (t.date.month == monthKey && t.date.year == monthDate.year) {
          monthlySpending[monthKey] =
              (monthlySpending[monthKey] ?? 0) + t.amount;
        }
      }
    }

    final List<FlSpot> spots = [];
    double total = 0;
    double maxVal = 0;

    for (int i = 5; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i);
      final val = monthlySpending[monthDate.month] ?? 0;
      spots.add(FlSpot((5 - i).toDouble(), val));
      total += val;
      if (val > maxVal) maxVal = val;
    }

    setState(() {
      _yearlySpots = spots;
      _averageSpending = total / 6;
      _maxSpending = maxVal > 0 ? maxVal * 1.2 : 1000000;
    });
  }

  void _generateMockData() {
    _yearlySpots = [
      const FlSpot(0, 500000),
      const FlSpot(1, 1500000),
      const FlSpot(2, 800000),
      const FlSpot(3, 2000000),
      const FlSpot(4, 1200000),
      const FlSpot(5, 3000000),
    ];
    _averageSpending = 1500000;
    _maxSpending = 3500000;
  }

  void _onComplete() {
    if (!_isFormValid) return;

    final amountStr = _amountController.text.replaceAll('.', '');
    final double amount = double.tryParse(amountStr) ?? 0;

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số tiền hợp lệ')),
      );
      return;
    }

    final now = DateTime.now();

    // Dispatch Create Event
    context.read<BudgetBloc>().add(
      BudgetCreateRequested(
        category: widget.categoryName,
        amount: amount,
        month: now.month,
        year: now.year,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BudgetBloc, BudgetState>(
      listener: (context, state) {
        if (state is BudgetOperationSuccess) {
          Navigator.pop(context, true); // Return true to signal success
        }
        if (state is BudgetError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: const BackButton(color: Colors.black),
          title: Text(
            "Tạo ngân sách",
            style: GoogleFonts.inter(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                CategoryHelper.getIcon(widget.categoryName),
                                size: 40,
                                color: CategoryHelper.getColor(
                                  widget.categoryName,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              widget.categoryName,
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      Text(
                        "Số tiền",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        autofocus: true,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          ThousandsFormatter(),
                        ],
                        style: GoogleFonts.inter(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                        decoration: InputDecoration(
                          hintText: "0",
                          suffixText: "đ",
                          suffixStyle: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const Divider(height: 1, color: Color(0xFFE2E8F0)),
                      const SizedBox(height: 40),

                      // "Stats" Section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  LucideIcons.lightbulb, // Use valid icon
                                  size: 20,
                                  color: Colors.orange,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Tham khảo thống kê chi tiêu của bạn",
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Xu hướng 6 tháng",
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    "Trung bình: ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0).format(_averageSpending)}",
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 150,
                              child: BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.spaceBetween,
                                  maxY: _maxSpending, // Based on max spending
                                  barTouchData: BarTouchData(enabled: false),
                                  titlesData: FlTitlesData(
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    rightTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    topTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          // Map 0..5 to Tx..CurrentMonth
                                          final now = DateTime.now();
                                          // 5 is current, 0 is 5 months ago
                                          final month = DateTime(
                                            now.year,
                                            now.month - (5 - value.toInt()),
                                          ).month;
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              top: 8,
                                            ),
                                            child: Text(
                                              "T$month",
                                              style: GoogleFonts.inter(
                                                color: AppColors.textSecondary,
                                                fontSize: 10,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: false,
                                    getDrawingHorizontalLine: (value) {
                                      return FlLine(
                                        color: Colors.black.withOpacity(0.05),
                                        strokeWidth: 1,
                                        dashArray: [4, 4],
                                      );
                                    },
                                  ),
                                  borderData: FlBorderData(show: false),
                                  barGroups: _yearlySpots.asMap().entries.map((
                                    e,
                                  ) {
                                    return BarChartGroupData(
                                      x: e.key,
                                      barRods: [
                                        BarChartRodData(
                                          toY: e.value.y,
                                          color: e.key == 5
                                              ? AppColors.primary
                                              : AppColors.primary.withOpacity(
                                                  0.3,
                                                ),
                                          width: 12,
                                          borderRadius: BorderRadius.circular(
                                            2,
                                          ),
                                          backDrawRodData:
                                              BackgroundBarChartRodData(
                                                show: true,
                                                toY: _maxSpending, // Max
                                                color: Colors.white,
                                              ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              BlocBuilder<BudgetBloc, BudgetState>(
                builder: (context, state) {
                  final isLoading = state is BudgetLoading;
                  return Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (_isFormValid && !isLoading)
                            ? _onComplete
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor: AppColors.primary
                              .withOpacity(0.5),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                "Hoàn tất",
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final String cleanText = newValue.text.replaceAll('.', '');
    final number = int.tryParse(cleanText);

    if (number == null) {
      return oldValue;
    }

    final String newText = NumberFormat(
      '#,###',
      'vi_VN',
    ).format(number).replaceAll(',', '.');

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
