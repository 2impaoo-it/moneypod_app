import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../bloc/financial_report/financial_report_bloc.dart';
import '../../bloc/financial_report/financial_report_state.dart';
import '../../bloc/financial_report/financial_report_event.dart';
import '../../main.dart'; // For AppColors
import '../../models/transaction.dart';
import '../../utils/category_helper.dart';
import 'filter_transaction_dialog.dart';

enum CalendarTab { week, month, year }

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
  CalendarTab _currentTab = CalendarTab.week; // Default to Week

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('vi_VN', null);
    _selectedDay = _focusedDay;
  }

  /* void _onViewTypeChanged(ReportType type) {
    setState(() {
      _viewType = type;
      if (type == ReportType.week) {
        _calendarFormat = CalendarFormat.week;
      } else if (type == ReportType.month) {
        _calendarFormat = CalendarFormat.month;
      }
      // Year view logic is handled in _buildContent
    });

    // Reload data if needed
    context.read<FinancialReportBloc>().add(
      LoadReport(
        month: _focusedDay.month,
        year: _focusedDay.year,
        week: 1,
        reportType: type == ReportType.week
            ? ReportType.month
            : type, // Keep monthly data for week view
      ),
    );
  } */

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
          if (state is ReportLoaded) return _buildContent(context, state);
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

    return CustomScrollView(
      slivers: [
        // View Selector
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  _buildViewOption("Tuần", CalendarTab.week),
                  _buildViewOption("Tháng", CalendarTab.month),
                  _buildViewOption("Năm", CalendarTab.year),
                ],
              ),
            ),
          ),
        ),

        // Summary Row (for Month and Year tabs) - at the top
        if (_currentTab == CalendarTab.month || _currentTab == CalendarTab.year)
          SliverToBoxAdapter(child: _buildMonthSummary(state)),

        // Content
        if (_currentTab == CalendarTab.week)
          SliverToBoxAdapter(child: _buildCalendar(state))
        else if (_currentTab == CalendarTab.month)
          _buildMonthGrid(state)
        else if (_currentTab == CalendarTab.year)
          SliverToBoxAdapter(child: _buildYearControl()),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        // Active Filter Chips (Keep or refactor? It was below calendar before.
        // I'll keep it here if not redundant.
        // Actually, the previous code had it in _buildContent.
        // It's useful to show filters on top of the list.)
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

        // Transaction List
        SliverToBoxAdapter(
          child: _buildTransactionList(state.data.transactions, currencyFormat),
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
      // For Year tab: filter by year only
      // For Month tab: filter by month AND year
      if (_currentTab == CalendarTab.year) {
        if (tx.date.year != _focusedDay.year) {
          continue;
        }
      } else {
        // Month tab or Week tab
        if (tx.date.month != _focusedDay.month ||
            tx.date.year != _focusedDay.year) {
          continue;
        }
      }

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
    List<Transaction> allTransactions, {
    bool isSelected = false,
    bool isToday = false,
  }) {
    // Calculate daily totals
    double dailyIncome = 0;
    double dailyExpense = 0;
    for (var t in allTransactions) {
      if (isSameDay(t.date, day)) {
        // We only show dots/numbers for data present, ignoring filters for the calendar grid?
        // Or should we respect filters? The user wants to see "Lịch" which implies overview.
        // Let's respect filters if set, consistent with list.
        if (_selectedCategories.isNotEmpty &&
            !_selectedCategories.contains(t.category)) {
          continue;
        }

        if (t.type == 'income') {
          dailyIncome += t.amount;
        } else {
          dailyExpense += t.amount;
        }
      }
    }

    final hasData = dailyIncome > 0 || dailyExpense > 0;

    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withOpacity(0.1)
            : (isToday ? Colors.blue.withOpacity(0.08) : null),
        border: isSelected
            ? Border.all(color: AppColors.primary, width: 1.5)
            : (isToday
                  ? Border.all(color: Colors.blue.withOpacity(0.5), width: 1.5)
                  : null),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            '${day.day}',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: (isSelected || isToday)
                  ? FontWeight.bold
                  : FontWeight.normal,
              color: isSelected
                  ? AppColors.primary
                  : (isToday ? Colors.blue : Colors.black87),
            ),
          ),
          // Dot indicator for today
          if (isToday)
            Container(
              margin: const EdgeInsets.only(top: 2),
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            ),
          const Spacer(),
          if (hasData) ...[
            if (dailyIncome > 0)
              Text(
                NumberFormat.compact(locale: 'en_US').format(dailyIncome),
                style: GoogleFonts.inter(
                  fontSize: 9,
                  color: Colors.blue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            if (dailyExpense > 0)
              Text(
                NumberFormat.compact(locale: 'en_US').format(dailyExpense),
                style: GoogleFonts.inter(
                  fontSize: 9,
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            const SizedBox(height: 2),
          ],
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Transaction tx, NumberFormat currencyFormat) {
    final isIncome = tx.type == 'income';
    final color = CategoryHelper.getColor(tx.category);
    final bgColor = CategoryHelper.getBackgroundColor(tx.category);

    return GestureDetector(
      onTap: () => _showTransactionDetails(context, tx, currencyFormat),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12), // Square rounded
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
                    "${tx.title.isNotEmpty ? '${tx.title} • ' : ''}${DateFormat('HH:mm').format(tx.date)}",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              currencyFormat.format(tx.amount),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isIncome ? AppColors.success : AppColors.danger,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTransactionDetails(
    BuildContext context,
    Transaction tx,
    NumberFormat currencyFormat,
  ) {
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
            if (tx.title.isNotEmpty) _buildDetailRow('Ghi chú', tx.title),
            if (tx.walletName != null) _buildDetailRow('Ví', tx.walletName!),

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

  Widget _buildViewOption(String label, CalendarTab tab) {
    bool isSelected = _currentTab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabChanged(tab),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.black : Colors.grey[600],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthGrid(ReportLoaded state) {
    return SliverPadding(
      padding: const EdgeInsets.all(16.0),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          // Year Picker Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DropdownButton<int>(
                  value: _focusedDay.year,
                  items:
                      List.generate(
                            11,
                            (index) => DateTime.now().year - 5 + index,
                          )
                          .map(
                            (year) => DropdownMenuItem(
                              value: year,
                              child: Text(
                                "$year",
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: (year) {
                    if (year != null) {
                      setState(() {
                        _focusedDay = DateTime(year, _focusedDay.month, 1);
                      });
                      context.read<FinancialReportBloc>().add(
                        LoadReport(
                          month: _focusedDay.month,
                          year: year,
                          week: 1,
                          reportType: ReportType.month,
                        ),
                      );
                    }
                  },
                  underline: const SizedBox(),
                  icon: const Icon(Icons.arrow_drop_down),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.8,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: 12,
            itemBuilder: (context, index) {
              final month = index + 1;
              final trend = state.data.trends.firstWhere(
                (t) => t.month == month,
                orElse: () => MonthlyTrend(
                  month: month,
                  year: _focusedDay.year,
                  income: 0,
                  expense: 0,
                ),
              );

              final isSelected = _focusedDay.month == month;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _focusedDay = DateTime(_focusedDay.year, month, 1);
                  });
                  context.read<FinancialReportBloc>().add(
                    LoadReport(
                      month: month,
                      year: _focusedDay.year,
                      week: 1,
                      reportType: ReportType.month,
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? Border.all(color: AppColors.primary, width: 2)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (month == DateTime.now().month &&
                          _focusedDay.year == DateTime.now().year)
                        Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      Text(
                        "Tháng $month",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isSelected
                              ? AppColors.primary
                              : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (trend.income > 0)
                        Text(
                          NumberFormat.compact(
                            locale: 'vi',
                          ).format(trend.income),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.blue,
                          ),
                        ),
                      if (trend.expense > 0)
                        Text(
                          NumberFormat.compact(
                            locale: 'vi',
                          ).format(trend.expense),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.red,
                          ),
                        ),
                      if (trend.income == 0 && trend.expense == 0)
                        Text(
                          "-",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ]),
      ),
    );
  }

  Widget _buildYearControl() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(LucideIcons.chevronLeft),
            onPressed: () {
              setState(() {
                _focusedDay = DateTime(
                  _focusedDay.year - 1,
                  _focusedDay.month,
                  1,
                );
              });
              // Reload data for new year
              _onTabChanged(CalendarTab.year);
            },
          ),
          const SizedBox(width: 24),
          Text(
            "${_focusedDay.year}",
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 24),
          IconButton(
            icon: const Icon(LucideIcons.chevronRight),
            onPressed: () {
              setState(() {
                _focusedDay = DateTime(
                  _focusedDay.year + 1,
                  _focusedDay.month,
                  1,
                );
              });
              _onTabChanged(CalendarTab.year);
            },
          ),
        ],
      ),
    );
  }

  void _onTabChanged(CalendarTab tab) {
    setState(() {
      _currentTab = tab;
      _focusedDay = DateTime.now(); // Reset to current date on tab switch
      _selectedDay = _focusedDay;
    });

    final reportType = tab == CalendarTab.week
        ? ReportType.month
        : ReportType.year;

    context.read<FinancialReportBloc>().add(
      LoadReport(
        month: _focusedDay.month,
        year: _focusedDay.year,
        week: 1,
        reportType: reportType,
      ),
    );
  }

  Widget _buildCalendar(ReportLoaded state) {
    return Column(
      children: [
        _buildMonthSummary(state),
        Container(
          color: Colors.white,
          child: TableCalendar(
            firstDay: DateTime(2020),
            lastDay: DateTime(2040),
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
              _focusedDay = focusedDay;
              context.read<FinancialReportBloc>().add(
                LoadReport(
                  month: focusedDay.month,
                  year: focusedDay.year,
                  week: 1,
                  reportType: ReportType.month,
                ),
              );
            },
            calendarFormat:
                CalendarFormat.month, // Always Month format for Week Tab
            locale: 'vi_VN',
            availableCalendarFormats: const {CalendarFormat.month: 'Tháng'},
            startingDayOfWeek: StartingDayOfWeek.monday,
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            calendarStyle: const CalendarStyle(
              // Hide default today decoration since we use custom todayBuilder
              todayDecoration: BoxDecoration(),
              todayTextStyle: TextStyle(),
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                return _buildCalendarCell(day, state.data.transactions);
              },
              selectedBuilder: (context, day, focusedDay) {
                return _buildCalendarCell(
                  day,
                  state.data.transactions,
                  isSelected: true,
                );
              },
              todayBuilder: (context, day, focusedDay) {
                return _buildCalendarCell(
                  day,
                  state.data.transactions,
                  isToday: true,
                );
              },
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
    );
  }

  Widget _buildTransactionList(
    List<Transaction> allTransactions,
    NumberFormat currencyFormat,
  ) {
    List<Transaction> filteredTransactions = [];
    String headerTitle = "";

    if (_currentTab == CalendarTab.week) {
      if (_selectedDay != null) {
        // Filter for the week containing _selectedDay
        // Calculate start and end of week (Monday to Sunday)
        // DateTime weekday 1 is Monday, 7 is Sunday.
        final startOfWeek = _selectedDay!.subtract(
          Duration(days: _selectedDay!.weekday - 1),
        );
        final endOfWeek = startOfWeek.add(const Duration(days: 6));

        // Normalize dates to ignore time for comparison
        final start = DateTime(
          startOfWeek.year,
          startOfWeek.month,
          startOfWeek.day,
        );
        final end = DateTime(
          endOfWeek.year,
          endOfWeek.month,
          endOfWeek.day,
          23,
          59,
          59,
        );

        filteredTransactions = allTransactions.where((t) {
          if (_selectedCategories.isNotEmpty &&
              !_selectedCategories.contains(t.category)) {
            return false;
          }
          return t.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
              t.date.isBefore(end.add(const Duration(seconds: 1)));
        }).toList();

        headerTitle =
            "Giao dịch tuần ${DateFormat('dd/MM', 'vi_VN').format(start)} - ${DateFormat('dd/MM', 'vi_VN').format(end)}";
      }
    } else if (_currentTab == CalendarTab.month) {
      // Filter for the selected Month (_focusedDay)
      filteredTransactions = allTransactions.where((t) {
        if (_selectedCategories.isNotEmpty &&
            !_selectedCategories.contains(t.category)) {
          return false;
        }
        return t.date.month == _focusedDay.month &&
            t.date.year == _focusedDay.year;
      }).toList();
      headerTitle =
          "Giao dịch tháng ${DateFormat('MM/yyyy', 'vi_VN').format(_focusedDay)}";
    } else if (_currentTab == CalendarTab.year) {
      // Filter for the selected Year (_focusedDay)
      filteredTransactions = allTransactions.where((t) {
        if (_selectedCategories.isNotEmpty &&
            !_selectedCategories.contains(t.category)) {
          return false;
        }
        return t.date.year == _focusedDay.year;
      }).toList();
      headerTitle = "Giao dịch năm ${_focusedDay.year}";
    }

    filteredTransactions.sort((a, b) => b.date.compareTo(a.date));

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            headerTitle,
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const Divider(height: 24),
          if (filteredTransactions.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  "Không có giao dịch",
                  style: GoogleFonts.inter(color: Colors.grey),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredTransactions.length,
              itemBuilder: (context, index) {
                final t = filteredTransactions[index];
                return _buildTransactionItem(t, currencyFormat);
              },
            ),
        ],
      ),
    );
  }
}
