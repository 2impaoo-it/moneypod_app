import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../bloc/financial_report/financial_report_bloc.dart';
import '../../bloc/financial_report/financial_report_event.dart';
import '../../bloc/financial_report/financial_report_state.dart';
import '../../models/transaction.dart';
import '../../utils/category_helper.dart';
import 'package:go_router/go_router.dart';
import '../../main.dart'; // For AppColors

class FinancialReportScreen extends StatefulWidget {
  const FinancialReportScreen({super.key});

  @override
  State<FinancialReportScreen> createState() => _FinancialReportScreenState();
}

class _FinancialReportScreenState extends State<FinancialReportScreen>
    with SingleTickerProviderStateMixin {
  late DateTime _selectedDate;
  int _selectedWeek = 1; // Week 1-4/5
  bool _hideAmounts = false; // Toggle for hiding amounts
  late TabController _tabController;
  int _selectedSubTab =
      2; // Default to Difference (0: Income, 1: Expense, 2: Difference)
  String? _selectedCategory; // For pie chart category highlight
  int _touchedBarIndex = -1; // For bar chart tooltip

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _selectedWeek = _getWeekOfMonth(_selectedDate);
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: 1, // Default to 'Theo tháng'
    );
    _tabController.addListener(_onTabChanged);
    _loadReport(); // Load default (Month)
  }

  int _getWeekOfMonth(DateTime date) {
    final firstDayOfMonth = DateTime(date.year, date.month, 1);
    final dayOfMonth = date.day;
    return ((dayOfMonth + firstDayOfMonth.weekday - 2) ~/ 7) + 1;
  }

  int _getWeeksInMonth(int year, int month) {
    final lastDay = DateTime(year, month + 1, 0).day;
    final firstDayWeekday = DateTime(year, month, 1).weekday;
    return ((lastDay + firstDayWeekday - 2) ~/ 7) + 1;
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      // Trigger load when tab IS changing (animation start)
      _loadReport();
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _loadReport() {
    ReportType type = ReportType.month;
    if (_tabController.index == 0) {
      type = ReportType.week;
    } else if (_tabController.index == 2) {
      type = ReportType.year;
    }

    context.read<FinancialReportBloc>().add(
      LoadReport(
        month: _selectedDate.month,
        year: _selectedDate.year,
        week: _selectedWeek,
        reportType: type,
      ),
    );
  }

  void _changePeriod(int offset) {
    setState(() {
      if (_tabController.index == 0) {
        // Week navigation
        final maxWeeks = _getWeeksInMonth(
          _selectedDate.year,
          _selectedDate.month,
        );
        _selectedWeek += offset;
        if (_selectedWeek > maxWeeks) {
          _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1);
          _selectedWeek = 1;
        } else if (_selectedWeek < 1) {
          _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1);
          _selectedWeek = _getWeeksInMonth(
            _selectedDate.year,
            _selectedDate.month,
          );
        }
      } else if (_tabController.index == 2) {
        // Year navigation
        _selectedDate = DateTime(
          _selectedDate.year + offset,
          _selectedDate.month,
        );
      } else {
        // Month navigation
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month + offset,
        );
      }
    });
    _loadReport();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Biến động thu chi"),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.wallet), // Budget Icon
            color: AppColors.textPrimary,
            onPressed: () {
              context.push('/budget-list');
            },
          ),
          IconButton(
            icon: const Icon(LucideIcons.calendar), // Calendar Icon
            color: AppColors.textPrimary,
            onPressed: () async {
              await context.push('/calendar');
              _loadReport();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: "Theo tuần"),
            Tab(text: "Theo tháng"),
            Tab(text: "Theo năm"),
          ],
        ),
      ),
      body: BlocBuilder<FinancialReportBloc, FinancialReportState>(
        builder: (context, state) {
          if (state is ReportLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ReportError) {
            return Center(child: Text("Lỗi: ${state.message}"));
          }
          if (state is ReportLoaded) {
            return _buildMonthView(context, state);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  // Remove _buildPlaceholderView entirely as we use BlocBuilder

  Widget _buildMonthView(BuildContext context, ReportLoaded state) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildMonthPicker(),
          const SizedBox(height: 16),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: [
                _buildSubTabButton("Thu nhập", 0),
                const SizedBox(width: 8),
                _buildSubTabButton("Chi tiêu", 1),
                const SizedBox(width: 8),
                _buildSubTabButton("Chênh lệch", 2),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildMainContent(state),
        ],
      ),
    );
  }

  Widget _buildSubTabButton(String title, int index) {
    final isSelected = _selectedSubTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedSubTab = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : AppColors.background,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? (_selectedSubTab == 1
                        ? Colors
                              .red // Expense - Red
                        : (_selectedSubTab == 0
                              ? Colors
                                    .blue // Income - Blue
                              : Colors.orange)) // Difference - Orange
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(ReportLoaded state) {
    double currentAmount = 0;
    double prevAmount = 0;
    String title = "";
    String periodLabel = "";
    String prevPeriodLabel = "";

    // Determine labels based on report type
    if (state.reportType == ReportType.year) {
      periodLabel = "năm nay";
      prevPeriodLabel = "năm trước";
    } else if (state.reportType == ReportType.week) {
      periodLabel = "tuần này";
      prevPeriodLabel = "tuần trước";
    } else {
      periodLabel = "tháng này";
      prevPeriodLabel = "tháng trước";
    }

    // Data selection
    if (_selectedSubTab == 0) {
      // Salary / Income
      currentAmount = state.data.totalIncome;
      prevAmount = state.data.previousMonthIncome;
      title = "Tổng thu $periodLabel";
    } else if (_selectedSubTab == 1) {
      // Expense
      currentAmount = state.data.totalExpense;
      prevAmount = state.data.previousMonthExpense;
      title = "Tổng chi $periodLabel";
    } else {
      // Difference
      currentAmount = state.data.totalIncome - state.data.totalExpense;
      prevAmount =
          state.data.previousMonthIncome - state.data.previousMonthExpense;
      title = "Tổng chênh lệch $periodLabel";
    }

    final diff = currentAmount - prevAmount;
    final isIncrease = diff > 0;
    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    );

    // Calculate Max Y for Chart based on Trends
    double maxY = 0;
    for (var t in state.data.trends) {
      double val = _selectedSubTab == 0
          ? t.income
          : (_selectedSubTab == 1 ? t.expense : (t.income - t.expense).abs());
      if (val > maxY) maxY = val;
    }
    if (maxY == 0) maxY = 100000; // Default min height

    return SingleChildScrollView(
      child: Column(
        children: [
          // Total Amount
          Text(
            title, // Restore title usage
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),

          // Total Amount with Eye Button
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                !_hideAmounts ? currencyFormat.format(currentAmount) : '******',
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.normal,
                  color: _selectedSubTab == 1
                      ? Colors.red
                      : (_selectedSubTab == 2
                            ? Colors.orange
                            : AppColors.primary),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  _hideAmounts ? LucideIcons.eyeOff : LucideIcons.eye,
                  size: 20,
                ),
                color: AppColors.textSecondary,
                onPressed: () {
                  setState(() {
                    _hideAmounts = !_hideAmounts;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Banner (Hide if future)
          if (_selectedDate.isBefore(DateTime.now()) ||
              (_selectedDate.month == DateTime.now().month &&
                  _selectedDate.year == DateTime.now().year))
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: isIncrease
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isIncrease
                        ? LucideIcons.trendingUp
                        : LucideIcons.trendingDown,
                    size: 16,
                    color: isIncrease ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    // Ensure text wraps if needed
                    child: Text(
                      "${isIncrease ? 'Tăng' : 'Giảm'} ${currencyFormat.format(diff.abs())} so với cùng kỳ $prevPeriodLabel",
                      style: GoogleFonts.inter(
                        color: isIncrease
                            ? Colors.green
                            : Colors.red, // Text matches icon
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    LucideIcons.info,
                    size: 14,
                    color: isIncrease ? Colors.green : Colors.red,
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // Chart Section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Chart Legend
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_selectedSubTab == 2) ...[
                      // Chênh lệch tab: show both legends
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Thu nhập",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Chi tiêu",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ] else ...[
                      // Thu nhập / Chi tiêu tab: show single legend
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _selectedSubTab == 0
                              ? Colors.green
                              : Colors.red,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _selectedSubTab == 0 ? "Thu nhập" : "Chi tiêu",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),

                Container(
                  height: 300,
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: (() {
                        double m = 0;
                        for (int i = 0; i < state.data.trends.length; i++) {
                          double val;
                          if (_selectedSubTab == 0) {
                            val = state.data.trends[i].income;
                          } else if (_selectedSubTab == 1) {
                            val = state.data.trends[i].expense;
                          } else {
                            // Difference tab: get max of both income and expense
                            val =
                                state.data.trends[i].income >
                                    state.data.trends[i].expense
                                ? state.data.trends[i].income
                                : state.data.trends[i].expense;
                          }
                          if (val > m) m = val;
                        }
                        return m == 0 ? 10.0 : m * 1.2;
                      })(),
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          tooltipBgColor: Colors.blueGrey,
                          tooltipPadding: const EdgeInsets.all(8),
                          tooltipMargin: 8,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            if (groupIndex >= state.data.trends.length) {
                              return null;
                            }
                            final item = state.data.trends[groupIndex];
                            final currencyFormat = NumberFormat.compact(
                              locale: 'vi_VN',
                            );

                            // For Difference tab (2 bars): show only relevant value
                            if (_selectedSubTab == 2) {
                              if (rodIndex == 0) {
                                // Green bar - Income only
                                return BarTooltipItem(
                                  'Thu: ${currencyFormat.format(item.income)}',
                                  GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                );
                              } else {
                                // Red bar - Expense only
                                return BarTooltipItem(
                                  'Chi: ${currencyFormat.format(item.expense)}',
                                  GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                );
                              }
                            }

                            // For Income/Expense tabs: show single value
                            final isIncome = _selectedSubTab == 0;
                            return BarTooltipItem(
                              isIncome
                                  ? 'Thu: ${currencyFormat.format(item.income)}'
                                  : 'Chi: ${currencyFormat.format(item.expense)}',
                              GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                        touchCallback: (FlTouchEvent event, barTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                barTouchResponse == null ||
                                barTouchResponse.spot == null) {
                              _touchedBarIndex = -1;
                              return;
                            }
                            _touchedBarIndex =
                                barTouchResponse.spot!.touchedBarGroupIndex;
                          });
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              if (value == 0) return const SizedBox.shrink();
                              return Text(
                                NumberFormat.compact(
                                  locale: 'en_US',
                                ).format(value),
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 10,
                                ),
                              );
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (val, meta) {
                              final index = val.toInt();
                              if (index < 0 ||
                                  index >= state.data.trends.length) {
                                return const SizedBox.shrink();
                              }
                              final item = state.data.trends[index];
                              final isCurrent =
                                  index == state.data.trends.length - 1;

                              String label;
                              if (state.reportType == ReportType.year) {
                                // Year view: Show year labels (2020, 2021, 2022...)
                                // item.month stores the year in year view
                                label = "${item.month}";
                              } else if (state.reportType == ReportType.week) {
                                // Week view: Show week number or "Tuần này"
                                label = isCurrent
                                    ? "Tuần này"
                                    : "T${item.month}";
                              } else {
                                // Month view: Show past 6 months
                                label = isCurrent
                                    ? "Tháng này"
                                    : "T${item.month}";
                              }

                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: isCurrent
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isCurrent
                                        ? Colors.blue
                                        : Colors.grey,
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
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.grey.withOpacity(0.2),
                          strokeWidth: 1,
                          dashArray: [5, 5],
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: [
                        if (state.data.trends.isNotEmpty)
                          for (int i = 0; i < state.data.trends.length; i++)
                            BarChartGroupData(
                              x: i,
                              barRods: _selectedSubTab == 2
                                  // Tab Chênh lệch: Hiển thị 2 cột (Thu nhập + Chi tiêu)
                                  ? [
                                      // Cột Thu nhập (xanh lá)
                                      BarChartRodData(
                                        toY: state.data.trends[i].income,
                                        color: i == _touchedBarIndex
                                            ? Colors.green.shade900
                                            : (i == state.data.trends.length - 1
                                                  ? Colors.green
                                                  : Colors.green.shade200),
                                        width: state.data.trends.length < 7
                                            ? 14
                                            : 7,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                      // Cột Chi tiêu (đỏ)
                                      BarChartRodData(
                                        toY: state.data.trends[i].expense,
                                        color: i == _touchedBarIndex
                                            ? Colors.red.shade900
                                            : (i == state.data.trends.length - 1
                                                  ? Colors.red
                                                  : Colors.red.shade200),
                                        width: state.data.trends.length < 7
                                            ? 14
                                            : 7,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ]
                                  // Tab Thu nhập / Chi tiêu: Hiển thị 1 cột
                                  : [
                                      BarChartRodData(
                                        toY: _selectedSubTab == 0
                                            ? state.data.trends[i].income
                                            : state.data.trends[i].expense,
                                        color: i == _touchedBarIndex
                                            ? (_selectedSubTab == 0
                                                  ? Colors.green.shade900
                                                  : Colors.red.shade900)
                                            : (_selectedSubTab == 0
                                                  ? (i ==
                                                            state
                                                                    .data
                                                                    .trends
                                                                    .length -
                                                                1
                                                        ? Colors.green
                                                        : Colors.green.shade200)
                                                  : (i ==
                                                            state
                                                                    .data
                                                                    .trends
                                                                    .length -
                                                                1
                                                        ? Colors.red
                                                        : Colors.red.shade200)),
                                        width: state.data.trends.length < 7
                                            ? 32
                                            : 16,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ],
                              barsSpace: 4,
                            ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Pie Chart Section
          _buildPieChartSection(state),

          const SizedBox(height: 24),

          // Recent Transactions List
          _buildTransactionList(state.data.transactions),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPieChartSection(ReportLoaded state) {
    if (_selectedSubTab == 2) {
      // For Difference tab, we show Expense breakdown by default (or user preference if we had it)
      // No early return
    }

    // 1. Prepare Data
    // If Tab 0 (Income) -> Show Income
    // If Tab 1 (Expense) -> Show Expense
    // If Tab 2 (Difference) -> Show Expense (as requested/decided)
    final isIncome = _selectedSubTab == 0;
    final relevantTransactions = state.data.transactions.where((t) {
      if (isIncome) return t.type == 'income';
      return t.type == 'expense';
    }).toList();

    if (relevantTransactions.isEmpty) return const SizedBox.shrink();

    // Group by category
    final Map<String, double> categoryMap = {};
    double totalAmount = 0;
    for (var t in relevantTransactions) {
      categoryMap[t.category] = (categoryMap[t.category] ?? 0) + t.amount;
      totalAmount += t.amount;
    }

    final sortedEntries = categoryMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // 2. Build Pie Sections
    List<PieChartSectionData> sections = [];
    for (int i = 0; i < sortedEntries.length; i++) {
      final entry = sortedEntries[i];
      final isSelected = _selectedCategory == entry.key;

      final radius = isSelected ? 75.0 : 60.0;
      final color = CategoryHelper.getColor(entry.key);
      final percentage = (entry.value / totalAmount * 100);

      sections.add(
        PieChartSectionData(
          color: color,
          value: entry.value,
          title: '${percentage.toStringAsFixed(0)}%',
          radius: radius,
          titleStyle: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black, // Dark color for external labels
          ),
          showTitle: true,
          titlePositionPercentageOffset: 1.5, // Move Labels Outside
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 300,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 60,
                  sectionsSpace: 2,
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        // Robust touch handling
                        if (pieTouchResponse != null &&
                            pieTouchResponse.touchedSection != null) {
                          // If valid section touched
                          final index = pieTouchResponse
                              .touchedSection!
                              .touchedSectionIndex;

                          if (index >= 0 && index < sortedEntries.length) {
                            // Only react to TapUp to avoid jitter, OR check for touch down if immediate response preferred.
                            // Using TapUp is generally safer for "clicks".
                            if (event is FlTapUpEvent) {
                              if (_selectedCategory ==
                                  sortedEntries[index].key) {
                                _selectedCategory = null;
                              } else {
                                _selectedCategory = sortedEntries[index].key;
                              }
                            }
                          }
                        } else if (event is FlTapUpEvent) {
                          // If tapped outside (valid response but nil section), deselect
                          // But BEAM CAREFUL: center hole taps might trigger this.
                          // If user wants to deselect, they usually tap the already selected slice or outside.
                          // Tapping outside strictly causing deselect is standard behavior but can be annoying if accidentally triggered.
                          // Given user complaint, I will DISABLE "tap outside deselect" to prioritize "tap slice selects".
                          // _selectedCategory = null;
                        }
                      });
                    },
                  ),
                ),
              ),
              // Center Info
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isIncome ? "Tổng thu" : "Tổng chi",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isIncome ? Colors.blue : Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    !_hideAmounts
                        ? NumberFormat.compact(
                            locale: 'vi_VN',
                          ).format(totalAmount)
                        : '******',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isIncome ? Colors.blue : Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Category Legend List
        ...sortedEntries.map((e) {
          final isSelected = _selectedCategory == e.key;
          final percentage = (e.value / totalAmount * 100).toStringAsFixed(1);
          return InkWell(
            onTap: () {
              setState(() {
                if (_selectedCategory == e.key) {
                  _selectedCategory = null;
                } else {
                  _selectedCategory = e.key;
                }
              });
            },
            child: Container(
              color: isSelected ? Colors.blue.withOpacity(0.1) : null,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: CategoryHelper.getColor(e.key),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      e.key,
                      style: GoogleFonts.inter(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  Text(
                    !_hideAmounts
                        ? '${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(e.value)} ($percentage%)'
                        : '$percentage%',
                    style: GoogleFonts.inter(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTransactionList(List<Transaction> transactions) {
    if (transactions.isEmpty) return const SizedBox.shrink();

    // Filter based on selected sub-tab
    List<Transaction> filteredTransactions;
    if (_selectedSubTab == 0) {
      // Income only
      filteredTransactions = transactions
          .where((t) => t.type == 'income')
          .toList();
    } else if (_selectedSubTab == 1) {
      // Expense only
      filteredTransactions = transactions
          .where((t) => t.type == 'expense')
          .toList();
    } else {
      // Difference tab - show all
      filteredTransactions = transactions;
    }

    // Filter by selected category from Pie Chart
    if (_selectedCategory != null) {
      filteredTransactions = filteredTransactions
          .where((t) => t.category == _selectedCategory)
          .toList();
    }

    if (filteredTransactions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: Text("Không có giao dịch")),
      );
    }

    // Limit to 5 items to show "Recent" unless filtered by category (then show all)
    final displayList = _selectedCategory != null
        ? filteredTransactions
        : filteredTransactions.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            "Giao dịch gần đây",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: displayList.length,
          itemBuilder: (context, index) {
            final t = displayList[index];
            final categoryColor = CategoryHelper.getColor(t.category);
            final backgroundColor = CategoryHelper.getBackgroundColor(
              t.category,
            );

            return ListTile(
              onTap: () => _showTransactionDetail(t),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  CategoryHelper.getIcon(t.category),
                  color: categoryColor,
                  size: 20,
                ),
              ),
              title: Text(
                t.category,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                "${t.title.isNotEmpty ? '${t.title} • ' : ''}${DateFormat('HH:mm dd/MM').format(t.date)}",
                style: const TextStyle(fontSize: 12),
              ),
              trailing: Text(
                !_hideAmounts
                    ? NumberFormat.currency(
                        locale: 'vi_VN',
                        symbol: 'đ',
                      ).format(t.amount)
                    : '******',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: t.type == 'income'
                      ? Colors.green
                      : Colors.red, // Keep amount color red/green
                ),
              ),
            );
          },
        ),
        if (transactions.length > 5)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: TextButton(
                onPressed: () => context.push('/transactions'),
                child: const Text("Xem thêm"),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMonthPicker() {
    String label;
    if (_tabController.index == 0) {
      // Week view
      label =
          "Tuần $_selectedWeek - Tháng ${_selectedDate.month}/${_selectedDate.year}";
    } else if (_tabController.index == 2) {
      // Year view
      label = "Năm ${_selectedDate.year}";
    } else {
      // Month view
      label = "Tháng ${_selectedDate.month}/${_selectedDate.year}";
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(LucideIcons.chevronLeft),
            onPressed: () => _changePeriod(-1),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.calendar,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.chevronRight),
            onPressed: () => _changePeriod(1),
          ),
        ],
      ),
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
}
