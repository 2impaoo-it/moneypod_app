import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../main.dart';
import '../repositories/group_repository.dart';
import 'add_expense_screen.dart';

/// Màn hình chi tiết nhóm - Sổ nợ
class GroupDetailScreen extends StatefulWidget {
  final String groupId;
  final String? groupName;

  const GroupDetailScreen({super.key, required this.groupId, this.groupName});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GroupRepository _groupRepo = GroupRepository();

  final currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  bool _isLoading = true;
  Map<String, dynamic> _groupData = {};
  List<Map<String, dynamic>> _myDebts = [];
  List<Map<String, dynamic>> _debtsToMe = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      // Load debt data
      final myDebts = await _groupRepo.getMyDebts(widget.groupId);
      final debtsToMe = await _groupRepo.getDebtsToMe(widget.groupId);

      // Mock basic group info since we don't have getGroupDetail API yet
      final mockInfo = {
        'id': widget.groupId,
        'name': 'Nhóm ${widget.groupId.substring(0, 4)}...',
        'memberCount': 0,
      };

      if (mounted) {
        setState(() {
          _myDebts = myDebts;
          _debtsToMe = debtsToMe;
          _groupData = mockInfo;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
        // );
      }
    }
  }

  Future<void> _markPaid(String debtId) async {
    try {
      await _groupRepo.markDebtPaid(debtId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã đánh dấu đã trả'),
            backgroundColor: Colors.green,
          ),
        );
        _loadAllData(); // Reload
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showAddMemberDialog() {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm thành viên'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Nhập email của thành viên mới:'),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty) return;

              Navigator.pop(context); // Close dialog first

              try {
                // Show loading
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đang thêm thành viên...')),
                );

                await _groupRepo.addMember(widget.groupId, email);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Đã thêm thành viên thành công!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '❌ Lỗi: ${e.toString().replaceAll("Exception: ", "")}',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverFillRemaining(
            child: Column(
              children: [
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildDebtDashboardTab(),
                      _buildMembersTab(), // Adding back a placeholder for members
                      _buildTransactionsTab(), // Placeholder for history
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      // bottomNavigationBar: _buildBottomActionBar(), // Removed per new requirements or kept minimal? Removed for now.
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  AddExpenseScreen(preSelectedGroupId: widget.groupId),
            ),
          );
          if (result == true) {
            _loadAllData();
          }
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Thêm chi tiêu",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    // Calculate totals for header summary
    double totalIOwe = _myDebts.fold(
      0.0,
      (sum, item) => sum + (double.tryParse(item['amount'].toString()) ?? 0.0),
    );
    double totalOwedToMe = _debtsToMe.fold(
      0.0,
      (sum, item) => sum + (double.tryParse(item['amount'].toString()) ?? 0.0),
    );

    // Handle initial loading case where _groupData['name'] might be null
    // Use passed group name if available, otherwise "Đang tải..." or truncated ID
    final groupName =
        widget.groupName ??
        _groupData['name'] ??
        'Nhóm ${widget.groupId.substring(0, 4)}...';

    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppColors.primary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.person_add, color: Colors.white),
          onPressed: _showAddMemberDialog,
          tooltip: 'Thêm thành viên',
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, Color(0xFF0F766E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    groupName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          "Tôi nợ",
                          totalIOwe,
                          Colors.redAccent.shade100,
                          Colors.red.shade900,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSummaryCard(
                          "Nợ tôi",
                          totalOwedToMe,
                          Colors.greenAccent.shade100,
                          Colors.green.shade900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, double amount, Color bg, Color textC) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            currencyFormat.format(amount),
            style: TextStyle(
              color: textC,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textMuted,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        tabs: const [
          Tab(text: 'Sổ nợ'),
          Tab(text: 'Thành viên'),
          Tab(text: 'Lịch sử'),
        ],
      ),
    );
  }

  Widget _buildDebtDashboardTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section 1: My Debts (Tôi nợ ai)
          _buildSectionHeader("Tôi nợ ai?", Colors.red),
          if (_myDebts.isEmpty)
            _buildEmptyState("Bạn không nợ ai cả! 🎉")
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _myDebts.length,
              itemBuilder: (context, index) =>
                  _buildDebtItem(_myDebts[index], isMyDebt: true),
            ),

          const SizedBox(height: 24),

          // Section 2: Debts to Me (Ai nợ tôi)
          _buildSectionHeader("Ai nợ tôi?", Colors.green),
          if (_debtsToMe.isEmpty)
            _buildEmptyState("Không có ai nợ bạn.")
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _debtsToMe.length,
              itemBuilder: (context, index) =>
                  _buildDebtItem(_debtsToMe[index], isMyDebt: false),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            color: color,
            margin: const EdgeInsets.only(right: 8),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Container(
      padding: const EdgeInsets.all(20),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(msg, style: const TextStyle(color: AppColors.textMuted)),
    );
  }

  Widget _buildDebtItem(Map<String, dynamic> debt, {required bool isMyDebt}) {
    final amount = double.tryParse(debt['amount'].toString()) ?? 0.0;
    final name = isMyDebt
        ? (debt['creditor_name'] ?? 'Người lạ')
        : (debt['debtor_name'] ?? 'Người lạ');
    final note = debt['note'] ?? 'Chi tiêu nhóm';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isMyDebt
                  ? Colors.red.withOpacity(0.1)
                  : Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isMyDebt ? LucideIcons.arrowUpRight : LucideIcons.arrowDownLeft,
              color: isMyDebt ? Colors.red : Colors.green,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  note,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currencyFormat.format(amount),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isMyDebt ? Colors.red : Colors.green,
                ),
              ),
              if (isMyDebt)
                TextButton(
                  onPressed: () => _markPaid(debt['id'].toString()),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 24),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: AppColors.primary,
                  ),
                  child: const Text('Đã trả?', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // Placeholder for Members Tab
  Widget _buildMembersTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.users, size: 48, color: Colors.grey),
          SizedBox(height: 12),
          Text("Danh sách thành viên"),
        ],
      ),
    );
  }

  // Placeholder for Transactions Tab
  Widget _buildTransactionsTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.history, size: 48, color: Colors.grey),
          SizedBox(height: 12),
          Text("Lịch sử hoạt động"),
        ],
      ),
    );
  }
}
