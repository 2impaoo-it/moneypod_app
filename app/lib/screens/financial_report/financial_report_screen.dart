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
  final bool _areAmountsVisible = true;
  late TabController _tabController;
  int _selectedSubTab = 0; // 0: Income, 1: Expense, 2: Difference
  bool _compareWithSamePeriod = true;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: 1, // Default to 'Theo tháng'
    );
    _tabController.addListener(_onTabChanged);
    _loadReport(); // Load default (Month)
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
    if (_tabController.index == 0)
      type = ReportType.week;
    else if (_tabController.index == 2)
      type = ReportType.year;

    context.read<FinancialReportBloc>().add(
      LoadReport(
        month: _selectedDate.month,
        year: _selectedDate.year,
        reportType: type,
      ),
    );
  }

  void _changeMonth(int offset) {
    setState(() {
      _selectedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month + offset,
      );
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
                        ? AppColors.danger
                        : (_selectedSubTab == 0
                              ? Colors.pink
                              : AppColors.success))
                  : AppColors.textSecondary,
              // Note: Logic adjustment - Income usually Green/Pink, Expense Red/Blue depending on theme.
              // Based on image: Income = Pink/Redish tab text? Let's stick to Pink for Income, Red for Expense not ideal.
              // Image 0 (Thu nhap) has Pink text.
              // Image 1 (Chi tieu) has Pink text.
              // Let's use Pink (Color(0xFFE91E63)) for active tab text logic if that matches theme, or AppColors.primary
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

    // Data selection
    if (_selectedSubTab == 0) {
      // Salary / Income
      currentAmount = state.data.totalIncome;
      prevAmount = state.data.previousMonthIncome;
      title = "Tổng thu tháng này";
    } else if (_selectedSubTab == 1) {
      // Expense
      currentAmount = state.data.totalExpense;
      prevAmount = state.data.previousMonthExpense;
      title = "Tổng chi tháng này";
    } else {
      // Difference
      currentAmount = state.data.totalIncome - state.data.totalExpense;
      prevAmount =
          state.data.previousMonthIncome - state.data.previousMonthExpense;
      title = "Tổng chênh lệch tháng này";
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

    return Column(
      children: [
        // Total Amount
        Text(
          title,
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _areAmountsVisible ? currencyFormat.format(currentAmount) : '******',
          style: GoogleFonts.inter(
            fontSize: 32,
            fontWeight: FontWeight.normal,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),

        // Banner
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: isIncrease
                ? Colors.green.withOpacity(0.1)
                : Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isIncrease ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                size: 16,
                color: isIncrease ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 8),
              Text(
                "${isIncrease ? 'Tăng' : 'Giảm'} ${currencyFormat.format(diff.abs())} so với cùng kỳ tháng trước",
                style: GoogleFonts.inter(
                  color: isIncrease
                      ? Colors.green
                      : Colors.orange, // Text matches icon
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                LucideIcons.info,
                size: 14,
                color: isIncrease ? Colors.green : Colors.orange,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Biến động",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        "So với cùng kỳ",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Transform.scale(
                        scale: 0.8,
                        child: Switch(
                          value: _compareWithSamePeriod,
                          activeThumbColor: Colors.white,
                          activeTrackColor: Colors.green,
                          onChanged: (val) {
                            setState(() {
                              _compareWithSamePeriod = val;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
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
                      if (state.data.trends.length < 7) return 1000000.0;
                      double m = 0;
                      for (int i = 1; i < state.data.trends.length; i++) {
                        double val = _selectedSubTab == 0
                            ? state.data.trends[i].income
                            : state.data.trends[i].expense;
                        if (val > m) m = val;
                        if (_compareWithSamePeriod) {
                          double prev = _selectedSubTab == 0
                              ? state.data.trends[i - 1].income
                              : state.data.trends[i - 1].expense;
                          if (prev > m) m = prev;
                        }
                      }
                      return m == 0 ? 10.0 : m * 1.2;
                    })(),
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        tooltipBgColor: Colors.blueGrey,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            NumberFormat.currency(
                              locale: 'vi_VN',
                              symbol: 'đ',
                            ).format(rod.toY),
                            const TextStyle(color: Colors.white),
                          );
                        },
                      ),
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
                            if (index < 1 ||
                                index >= state.data.trends.length) {
                              return const SizedBox.shrink();
                            }
                            final item = state.data.trends[index];
                            final isCurrent =
                                index == state.data.trends.length - 1;

                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                isCurrent ? "Tháng này" : "T${item.month}",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: isCurrent
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isCurrent ? Colors.blue : Colors.grey,
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
                      if (state.data.trends.length >= 7)
                        for (int i = 1; i < state.data.trends.length; i++)
                          BarChartGroupData(
                            x: i,
                            barRods: [
                              if (_compareWithSamePeriod)
                                BarChartRodData(
                                  toY: _selectedSubTab == 0
                                      ? state.data.trends[i - 1].income
                                      : state.data.trends[i - 1].expense,
                                  color: Colors.blue.withOpacity(0.4),
                                  width: 12,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              BarChartRodData(
                                toY: _selectedSubTab == 0
                                    ? state.data.trends[i].income
                                    : state.data.trends[i].expense,
                                color: i == state.data.trends.length - 1
                                    ? Colors.blue
                                    : Colors.blue.shade200,
                                width: 12,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ],
                            barsSpace: 4,
                          ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Recent Transactions List
              _buildTransactionList(state.data.transactions),

              const SizedBox(height: 24),

              // Breakdown List - Removed as per user request (duplicate info)
              // _buildBreakdownSection(state),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBreakdownSection(ReportLoaded state) {
    if (_selectedSubTab == 2) return const SizedBox.shrink();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: _buildCategoryListBreakdown(
          state,
          NumberFormat.currency(locale: 'vi_VN', symbol: 'đ'),
        ),
      ),
    );
  }

  Widget _buildTransactionList(List<Transaction> transactions) {
    if (transactions.isEmpty) return const SizedBox.shrink();

    // Limit to 5 items to show "Recent"
    final displayList = transactions.take(5).toList();

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
                NumberFormat.currency(
                  locale: 'vi_VN',
                  symbol: 'đ',
                ).format(t.amount),
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
                onPressed: () {},
                child: const Text("Xem thêm"),
              ),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildCategoryListBreakdown(
    ReportLoaded state,
    NumberFormat fmt,
  ) {
    if (_selectedSubTab == 2) return [];

    // We need to filter by Income vs Expense based on selectedSubTab
    // But data.categoryAllocation includes BOTH mixed.
    // We need to filter categories by type.

    final Map<String, double> relevantCurrent = {};

    // Scan transactions for correct type
    final typeToCheck = _selectedSubTab == 0 ? 'income' : 'expense';

    // Current
    for (var t in state.data.transactions) {
      if (t.type == typeToCheck) {
        relevantCurrent[t.category] =
            (relevantCurrent[t.category] ?? 0) + t.amount;
      }
    }

    // So, iterate relevantCurrent keys.
    final List<MapEntry<String, double>> sortedEntries =
        relevantCurrent.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    return sortedEntries.map((entry) {
      final catName = entry.key;
      final currentVal = entry.value;

      final categoryColor = CategoryHelper.getColor(catName);
      final backgroundColor = CategoryHelper.getBackgroundColor(catName);

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: backgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                CategoryHelper.getIcon(catName),
                color: categoryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                catName,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              _areAmountsVisible ? fmt.format(currentVal) : '******',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildMonthPicker() {
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
            onPressed: () => _changeMonth(-1),
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
                  "Tháng ${_selectedDate.month}/${_selectedDate.year}",
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
            onPressed: () => _changeMonth(1),
          ),
        ],
      ),
    );
  }
}
