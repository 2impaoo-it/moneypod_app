import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../repositories/group_repository.dart';

// --- UTILS: Colors & Helpers (Copy-paste friendly) ---
import '../theme/app_colors.dart';

// Helper format tiền tệ đơn giản (VD: 2500000 -> 2.500.000 ₫)
String formatCurrency(int amount) {
  final str = amount.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (Match m) => '${m[1]}.',
  );
  return '$str ₫';
}

final Map<String, dynamic> debtOptimization = {
  "from": {"name": "Minh", "avatar": "M"},
  "to": {"name": "Lan", "avatar": "L"},
  "amount": 150000,
};

final List<Map<String, dynamic>> pendingSettlements = [
  {
    "name": "Hùng",
    "avatar": "H",
    "description": "Tiền ăn tối nhóm",
    "amount": 85000,
  },
  {
    "name": "Linh",
    "avatar": "Li",
    "description": "Tiền Grab đi chung",
    "amount": 45000,
  },
];

// --- MAIN SCREEN ---
class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  // Data list
  List<Map<String, dynamic>> _groupsList = [];
  bool _isLoading = true;
  final GroupRepository _groupRepository = GroupRepository();

  @override
  void initState() {
    super.initState();
    _fetchGroups();
  }

  Future<void> _fetchGroups() async {
    try {
      final groups = await _groupRepository.getGroups();

      // Map API data to UI model
      final mappedGroups = groups.map((g) {
        print("DEBUG GROUP: ${g['name']} - Members: ${g['members']}");
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
            print('Error parsing deadline: $e');
          }
        }

        // Parse members
        final membersList = g['members'] as List? ?? [];
        final int memberCount = membersList.length;
        print("DEBUG: Group ${g['name']} has ${membersList.length} members");

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
      print('Error fetching groups: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi tải danh sách nhóm: $e')));
      }
    }
  }

  void _navigateToCreateGroup() async {
    await context.push('/groups/create');
    // Luôn refresh kể cả khi back về, để đảm bảo data mới nhất
    _fetchGroups();
  }

  void _navigateToGroupDetail(Map<String, dynamic> group) {
    context.push(
      '/groups/${group['id']}',
      extra: {'groupName': group['name'], 'inviteCode': group['inviteCode']},
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
          onRefresh: _fetchGroups,
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

                // 3. Debt Optimization Section (Static UI for now)
                _buildDebtOptimizationSection(),

                // 4. Pending Settlements Section (Static UI for now)
                _buildPendingSettlementsSection(),

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
    return Row(
      children: [
        const Text(
          "Nhóm chi tiêu",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.slate900,
          ),
        ),
        const Spacer(),
        InkWell(
          onTap: _navigateToCreateGroup,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.teal500,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: const [
                Icon(Icons.add, color: Colors.white, size: 16),
                SizedBox(width: 4),
                Text(
                  "Tạo nhóm mới",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
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
              color: Colors.black.withOpacity(
                0.05,
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

  // 3. Debt Optimization Section
  Widget _buildDebtOptimizationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        // Title Row
        Row(
          children: const [
            Icon(
              Icons.auto_awesome,
              color: AppColors.amber500,
              size: 20,
            ), // Icon Sparkles tương tự
            SizedBox(width: 8),
            Text(
              "Tối ưu trả nợ",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.slate700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Debt Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.amber50, AppColors.orange50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: AppColors.amber200),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // Row: From -> To + Amount
              Row(
                children: [
                  _buildAvatarCircle(
                    debtOptimization['from']['avatar'],
                    debtOptimization['from']['name'],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Icon(
                      Icons.arrow_forward,
                      color: AppColors.amber500,
                      size: 18,
                    ),
                  ),
                  _buildAvatarCircle(
                    debtOptimization['to']['avatar'],
                    debtOptimization['to']['name'],
                  ),
                  const Spacer(),
                  Text(
                    formatCurrency(debtOptimization['amount']),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.amber500,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    "Đánh dấu đã trả",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper cho Avatar trong Debt Card
  Widget _buildAvatarCircle(String char, String name) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.slate200,
          child: Text(
            char,
            style: const TextStyle(fontSize: 12, color: AppColors.slate700),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          name,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.slate700,
          ),
        ),
      ],
    );
  }

  // 4. Pending Settlements Section
  Widget _buildPendingSettlementsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text(
          "Chờ thanh toán",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.slate700,
          ),
        ),
        const SizedBox(height: 12),
        ...pendingSettlements.map(
          (item) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.slate100,
              ), // Thêm border nhẹ cho rõ ràng
            ),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.slate200,
                  child: Text(
                    item['avatar'],
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.slate700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Name & Desc
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
                    ],
                  ),
                ),
                // Amount
                Text(
                  formatCurrency(item['amount']),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.red500,
                  ),
                ),
                const SizedBox(width: 12),
                // Action Buttons Column
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () {},
                      child: const Icon(
                        Icons.notifications_none,
                        size: 20,
                        color: AppColors.slate400,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () {},
                      child: const Icon(
                        Icons.check_circle_outline,
                        size: 20,
                        color: AppColors.teal500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
