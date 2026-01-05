import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/auth_service.dart';
import '../repositories/group_repository.dart';

// --- UTILS: Colors & Helpers (Copy-paste friendly) ---
import '../theme/app_colors.dart';
import '../utils/popup_notification.dart';

// Helper format tiền tệ đơn giản (VD: 2500000 -> 2.500.000 ₫)
String formatCurrency(int amount) {
  final str = amount.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (Match m) => '${m[1]}.',
  );
  return '$str ₫';
}

// --- MAIN SCREEN ---
class GroupsScreen extends StatefulWidget {
  final GroupRepository? groupRepository;
  final AuthService? authService;

  const GroupsScreen({super.key, this.groupRepository, this.authService});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen>
    with WidgetsBindingObserver {
  // Data list
  List<Map<String, dynamic>> _groupsList = [];
  bool _isLoading = true;
  late final GroupRepository _groupRepository;

  // Debt optimization and pending settlements
  List<Map<String, dynamic>> _pendingSettlements = []; // Tôi nợ người khác
  List<Map<String, dynamic>> _peopleOweMe = []; // Người nợ tôi
  bool _isLoadingDebts = true;
  String _sortBy = 'default'; // default, group

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _groupRepository = widget.groupRepository ?? GroupRepository();
    _fetchGroups();
    _fetchDebtData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Auto-refresh khi app quay lại foreground
    // Chỉ refresh nếu đã cache đủ lâu hoặc các màn hình khác pop về
    // Tuy nhiên ở đây chỉ đơn giản là check resumed.
    // Để fix bug "kéo notif xuống bị reload", ta có thể bỏ qua refresh ở đây
    // hoặc check thời gian pause. Nhưng đơn giản nhất là bỏ việc auto refresh quá aggressive.
    if (state == AppLifecycleState.resumed) {
      // _refreshData(); // Bỏ auto refresh khi resume để tránh reload khi kéo notification
    }
  }

  // Load user profile để hiển thị trong optimization

  // Fetch tất cả dữ liệu về nợ
  Future<void> _fetchDebtData() async {
    setState(() => _isLoadingDebts = true);

    try {
      // Lấy tất cả các nhóm để tính toán nợ tối ưu
      final groups = await _groupRepository.getGroups();

      // Fetch debts từ tất cả các nhóm
      List<Map<String, dynamic>> allMyDebts = [];
      List<Map<String, dynamic>> allDebtsToMe = [];

      for (var group in groups) {
        final groupId = group['id']?.toString();
        final groupName = group['name'] ?? 'Nhóm';
        if (groupId != null) {
          final myDebts = await _groupRepository.getMyDebts(groupId);
          final debtsToMe = await _groupRepository.getDebtsToMe(groupId);

          allMyDebts.addAll(
            myDebts.map(
              (d) => {...d, 'group_id': groupId, 'group_name': groupName},
            ),
          );
          allDebtsToMe.addAll(
            debtsToMe.map(
              (d) => {...d, 'group_id': groupId, 'group_name': groupName},
            ),
          );
        }
      }

      // Lấy danh sách chờ thanh toán (TÔI NỢ người khác - cần trả)
      _pendingSettlements = _mapPendingSettlements(allMyDebts);

      // Lấy danh sách người nợ tôi (người khác NỢ TÔI - chờ xác nhận)
      _peopleOweMe = _mapPeopleOweMe(allDebtsToMe);

      debugPrint('DEBUG: Total debts to me: ${allDebtsToMe.length}');
      debugPrint(
        'DEBUG: Pending settlements after filter: ${_pendingSettlements.length}',
      );
      debugPrint('DEBUG: People owe me after map: ${_peopleOweMe.length}');

      for (var debt in allDebtsToMe) {
        debugPrint(
          'DEBUG DEBT: ${debt['from_user']?['full_name']} - ${debt['amount']} - is_paid: ${debt['is_paid']}',
        );
      }

      setState(() => _isLoadingDebts = false);
    } catch (e) {
      debugPrint('Error fetching debt data: $e');
      setState(() => _isLoadingDebts = false);
    }
  }

  // Map pending settlements từ myDebts (TÔI NỢ người khác)
  List<Map<String, dynamic>> _mapPendingSettlements(
    List<Map<String, dynamic>> myDebts,
  ) {
    return myDebts.where((debt) => debt['is_paid'] != true).map((debt) {
      final amount = (debt['amount'] as num?)?.toDouble() ?? 0.0;

      // Lấy thông tin từ to_user object (người tôi nợ)
      final toUser = debt['to_user'] as Map<String, dynamic>?;
      final toUserName =
          toUser?['full_name'] ??
          toUser?['name'] ??
          toUser?['email'] ??
          'Unknown';
      final toUserAvatar = toUser?['avatar_url'] ?? '';

      final expenseData = debt['expense'] as Map<String, dynamic>?;
      final description = expenseData?['description'] ?? 'Chi phí nhóm';
      final expenseImageUrl =
          expenseData?['image_url'] ?? ''; // Hình ảnh bill từ expense
      final groupName = debt['group_name'] ?? 'Nhóm';

      // Payment confirmation info
      final paymentConfirmedAt = debt['payment_confirmed_at'];
      final paymentWalletId = debt['payment_wallet_id']?.toString();
      final paymentNote = debt['payment_note'] as String?;

      return {
        'name': toUserName,
        'avatar': toUserAvatar,
        'description': description,
        'group_name': groupName,
        'amount': amount.round(),
        'debt_id': debt['id']?.toString(),
        'expense_image_url': expenseImageUrl,
        'payment_confirmed_at': paymentConfirmedAt,
        'payment_wallet_id': paymentWalletId,
        'payment_note': paymentNote,
      };
    }).toList();
  }

  // Map danh sách người nợ tôi từ debtsToMe (người khác NỢ TÔI)
  List<Map<String, dynamic>> _mapPeopleOweMe(
    List<Map<String, dynamic>> debtsToMe,
  ) {
    return debtsToMe.where((debt) => debt['is_paid'] != true).map((debt) {
      final amount = (debt['amount'] as num?)?.toDouble() ?? 0.0;

      // Lấy thông tin từ from_user object (người nợ tôi)
      final fromUser = debt['from_user'] as Map<String, dynamic>?;
      final fromUserName =
          fromUser?['full_name'] ??
          fromUser?['name'] ??
          fromUser?['email'] ??
          'Unknown';
      final fromUserAvatar = fromUser?['avatar_url'] ?? '';

      final expenseData = debt['expense'] as Map<String, dynamic>?;
      final description = expenseData?['description'] ?? 'Chi phí nhóm';
      final expenseImageUrl = expenseData?['image_url'] ?? '';
      final groupName = debt['group_name'] ?? 'Nhóm';

      // Kiểm tra xem người nợ đã gửi yêu cầu thanh toán chưa
      final hasPaymentRequest = debt['payment_wallet_id'] != null;
      final paymentDate = debt['payment_confirmed_at'] as String?;
      final paymentNote = debt['payment_note'] as String?;
      final isPaid = debt['is_paid'] == true;
      final receivedWalletId = debt['received_wallet_id']?.toString();

      return {
        'name': fromUserName,
        'avatar': fromUserAvatar,
        'description': description,
        'group_name': groupName,
        'amount': amount.round(),
        'debt_id': debt['id']?.toString(),
        'expense_image_url': expenseImageUrl,
        'has_payment_request': hasPaymentRequest,
        'payment_date': paymentDate,
        'payment_note': paymentNote,
        'is_paid': isPaid,
        'received_wallet_id': receivedWalletId,
      };
    }).toList();
  }

  // Refresh toàn bộ data (groups + debts)
  Future<void> _refreshData() async {
    await Future.wait([_fetchGroups(), _fetchDebtData()]);
  }

  Future<void> _fetchGroups() async {
    try {
      final groups = await _groupRepository.getGroups();

      // Map API data to UI model
      final mappedGroups = groups.map((g) {
        debugPrint("DEBUG GROUP: ${g['name']} - Members: ${g['members']}");
        // Calculate days left
        int daysLeft = 0;
        String status = 'active';

        if (g['deadline'] != null && g['deadline'].toString().isNotEmpty) {
          try {
            final deadline = DateTime.parse(g['deadline']);
            final now = DateTime.now();
            final difference = deadline.difference(now).inDays;
            daysLeft = difference > 0 ? difference : 0;

            if (daysLeft == 0 && difference < 0) {
              status = 'completed';
            }
          } catch (e) {
            debugPrint('Error marking debt as paid: $e');
          }
        }

        // Parse members
        final membersList = g['members'] as List? ?? [];
        final int memberCount = membersList.length;
        debugPrint(
          "DEBUG: Group ${g['name']} has ${membersList.length} members",
        );

        // Parse avatars
        final avatars = membersList
            .map((m) {
              final user = m['user'];
              final avatarUrl = user?['avatar_url'] as String?;
              if (avatarUrl != null && avatarUrl.isNotEmpty) {
                return avatarUrl;
              }
              final name = user != null
                  ? (user['full_name'] ?? user['name'] ?? m['email'] ?? '?')
                  : (m['email'] ?? '?');
              return name.toString().isNotEmpty
                  ? name.toString().substring(0, 1).toUpperCase()
                  : '?';
            })
            .take(3)
            .toList();

        return {
          "id": g['id'],
          "name": g['name'] ?? 'Không tên',
          "members": memberCount,
          "avatars": avatars,
          "extraMembers": membersList.length > 3 ? membersList.length - 3 : 0,
          "status": status,
          "description": g['description'], // Optional
          "inviteCode": g['invite_code'],
        };
      }).toList();

      if (mounted) {
        setState(() {
          _groupsList = mappedGroups;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching groups: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        PopupNotification.showError(context, 'Lỗi tải danh sách nhóm: $e');
      }
    }
  }

  void _navigateToCreateGroup() async {
    await context.push('/groups/create');
    // Luôn refresh kể cả khi back về, để đảm bảo data mới nhất
    _fetchGroups();
  }

  void _navigateToGroupDetail(Map<String, dynamic> group) async {
    await context.push(
      '/groups/${group['id']}',
      extra: {'groupName': group['name'], 'inviteCode': group['inviteCode']},
    );
    // Auto-reload when returning from detail screen
    _fetchGroups();
  }

  void _showJoinGroupDialog() {
    final codeController = TextEditingController();
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true, // Elevate above FAB in shell
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.slate300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Title
                  const Text(
                    'Tham gia nhóm',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.slate900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Nhập mã mời để tham gia nhóm chi tiêu',
                    style: TextStyle(fontSize: 14, color: AppColors.slate500),
                  ),
                  const SizedBox(height: 20),
                  // Input field
                  TextField(
                    controller: codeController,
                    textCapitalization: TextCapitalization.characters,
                    autofocus: true,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Nhập mã mời',
                      hintStyle: const TextStyle(
                        fontWeight: FontWeight.normal,
                        letterSpacing: 0,
                      ),
                      prefixIcon: const Icon(
                        Icons.vpn_key_outlined,
                        color: AppColors.teal500,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.teal500,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: AppColors.slate50,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () async {
                              final code = codeController.text.trim();
                              if (code.isEmpty) {
                                PopupNotification.showError(
                                  context,
                                  'Vui lòng nhập mã mời',
                                );
                                return;
                              }

                              setModalState(() => isLoading = true);

                              try {
                                await _groupRepository.joinGroup(code: code);

                                if (!context.mounted) return;

                                Navigator.pop(ctx);
                                if (mounted) {
                                  await PopupNotification.showSuccess(
                                    context,
                                    'Tham gia nhóm thành công!',
                                  );
                                  _fetchGroups();
                                }
                              } catch (e) {
                                setModalState(() => isLoading = false);
                                if (context.mounted) {
                                  PopupNotification.showError(
                                    context,
                                    e.toString().replaceAll('Exception: ', ''),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.teal500,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Tham gia',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Phân loại groups
    final activeGroups = _groupsList
        .where((g) => g['status'] == 'active')
        .toList();
    final completedGroups = _groupsList
        .where((g) => g['status'] == 'completed')
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header Section
                _buildHeader(),

                // 2. Active Groups Section
                if (activeGroups.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text(
                    "Đang hoạt động",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...activeGroups.map((g) => _buildGroupCard(g)),
                ] else if (completedGroups.isEmpty) ...[
                  // Empty state nếu không có group nào
                  Container(
                    padding: const EdgeInsets.only(top: 40),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        const Icon(
                          Icons.group_off_outlined,
                          size: 48,
                          color: AppColors.slate300,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Chưa có nhóm nào",
                          style: TextStyle(color: AppColors.slate500),
                        ),
                        TextButton(
                          onPressed: _navigateToCreateGroup,
                          child: const Text("Tạo ngay"),
                        ),
                      ],
                    ),
                  ),
                ],

                // 3. Pending Settlements Section (Tôi nợ người khác)
                _buildPendingSettlementsSection(),

                // 5. People Owe Me Section (Người nợ tôi)
                _buildPeopleOweMeSection(),

                // 6. Completed Groups Section
                if (completedGroups.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Text(
                    "Đã hoàn thành",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...completedGroups.map((g) => _buildGroupCard(g)),
                ],

                const SizedBox(height: 40), // Bottom padding
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGET COMPONENTS ---

  // 1. Header
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Nhóm chi tiêu",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.slate900,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Nút Tham gia nhóm
            Expanded(
              child: InkWell(
                onTap: _showJoinGroupDialog,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.teal500),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.group_add, color: AppColors.teal500, size: 18),
                      SizedBox(width: 6),
                      Text(
                        "Tham gia",
                        style: TextStyle(
                          color: AppColors.teal500,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Nút Tạo nhóm mới
            Expanded(
              child: InkWell(
                onTap: _navigateToCreateGroup,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.teal500,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.add, color: Colors.white, size: 18),
                      SizedBox(width: 6),
                      Text(
                        "Tạo nhóm mới",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 2. Group Card (Dùng chung cho Active & Completed)
  Widget _buildGroupCard(Map<String, dynamic> group) {
    final bool isCompleted = group['status'] == 'completed';

    return InkWell(
      onTap: () => _navigateToGroupDetail(group),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: 0.1,
              ), // Giảm opacity cho nhẹ nhàng hơn
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          children: [
            // a) Header Row
            Row(
              children: [
                // Icon Circle
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: isCompleted
                          ? [AppColors.green500, AppColors.green700]
                          : [AppColors.teal400, AppColors.teal500],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(
                    Icons.groups,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                // Name & Count
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group['name'],
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.slate900,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "${group['members']} thành viên",
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.slate500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Avatar Stack
                SizedBox(
                  width: 60, // Đủ chỗ cho stack
                  height: 28,
                  child: Stack(
                    children: List.generate(3, (index) {
                      // Logic hiển thị avatar stack
                      final avatars = group['avatars'] as List;
                      // Nếu không có item ở index này, hide bằng SizedBox.shrink()
                      if (index >= avatars.length &&
                          !(index == 2 && group['extraMembers'] > 0)) {
                        return const SizedBox.shrink();
                      }

                      final isExtra = (index == 2 && group['extraMembers'] > 0);
                      final content = isExtra
                          ? "+${group['extraMembers']}"
                          : (index < avatars.length ? avatars[index] : "?");

                      // Check if it is URL
                      final isUrl = content.toString().startsWith("http");

                      return Positioned(
                        left: index * 16.0, // Overlap effect
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            color: isExtra
                                ? AppColors.slate200
                                : AppColors.slate300,
                            image: isUrl
                                ? DecorationImage(
                                    image: NetworkImage(content.toString()),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: isUrl
                              ? null
                              : Text(
                                  content.toString(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isExtra
                                        ? AppColors.slate500
                                        : Colors.white,
                                    fontWeight: isExtra
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),

            // b) Description (Optional)
            if (group['description'] != null &&
                group['description'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  group['description'],
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.slate500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 4. Pending Settlements Section
  Widget _buildPendingSettlementsSection() {
    // Nếu đang loading hoặc không có pending settlements, không hiển thị
    if (_isLoadingDebts || _pendingSettlements.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Chờ thanh toán",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.slate700,
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) => setState(() => _sortBy = value),
              itemBuilder: (context) {
                // Collect unique group names
                final groupNames = _pendingSettlements
                    .map((e) => e['group_name'] as String?)
                    .where((e) => e != null && e.isNotEmpty)
                    .toSet()
                    .toList();

                debugPrint('Group created successfully');
                return [
                  const PopupMenuItem(
                    value: 'default',
                    child: Text('Mặc định (Tất cả)'),
                  ),
                  if (groupNames.isNotEmpty) ...[
                    const PopupMenuDivider(),
                    ...groupNames.map(
                      (name) => PopupMenuItem(value: name, child: Text(name!)),
                    ),
                  ],
                ];
              },
              child: Row(
                children: [
                  Icon(
                    Icons.filter_list,
                    size: 16,
                    color: _sortBy == 'default'
                        ? AppColors.slate400
                        : AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 150),
                    child: Text(
                      _sortBy == 'default' ? 'Lọc theo nhóm' : _sortBy,
                      style: TextStyle(
                        fontSize: 12,
                        color: _sortBy == 'default'
                            ? AppColors.slate500
                            : AppColors.primary,
                        fontWeight: _sortBy == 'default'
                            ? FontWeight.normal
                            : FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Sorting/Filtering logic
        ...(() {
          var filteredList = List<Map<String, dynamic>>.from(
            _pendingSettlements,
          );

          // Filter by group if selected
          if (_sortBy != 'default') {
            filteredList = filteredList
                .where((item) => item['group_name'] == _sortBy)
                .toList();
          }

          return filteredList;
        })().map(
          (item) => GestureDetector(
            onTap: () async {
              // "Chờ thanh toán" là TÔI NỢ người khác -> Navigate đến màn hình trả nợ
              final result = await context.push(
                '/full-screen/debt/pay',
                extra: {
                  'debtId': item['debt_id'] ?? '',
                  'creditorName': item['name'] ?? 'Unknown',
                  'creditorAvatar': item['avatar'] ?? '',
                  'amount': item['amount'] ?? 0,
                  'description': item['description'] ?? '',
                  'groupName': item['group_name'] ?? 'Nhóm',
                  'existingProofImageUrl': item['expense_image_url'],
                  'isPaid': item['payment_wallet_id'] != null,
                  'paymentWalletId': item['payment_wallet_id'],
                  'paymentNote': item['payment_note'],
                },
              );

              // Refresh if payment was made
              if (result == true) {
                _fetchDebtData();
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
                        (item['avatar'] != null &&
                            item['avatar'].toString().isNotEmpty &&
                            item['avatar'].toString().startsWith('http'))
                        ? NetworkImage(item['avatar'])
                        : null,
                    child:
                        (item['avatar'] == null ||
                            item['avatar'].toString().isEmpty ||
                            !item['avatar'].toString().startsWith('http'))
                        ? Text(
                            item['name']
                                    ?.toString()
                                    .substring(0, 1)
                                    .toUpperCase() ??
                                'U',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.slate700,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  // Name & Desc & Group
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['name'],
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.slate900,
                          ),
                        ),
                        Text(
                          item['description'],
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.slate500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.group,
                              size: 11,
                              color: AppColors.slate400,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              item['group_name'] ?? 'Nhóm',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.slate400,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Amount and Status
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatCurrency(item['amount']),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.red500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (item['payment_wallet_id'] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.amber100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '⏳ Chờ xác nhận',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: AppColors.amber700,
                            ),
                          ),
                        )
                      else
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: AppColors.slate400,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 5. People Owe Me Section (Người nợ tôi - chờ họ trả)
  Widget _buildPeopleOweMeSection() {
    // Nếu đang loading hoặc không có người nợ tôi, không hiển thị
    if (_isLoadingDebts || _peopleOweMe.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text(
          "Đang chờ thu",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.slate700,
          ),
        ),
        const SizedBox(height: 12),
        ..._peopleOweMe.map(
          (item) => GestureDetector(
            onTap: () async {
              // Người nợ TÔI -> Navigate tới màn hình xác nhận nhận tiền
              // Chỉ navigate nếu đã có payment request
              if (item['has_payment_request'] == true ||
                  item['is_paid'] == true) {
                final result = await context.push(
                  '/full-screen/debt/confirm',
                  extra: {
                    'debtId': item['debt_id'] ?? '',
                    'debtorName': item['name'] ?? 'Unknown',
                    'debtorAvatar': item['avatar'] ?? '',
                    'amount': item['amount'] ?? 0,
                    'description': item['description'] ?? '',
                    'groupName': item['group_name'] ?? 'Nhóm',
                    'proofImageUrl': item['expense_image_url'],
                    'paymentDate': item['payment_date'],
                    'paymentNote': item['payment_note'],
                    'isPaid': item['is_paid'] ?? false,
                    'receivedWalletId': item['received_wallet_id'],
                    'hasPaymentRequest': item['has_payment_request'] ?? false,
                  },
                );

                // Refresh if confirmed
                if (result == true) {
                  _fetchDebtData();
                }
              } else {
                // Chưa có payment request
                PopupNotification.showInfo(
                  context,
                  'Chờ ${item['name']} gửi yêu cầu thanh toán để bạn xác nhận.',
                );
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
                        (item['avatar'] != null &&
                            item['avatar'].toString().isNotEmpty &&
                            item['avatar'].toString().startsWith('http'))
                        ? NetworkImage(item['avatar'])
                        : null,
                    child:
                        (item['avatar'] == null ||
                            item['avatar'].toString().isEmpty ||
                            !item['avatar'].toString().startsWith('http'))
                        ? Text(
                            item['name']
                                    ?.toString()
                                    .substring(0, 1)
                                    .toUpperCase() ??
                                'U',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.slate700,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  // Name & Desc & Group
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['name'],
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.slate900,
                          ),
                        ),
                        Text(
                          item['description'],
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.slate500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.group,
                              size: 11,
                              color: AppColors.slate400,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              item['group_name'] ?? 'Nhóm',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.slate400,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Amount & Status
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatCurrency(item['amount']),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.green500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Badge cho payment status
                      if (item['is_paid'] == true)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.green100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Đã nhận',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.green600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      else if (item['has_payment_request'] == true)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.amber100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Đã gửi',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.amber700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      else
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: AppColors.slate400,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
