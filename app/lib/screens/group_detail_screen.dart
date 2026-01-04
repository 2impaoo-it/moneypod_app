import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../utils/popup_notification.dart';
import '../repositories/group_repository.dart';
import '../repositories/profile_repository.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import 'package:go_router/go_router.dart';

/// Màn hình chi tiết nhóm - Sổ nợ
class GroupDetailScreen extends StatefulWidget {
  final String groupId;
  final String? groupName;
  final String? inviteCode;

  const GroupDetailScreen({
    super.key,
    required this.groupId,
    this.groupName,
    this.inviteCode,
  });

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GroupRepository _groupRepo = GroupRepository();
  final ProfileRepository _profileRepo = ProfileRepository();
  final AuthService _authService = AuthService(); // Add service

  final currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  bool _isLoading = true;
  Map<String, dynamic> _groupData = {};
  List<Map<String, dynamic>> _myDebts = [];
  List<Map<String, dynamic>> _debtsToMe = [];
  String? _currentUserId;
  bool _isLeader = false;
  List<Map<String, dynamic>> _transactions = []; // List transaction history

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      // Get User ID
      final token = await _authService.getToken();
      if (token == null) {
        setState(() => _isLoading = false);
        return;
      }
      final profile = await _profileRepo.fetchUserProfile(token);
      if (profile != null) {
        _currentUserId = profile.id;
      }

      // Load group details
      final groupDetails = await _groupRepo.getGroupDetails(widget.groupId);

      // Load debt data
      final myDebts = await _groupRepo.getMyDebts(widget.groupId);
      final debtsToMe = await _groupRepo.getDebtsToMe(widget.groupId);

      // Load history
      final history = await _groupRepo.getGroupExpenses(widget.groupId);

      if (mounted) {
        setState(() {
          _groupData = groupDetails;
          _myDebts = myDebts;
          _debtsToMe = debtsToMe;
          _transactions = history;

          // Check leader
          final members = _groupData['members'] as List<dynamic>? ?? [];
          final me = members.firstWhere(
            (m) => m['user_id'] == _currentUserId,
            orElse: () => null,
          );
          if (me != null && me['role'] == 'leader') {
            _isLeader = true;
          } else if (_groupData['creator_id'] == _currentUserId) {
            _isLeader = true;
          } else {
            _isLeader = false;
          }

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

  Future<void> _deleteGroup() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xóa nhóm?"),
        content: const Text(
          "Hành động này không thể hoàn tác. Bạn có chắc chắn muốn xóa nhóm này không?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Xóa"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _groupRepo.deleteGroup(widget.groupId);
        if (mounted) {
          context.pop(); // Close detail screen
          PopupNotification.showSuccess(context, 'Đã xóa nhóm thành công');
        }
      } catch (e) {
        if (mounted) {
          PopupNotification.showError(context, 'Lỗi: $e');
        }
      }
    }
  }

  void _showAddMemberOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Thêm thành viên',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.copy, color: AppColors.primary),
                ),
                title: const Text('Sao chép mã mời'),
                subtitle: Text(widget.inviteCode ?? 'Không có mã'),
                onTap: () {
                  Navigator.pop(context);
                  if (widget.inviteCode != null) {
                    Clipboard.setData(ClipboardData(text: widget.inviteCode!));
                    PopupNotification.showSuccess(
                      context,
                      'Đã sao chép mã mời!',
                    );
                  }
                },
              ),
              const Divider(),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.purple600.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.phone,
                    color: AppColors.purple600,
                  ),
                ),
                title: const Text('Thêm bằng số điện thoại'),
                subtitle: const Text('Nhập SĐT người muốn mời'),
                onTap: () {
                  Navigator.pop(context);
                  _showPhoneInputDialog();
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _showPhoneInputDialog() {
    final phoneController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nhập số điện thoại'),
        content: TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            hintText: 'Ví dụ: 0912345678',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              final phone = phoneController.text.trim();
              if (phone.isNotEmpty) {
                Navigator.pop(context);
                _addMemberByPhone(phone);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  Future<void> _addMemberByPhone(String phone) async {
    // Format phone logic similar to ProfileScreen
    String formattedPhone = phone;
    if (formattedPhone.startsWith('0')) {
      formattedPhone = '+84${formattedPhone.substring(1)}';
    } else if (!formattedPhone.startsWith('+')) {
      formattedPhone = '+84$formattedPhone';
    }

    setState(() => _isLoading = true);
    try {
      await _groupRepo.addMemberByPhone(widget.groupId, formattedPhone);
      if (mounted) {
        PopupNotification.showSuccess(
          context,
          'Đã thêm thành viên $formattedPhone thành công!',
        );
        _loadAllData(); // Reload member list
      }
    } catch (e) {
      if (mounted) {
        PopupNotification.showError(context, 'Lỗi: $e');
        setState(() => _isLoading = false);
      }
    }
  }

  /// Hiển thị dialog xác nhận xóa thành viên
  Future<void> _showRemoveMemberDialog(
    String memberId,
    String memberName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xóa thành viên'),
        content: Text('Bạn có chắc muốn xóa "$memberName" khỏi nhóm?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _removeMember(memberId);
    }
  }

  /// Xóa thành viên khỏi nhóm
  Future<void> _removeMember(String memberId) async {
    setState(() => _isLoading = true);
    try {
      await _groupRepo.removeMember(widget.groupId, memberId);
      await _loadAllData(); // Reload to update member list
      if (mounted) {
        PopupNotification.showSuccess(context, 'Đã xóa thành viên');
      }
    } catch (e) {
      if (mounted) {
        PopupNotification.showError(context, 'Lỗi: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
      expandedHeight: 250,
      pinned: true,
      backgroundColor: AppColors.primary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        if (_isLeader)
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            onPressed: () => _deleteGroup(),
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
                  if (widget.inviteCode != null &&
                      widget.inviteCode!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () {
                        Clipboard.setData(
                          ClipboardData(text: widget.inviteCode!),
                        );
                        PopupNotification.showSuccess(
                          context,
                          'Đã sao chép mã mời!',
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Mã mời: ${widget.inviteCode}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.copy,
                              color: Colors.white,
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
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
    // Logic lookup name and avatar
    String name = 'Người lạ';
    String avatarUrl = '';

    // Determine the ID of the person we are displaying
    dynamic targetId;
    if (isMyDebt) {
      // I owe someone -> Show Creditor
      targetId = debt['creditor_id'] ?? debt['to_user_id'];
    } else {
      // Someone owes me -> Show Debtor
      targetId = debt['debtor_id'] ?? debt['from_user_id'];
    }

    // Try finding in group members
    if (targetId != null) {
      final members = _groupData['members'] as List<dynamic>? ?? [];
      final found = members.firstWhere((m) {
        final u = m['user'] ?? {};
        final uid = u['id'] ?? m['user_id'] ?? m['id'];
        return uid.toString() == targetId.toString();
      }, orElse: () => null);

      if (found != null) {
        final u = found['user'] ?? found;
        name = u['full_name'] ?? u['name'] ?? u['email'] ?? 'Thành viên';
        avatarUrl = u['avatar_url'] ?? '';
      }
    }

    // Fallback if lookup failed but name is in debt object
    if (name == 'Người lạ') {
      name = isMyDebt
          ? (debt['creditor_name'] ?? 'Người lạ')
          : (debt['debtor_name'] ?? 'Người lạ');
    }

    final note = debt['note'] ?? 'Chi tiêu nhóm';
    final groupName = _groupData['name'] ?? 'Nhóm';
    final debtId = debt['id']?.toString() ?? '';

    // Check payment status
    // Assuming backend returns 'payment_wallet_id' when payment is made but not confirmed
    final paymentWalletId = debt['payment_wallet_id'];
    final isPending = paymentWalletId != null;

    // Lấy hình ảnh minh chứng từ expense
    final expenseImageUrl = (debt['expense'] is Map)
        ? (debt['expense']['image_url'] as String?)
        : null;

    return GestureDetector(
      onTap: () async {
        if (isMyDebt) {
          if (isPending) {
            // Pending confirmation - Do nothing or show toast
            PopupNotification.showInfo(
              context,
              'Bạn đã xác nhận trả khoản này rồi. Vui lòng chờ xác nhận!',
            );
            return;
          }
          // Tôi nợ người khác - Navigate to debt payment screen
          print("🚀 Navigating to /full-screen/debt/pay");
          final result = await context.push(
            '/full-screen/debt/pay',
            extra: {
              'debtId': debtId,
              'creditorName': name,
              'creditorAvatar': avatarUrl,
              'amount': amount.round(),
              'description': note,
              'groupName': groupName,
              'existingProofImageUrl': expenseImageUrl,
            },
          );

          // Refresh if payment was made
          if (result == true) {
            _loadAllData();
          }
        } else {
          // Người khác nợ tôi - Navigate to confirm receive payment screen
          final paymentDate = debt['payment_confirmed_at'] as String?;
          final paymentNote = debt['payment_note'] as String?;

          final result = await context.push(
            '/full-screen/debt/confirm',
            extra: {
              'debtId': debtId,
              'debtorName': name,
              'debtorAvatar': avatarUrl,
              'amount': amount.round(),
              'description': note,
              'groupName': groupName,
              'paymentDate': paymentDate,
              'paymentNote': paymentNote,
              'proofImageUrl': expenseImageUrl,
              'hasPaymentRequest': isPending, // Pass pending status
            },
          );

          // Refresh if confirmed
          if (result == true) {
            _loadAllData();
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.slate100),
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.slate200,
              backgroundImage:
                  (avatarUrl.isNotEmpty && avatarUrl.startsWith('http'))
                  ? NetworkImage(avatarUrl)
                  : null,
              child: (avatarUrl.isEmpty || !avatarUrl.startsWith('http'))
                  ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.slate700,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            // Name and Description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    note,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.slate600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.group,
                        size: 12,
                        color: AppColors.slate400,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        groupName,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.slate500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currencyFormat.format(amount),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isMyDebt ? AppColors.red500 : AppColors.teal500,
                  ),
                ),
                if (isPending)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      isMyDebt ? "Chờ xác nhận" : "Yêu cầu xác nhận",
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Members Tab
  Widget _buildMembersTab() {
    final members = _groupData['members'] as List<dynamic>? ?? [];

    return Column(
      children: [
        // Add Member Button
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showAddMemberOptions,
              icon: const Icon(LucideIcons.userPlus),
              label: const Text('Thêm thành viên'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),

        // Members List
        Expanded(
          child: members.isEmpty
              ? _buildEmptyState("Chưa có thành viên nào")
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final member = members[index];
                    final role = member['role'] == 'leader'
                        ? 'Trưởng nhóm'
                        : 'Thành viên';

                    final userObj = member['user'];
                    final name =
                        userObj?['full_name'] ??
                        userObj?['name'] ??
                        member['email'] ??
                        'Thành viên #${index + 1}';
                    final email = userObj?['email'] ?? member['email'] ?? '';
                    final avatarUrl = userObj?['avatar_url'] as String?;
                    final avatarChar = name.isNotEmpty
                        ? name.substring(0, 1).toUpperCase()
                        : '?';

                    final memberId =
                        member['user_id']?.toString() ??
                        userObj?['id']?.toString() ??
                        '';
                    final isCurrentUser = memberId == _currentUserId;
                    final isMemberLeader = member['role'] == 'leader';

                    return GestureDetector(
                      onLongPress:
                          (_isLeader && !isMemberLeader && !isCurrentUser)
                          ? () => _showRemoveMemberDialog(memberId, name)
                          : null,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: AppColors.primary.withOpacity(
                                0.1,
                              ),
                              backgroundImage:
                                  (avatarUrl != null && avatarUrl.isNotEmpty)
                                  ? NetworkImage(avatarUrl)
                                  : null,
                              child: (avatarUrl != null && avatarUrl.isNotEmpty)
                                  ? null
                                  : Text(
                                      avatarChar,
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  if (email.toString().isNotEmpty)
                                    Text(
                                      email,
                                      style: const TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: member['role'] == 'leader'
                                    ? Colors.orange.withOpacity(0.1)
                                    : Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                role,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: member['role'] == 'leader'
                                      ? Colors.orange
                                      : Colors.blue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // Transactions Tab - Lịch sử hoạt động
  Widget _buildTransactionsTab() {
    if (_transactions.isEmpty) {
      return _buildEmptyState("Chưa có lịch sử hoạt động nào");
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        final tx = _transactions[index];
        return _buildTransactionItem(tx);
      },
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> tx) {
    // Basic Info
    final payer = tx['payer'] ?? tx['user'] ?? tx['created_by'];
    final payerId = payer?['id']?.toString() ?? tx['payer_id']?.toString();
    final payerName =
        payer?['full_name'] ??
        payer?['name'] ??
        payer?['username'] ??
        'Unknown';
    final payerAvatar = payer?['avatar_url'];
    final totalAmount = (tx['amount'] as num).toDouble();
    final description = tx['description'] ?? 'Chi tiêu nhóm';
    final createdAtStr = tx['created_at'];

    // Time
    DateTime? createdAt;
    if (createdAtStr != null) {
      try {
        createdAt = DateTime.parse(createdAtStr).toLocal();
      } catch (e) {
        // ignore
      }
    }

    // Role Logic
    final isPayer = payerId == _currentUserId;
    double myShare = 0.0;
    bool isInvolved = false;

    if (!isPayer) {
      // Check if I am in the debts list
      final debts = tx['debts'] as List<dynamic>? ?? [];
      final myDebt = debts.firstWhere(
        (d) => d['from_user_id'] == _currentUserId,
        orElse: () => null,
      );
      if (myDebt != null) {
        myShare = (myDebt['amount'] as num).toDouble();
        isInvolved = true;
      }
    }

    // Display Logic
    String amountText;
    Color amountColor;
    String statusText;

    if (isPayer) {
      // I paid the total
      amountText = '+${currencyFormat.format(totalAmount)}';
      amountColor = AppColors.teal500;
      statusText = 'Bạn đã trả';
    } else if (isInvolved) {
      // I owe my share
      amountText = '-${currencyFormat.format(myShare)}';
      amountColor = AppColors.danger;
      statusText = 'Bạn nợ';
    } else {
      // Not involved
      amountText = currencyFormat.format(totalAmount);
      amountColor = AppColors.textSecondary;
      statusText = '$payerName đã trả';
    }

    return InkWell(
      onTap: () => _showTransactionDetail(tx),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.slate100),
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.slate200,
              backgroundImage:
                  (payerAvatar != null && payerAvatar.toString().isNotEmpty)
                  ? NetworkImage(payerAvatar)
                  : null,
              child: (payerAvatar == null || payerAvatar.toString().isEmpty)
                  ? Text(
                      payerName.isNotEmpty ? payerName[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.slate700,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 11,
                          color: isPayer || statusText.contains('đã trả')
                              ? AppColors.teal500
                              : AppColors.danger,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (createdAt != null) ...[
                        const SizedBox(width: 4),
                        const Text(
                          '•',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.slate400,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('dd/MM HH:mm').format(createdAt),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.slate500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Amount
            Text(
              amountText,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: amountColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
  /*
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 12,
                          color: amountColor.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (createdAt != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.slate300,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat('dd/MM HH:mm').format(createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Right: Amount
            Text(
              amountText,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: amountColor,
              ),
            ),
          ],
        ),
      ),
    );
  } */

  void _showTransactionDetail(Map<String, dynamic> tx) {
    // final payer = tx['payer'] ?? tx['user'] ?? tx['created_by'];
    // final payerName =
    //     payer?['full_name'] ??
    //     payer?['name'] ??
    //     payer?['username'] ??
    //     'Unknown';
    // final payerAvatar = payer?['avatar_url'];
    final amount = (tx['amount'] as num).toDouble();
    final description = tx['description'] ?? 'Chi tiêu nhóm';
    final imageUrl = tx['image_url'];
    final createdAtStr = tx['created_at'];

    DateTime? createdAt;
    if (createdAtStr != null) {
      try {
        createdAt = DateTime.parse(createdAtStr).toLocal();
      } catch (e) {
        // ignore
      }
    }

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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Chi tiết giao dịch',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(LucideIcons.x),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const Divider(height: 32),
            // Details
            if (createdAt != null)
              _buildDetailRow(
                'Thời gian',
                DateFormat('dd/MM/yyyy HH:mm').format(createdAt),
              ),
            _buildDetailRow(
              'Số tiền',
              '-${currencyFormat.format(amount)}',
              valueColor: AppColors.danger,
            ),
            _buildDetailRow('Mô tả', description),
            // Proof Image Section
            const SizedBox(height: 16),
            const Text(
              'Hình ảnh minh chứng',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            if (imageUrl != null && imageUrl.toString().isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: Image.network(
                    imageUrl,
                    width: double.infinity,
                    fit: BoxFit
                        .contain, // Changed to contain to show full image, or cover with limit
                    errorBuilder: (_, __, ___) => Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'Không thể tải hình ảnh',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'Không có minh chứng',
                    style: TextStyle(fontSize: 14, color: AppColors.textMuted),
                  ),
                ),
              ),
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
