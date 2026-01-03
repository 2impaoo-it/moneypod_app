import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../bloc/financial_report/financial_report_bloc.dart';
import '../../bloc/financial_report/financial_report_state.dart';
import '../../main.dart'; // For AppColors
import '../../models/transaction.dart';
import '../../utils/category_helper.dart';
import 'filter_transaction_dialog.dart';

class StatisticsCalendarScreen extends StatefulWidget {
  const StatisticsCalendarScreen({super.key});

  @override
  State<StatisticsCalendarScreen> createState() =>
      _StatisticsCalendarScreenState();
}

class _StatisticsCalendarScreenState extends State<StatisticsCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Set<String> _selectedCategories = {}; // Filter categories

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Lịch"),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(LucideIcons.slidersHorizontal),
                if (_selectedCategories.isNotEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${_selectedCategories.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () async {
              final result = await showModalBottomSheet<Set<String>>(
                context: context,
                isScrollControlled: true,
                useRootNavigator: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const FilterTransactionDialog(),
              );

              if (result != null) {
                setState(() {
                  _selectedCategories = result;
                });
              }
            },
          ),
        ],
      ),
      body: BlocBuilder<FinancialReportBloc, FinancialReportState>(
        builder: (context, state) {
          if (state is ReportLoaded) {
            if (_focusedDay.month != state.currentMonth ||
                _focusedDay.year != state.currentYear) {
              _focusedDay = DateTime(state.currentYear, state.currentMonth, 1);
              if (_selectedDay != null &&
                  (_selectedDay!.month != state.currentMonth ||
                      _selectedDay!.year != state.currentYear)) {
                _selectedDay = _focusedDay;
              }
            }

            return _buildContent(context, state);
          }
          if (state is ReportLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ReportError) {
            return Center(child: Text("Lỗi: ${state.message}"));
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, ReportLoaded state) {
    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    );

    // Get transactions for selected day
    List<Transaction> selectedTransactions = [];
    if (_selectedDay != null) {
      selectedTransactions = state.data.transactions.where((t) {
        final sameDay = isSameDay(t.date, _selectedDay);
        // Apply filter if categories are selected
        if (_selectedCategories.isNotEmpty) {
          return sameDay && _selectedCategories.contains(t.category);
        }
        return sameDay;
      }).toList();
    }

    // Sort by recent
    selectedTransactions.sort((a, b) => b.date.compareTo(a.date));

    return CustomScrollView(
      slivers: [
        // Summary & Calendar
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMonthSummary(state),
              Container(
                color: Colors.white,
                child: TableCalendar(
                  firstDay: DateTime(2020),
                  lastDay: DateTime(2030),
                  focusedDay: _focusedDay,
                  currentDay: DateTime.now(),
                  rowHeight: 80,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  onPageChanged: (focusedDay) {
                    setState(() {
                      _focusedDay = focusedDay;
                    });
                  },
                  calendarFormat: CalendarFormat.month,
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (context, day, focusedDay) =>
                        _buildCalendarCell(day, state),
                    selectedBuilder: (context, day, focusedDay) => Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        border: Border.all(color: AppColors.primary),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _buildCalendarCell(day, state, isSelected: true),
                    ),
                    todayBuilder: (context, day, focusedDay) => Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _buildCalendarCell(day, state),
                    ),
                    outsideBuilder: (context, day, focusedDay) =>
                        const SizedBox.shrink(),
                  ),
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                    weekendStyle: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.danger,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Active Filter Chips
        if (_selectedCategories.isNotEmpty)
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Text(
                      "Lọc: ",
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    ..._selectedCategories.map(
                      (cat) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Chip(
                          label: Text(cat),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () {
                            setState(() {
                              _selectedCategories.remove(cat);
                            });
                          },
                          backgroundColor: CategoryHelper.getBackgroundColor(
                            cat,
                          ),
                          labelStyle: GoogleFonts.inter(
                            fontSize: 12,
                            color: CategoryHelper.getColor(cat),
                          ),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedCategories.clear();
                        });
                      },
                      child: Text(
                        "Xóa tất cả",
                        style: GoogleFonts.inter(
                          color: AppColors.danger,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Date Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              DateFormat('d/M/yyyy').format(_selectedDay ?? DateTime.now()),
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),

        // Transaction List
        selectedTransactions.isEmpty
            ? SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          LucideIcons.inbox,
                          size: 48,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _selectedCategories.isEmpty
                              ? "Không có giao dịch"
                              : "Không có giao dịch cho bộ lọc đã chọn",
                          style: GoogleFonts.inter(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final tx = selectedTransactions[index];
                  return _buildTransactionItem(tx, currencyFormat);
                }, childCount: selectedTransactions.length),
              ),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildMonthSummary(ReportLoaded state) {
    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    );

    // Calculate totals (apply filter if active)
    double totalIncome = 0;
    double totalExpense = 0;

    for (var tx in state.data.transactions) {
      if (_selectedCategories.isNotEmpty &&
          !_selectedCategories.contains(tx.category)) {
        continue;
      }
      if (tx.type == 'income') {
        totalIncome += tx.amount;
      } else {
        totalExpense += tx.amount;
      }
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
            "Thu nhập",
            currencyFormat.format(totalIncome),
            AppColors.success,
          ),
          Container(height: 40, width: 1, color: Colors.grey[200]),
          _buildSummaryItem(
            "Chi tiêu",
            currencyFormat.format(totalExpense),
            AppColors.danger,
          ),
          Container(height: 40, width: 1, color: Colors.grey[200]),
          _buildSummaryItem(
            "Chênh lệch",
            currencyFormat.format(totalIncome - totalExpense),
            totalIncome >= totalExpense ? AppColors.success : AppColors.danger,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarCell(
    DateTime day,
    ReportLoaded state, {
    bool isSelected = false,
  }) {
    final dailyIncome = state.data.dailyIncome[day.day] ?? 0;
    final dailyExpense = state.data.dailyExpense[day.day] ?? 0;

    String formatK(double amount) {
      if (amount >= 1000000) {
        return "${(amount / 1000000).toStringAsFixed(1)}M";
      } else if (amount >= 1000) {
        return "${(amount / 1000).toStringAsFixed(0)}K";
      }
      return amount.toStringAsFixed(0);
    }

    if (day.month != state.currentMonth) return const SizedBox.shrink();

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        Text(
          day.day.toString(),
          style: GoogleFonts.inter(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
            color: isSelected ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        if (dailyIncome > 0)
          Text(
            "+${formatK(dailyIncome)}",
            style: GoogleFonts.inter(
              fontSize: 9,
              color: AppColors.success,
              fontWeight: FontWeight.w500,
            ),
          ),
        if (dailyExpense > 0)
          Text(
            "-${formatK(dailyExpense)}",
            style: GoogleFonts.inter(
              fontSize: 9,
              color: AppColors.danger,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }

  Widget _buildTransactionItem(Transaction tx, NumberFormat currencyFormat) {
    final isIncome = tx.type == 'income';
    final color = CategoryHelper.getColor(tx.category);
    final bgColor = CategoryHelper.getBackgroundColor(tx.category);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              CategoryHelper.getIcon(tx.category),
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.category,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "${tx.title} • ${DateFormat('HH:mm').format(tx.date)}",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            "${isIncome ? '+' : '-'}${currencyFormat.format(tx.amount)}",
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isIncome ? AppColors.success : AppColors.danger,
            ),
          ),
        ],
      ),
    );
  }
}
