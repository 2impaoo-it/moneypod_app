import 'package:flutter/material.dart';
import '../models/group.dart';
import '../services/group_service.dart';

class AppColors {
  static const Color slate50  = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate900 = Color(0xFF0F172A);

  static const Color teal50  = Color(0xFFF0FDFA);
  static const Color teal400 = Color(0xFF2DD4BF);
  static const Color teal500 = Color(0xFF14B8A6);
  static const Color teal700 = Color(0xFF0F766E);

  static const Color green50  = Color(0xFFF0FDF4);
  static const Color green500 = Color(0xFF22C55E);

  static const Color red50 = Color(0xFFFEF2F2);
  static const Color red500   = Color(0xFFEF4444);
}

String formatCurrency(double amount) {
  final str = amount.toInt().toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (Match m) => '${m[1]}.',
  );
  return '$str ₫';
}

class GroupDetailScreen extends StatefulWidget {
  final Group group;

  const GroupDetailScreen({super.key, required this.group});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  final GroupService _groupService = GroupService();
  bool _isLoading = true;
  List<GroupExpense> _expenses = [];
  List<GroupMember> _members = [];
  Group? _groupDetails;

  @override
  void initState() {
    super.initState();
    _loadGroupData();
  }

  Future<void> _loadGroupData() async {
    setState(() => _isLoading = true);

    try {
      // TODO: Backend chưa có API này - tạm dùng dữ liệu từ widget.group
      _groupDetails = widget.group;
      
      // Lấy members từ group hiện tại
      if (widget.group.members != null) {
        _members = widget.group.members!;
      }

      // TODO: Backend chưa có GET /groups/:id/expenses
      // Tạm thời để trống, sau sẽ cập nhật khi backend có API
      _expenses = [];
      
      // Note: Các API cần backend implement:
      // - GET /groups/:id - Chi tiết nhóm
      // - GET /groups/:id/members - Danh sách thành viên
      // - GET /groups/:id/expenses - Danh sách expenses
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải dữ liệu: ${e.toString()}'),
            backgroundColor: AppColors.red500,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleAddExpense() async {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Góp quỹ',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.slate900,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Số tiền',
                  hintText: 'VD: 100000',
                  border: OutlineInputBorder(),
                  prefixText: '₫ ',
                ),
                keyboardType: TextInputType.number,
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú (tùy chọn)',
                  hintText: 'VD: Góp quỹ tháng 12',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                final amountText = amountController.text.trim();
                if (amountText.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vui lòng nhập số tiền'),
                      backgroundColor: AppColors.red500,
                    ),
                  );
                  return;
                }
                final amount = double.tryParse(amountText);
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Số tiền không hợp lệ'),
                      backgroundColor: AppColors.red500,
                    ),
                  );
                  return;
                }
                Navigator.of(context).pop({
                  'amount': amount,
                  'description': descriptionController.text.trim(),
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.teal500,
                foregroundColor: Colors.white,
              ),
              child: const Text('Xác nhận'),
            ),
          ],
        );
      },
    );

    if (result == null) return;

    try {
      final response = await _groupService.addExpense(
        groupId: widget.group.id,
        amount: result['amount'],
        note: result['description'].isEmpty ? 'Góp quỹ' : result['description'],
        memberIds: [widget.group.creatorId], // Tạm thời dùng creator, sau này có thể chọn members
      );

      if (!mounted) return;

      if (response['success'] == true) {
        await _loadGroupData();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Góp quỹ thành công!'),
            backgroundColor: AppColors.green500,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Góp quỹ thất bại'),
            backgroundColor: AppColors.red500,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: AppColors.red500,
          ),
        );
      }
    }
  }

  Future<void> _handleLeaveGroup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Rời nhóm',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.slate900,
            ),
          ),
          content: const Text(
            'Bạn có chắc chắn muốn rời khỏi nhóm này không?',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.red500,
                foregroundColor: Colors.white,
              ),
              child: const Text('Rời nhóm'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final response = await _groupService.leaveGroup(groupId: widget.group.id);

      if (!mounted) return;

      if (response['success'] == true) {
        Navigator.of(context).pop(true); // Quay lại và refresh
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã rời khỏi nhóm'),
            backgroundColor: AppColors.green500,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Rời nhóm thất bại'),
            backgroundColor: AppColors.red500,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: AppColors.red500,
          ),
        );
      }
    }
  }

  Future<void> _handleAddMember() async {
    await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Thêm thành viên',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.slate900,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chia sẻ mã nhóm này với bạn bè:',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.slate700,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.teal50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.teal500, width: 2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.group.code,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.teal700,
                        letterSpacing: 3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Họ có thể tham gia bằng cách vào màn hình Quỹ nhóm và nhập mã này.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.slate500,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleWithdraw() async {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Rút quỹ',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.slate900,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Số tiền',
                  hintText: 'VD: 50000',
                  border: OutlineInputBorder(),
                  prefixText: '₫ ',
                ),
                keyboardType: TextInputType.number,
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Lý do rút (tùy chọn)',
                  hintText: 'VD: Chi phí ăn uống',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                final amountText = amountController.text.trim();
                if (amountText.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vui lòng nhập số tiền'),
                      backgroundColor: AppColors.red500,
                    ),
                  );
                  return;
                }
                final amount = double.tryParse(amountText);
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Số tiền không hợp lệ'),
                      backgroundColor: AppColors.red500,
                    ),
                  );
                  return;
                }
                Navigator.of(context).pop({
                  'amount': amount,
                  'description': descriptionController.text.trim(),
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.red500,
                foregroundColor: Colors.white,
              ),
              child: const Text('Xác nhận'),
            ),
          ],
        );
      },
    );

    if (result == null) return;

    try {
      // Sử dụng số âm để biểu thị rút tiền
      final response = await _groupService.addExpense(
        groupId: widget.group.id,
        amount: -result['amount'], // Số âm = rút
        note: result['description'].isEmpty ? 'Rút quỹ' : result['description'],
        memberIds: [widget.group.creatorId], // Tạm thời dùng creator, sau này có thể chọn members
      );

      if (!mounted) return;

      if (response['success'] == true) {
        await _loadGroupData();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rút quỹ thành công!'),
            backgroundColor: AppColors.green500,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Rút quỹ thất bại'),
            backgroundColor: AppColors.red500,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: AppColors.red500,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayGroup = _groupDetails ?? widget.group;
    final totalBalance = _members.fold<double>(0, (sum, member) => sum + member.balance);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.slate900),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          displayGroup.name,
          style: const TextStyle(
            color: AppColors.slate900,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.slate900),
            onSelected: (value) {
              if (value == 'add_member') {
                _handleAddMember();
              } else if (value == 'leave') {
                _handleLeaveGroup();
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'add_member',
                child: Row(
                  children: [
                    Icon(Icons.person_add, size: 20, color: AppColors.teal500),
                    SizedBox(width: 12),
                    Text('Thêm thành viên'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'leave',
                child: Row(
                  children: [
                    Icon(Icons.exit_to_app, size: 20, color: AppColors.red500),
                    SizedBox(width: 12),
                    Text('Rời nhóm'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.teal500),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadGroupData,
              color: AppColors.teal500,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Group Info Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.teal400, AppColors.teal500],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  displayGroup.code,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              const Icon(
                                Icons.groups,
                                color: Colors.white,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${_members.length} thành viên',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Tổng quỹ',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            formatCurrency(totalBalance),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _handleAddExpense,
                            icon: const Icon(Icons.add_circle_outline, size: 20),
                            label: const Text('Góp quỹ'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.teal500,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _handleWithdraw,
                            icon: const Icon(Icons.remove_circle_outline, size: 20),
                            label: const Text('Rút quỹ'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.red500,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(color: AppColors.red500),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Members Section
                    Row(
                      children: const [
                        Text(
                          'Thành viên',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.slate900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (_members.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            'Chưa có thành viên nào',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.slate500,
                            ),
                          ),
                        ),
                      )
                    else
                      ..._members.map((member) => _buildMemberItem(member)),

                    const SizedBox(height: 32),

                    // Recent Activities
                    Row(
                      children: const [
                        Text(
                          'Hoạt động gần đây',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.slate900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (_expenses.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Column(
                            children: const [
                              Icon(
                                Icons.history,
                                size: 60,
                                color: AppColors.slate300,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Chưa có hoạt động nào',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.slate500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ..._expenses.map((expense) => _buildActivityItem(expense)),
                  ],
                ),
              ),
            ),
    );
  }
  Widget _buildMemberItem(GroupMember member) {
    final isAdmin = member.role == 'admin';
    final userName = member.user?.fullName ?? 'Người dùng';
    final balance = member.balance;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.teal50,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.teal700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.slate900,
                      ),
                    ),
                    if (isAdmin) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.teal500,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Admin',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Số dư: ${formatCurrency(balance)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: balance >= 0 ? AppColors.green500 : AppColors.red500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildActivityItem(GroupExpense expense) {
    final isDeposit = expense.amount >= 0;
    final userName = expense.paidBy?.fullName ?? 'Người dùng';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDeposit ? AppColors.green50 : AppColors.red50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDeposit ? Icons.arrow_downward : Icons.arrow_upward,
              color: isDeposit ? AppColors.green500 : AppColors.red500,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.note.isEmpty 
                      ? (isDeposit ? 'Góp quỹ' : 'Rút quỹ')
                      : expense.note,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.slate500,
                  ),
                ),
              ],
            ),
          ),
          // Amount
          Text(
            '${isDeposit ? '+' : '-'}${formatCurrency(expense.amount.abs())}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isDeposit ? AppColors.green500 : AppColors.red500,
            ),
          ),
        ],
      ),
    );
  }
}
