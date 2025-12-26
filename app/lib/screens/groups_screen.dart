import 'package:flutter/material.dart';

// --- UTILS: Colors & Helpers (Copy-paste friendly) ---
class AppColors {
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate900 = Color(0xFF0F172A);

  static const Color teal50 = Color(0xFFF0FDFA);
  static const Color teal400 = Color(0xFF2DD4BF);
  static const Color teal500 = Color(0xFF14B8A6);
  static const Color teal700 = Color(0xFF0F766E);

  static const Color green50 = Color(0xFFF0FDF4);
  static const Color green500 = Color(0xFF22C55E);
  static const Color green700 = Color(0xFF15803D);

  static const Color amber50 = Color(0xFFFFFBEB);
  static const Color amber200 = Color(0xFFFDE68A);
  static const Color amber500 = Color(0xFFF59E0B);

  static const Color orange50 = Color(0xFFFFF7ED);
  static const Color red500 = Color(0xFFEF4444);
}

// Helper format tiền tệ đơn giản (VD: 2500000 -> 2.500.000 ₫)
String formatCurrency(int amount) {
  final str = amount.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (Match m) => '${m[1]}.',
  );
  return '$str ₫';
}

// --- MOCK DATA ---
final List<Map<String, dynamic>> groups = [
  {
    "id": 1,
    "name": "Du lịch Đà Lạt",
    "members": 5,
    "avatars": ["A", "B", "C"], // Dùng chữ cái thay cho URL ảnh thật để demo
    "extraMembers": 2,
    "collected": 2500000,
    "target": 5000000,
    "status": "active",
    "daysLeft": 15,
  },
  {
    "id": 2,
    "name": "Tiền nhà tháng 1",
    "members": 3,
    "avatars": ["D", "E", "F"],
    "extraMembers": 0,
    "collected": 6000000,
    "target": 6000000,
    "status": "completed",
    "daysLeft": 0,
  },
];

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
class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Phân loại groups
    final activeGroups = groups.where((g) => g['status'] == 'active').toList();
    final completedGroups = groups
        .where((g) => g['status'] == 'completed')
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
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
                ...activeGroups.map((g) => _buildGroupCard(g)).toList(),
              ],

              // 3. Debt Optimization Section
              _buildDebtOptimizationSection(),

              // 4. Pending Settlements Section
              _buildPendingSettlementsSection(),

              // 6. Completed Groups Section (Yêu cầu ở mục 6)
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
                ...completedGroups.map((g) => _buildGroupCard(g)).toList(),
              ],

              const SizedBox(height: 40), // Bottom padding
            ],
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
          "Quỹ nhóm",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.slate900,
          ),
        ),
        const Spacer(),
        InkWell(
          onTap: () {},
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
                  "Tạo quỹ mới",
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
    final double progress = group['collected'] / group['target'];
    final int collected = group['collected'];
    final int target = group['target'];

    // Theme colors dựa trên status
    final Color badgeBg = isCompleted ? AppColors.green50 : AppColors.teal50;
    final Color badgeText = isCompleted
        ? AppColors.green700
        : AppColors.teal700;
    final String statusText = isCompleted ? "Hoàn thành" : "Đang hoạt động";

    return Container(
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
                child: const Icon(Icons.groups, color: Colors.white, size: 20),
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
                    return Positioned(
                      left: index * 16.0, // Overlap effect
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          color: (index == 2 && group['extraMembers'] > 0)
                              ? AppColors.slate200
                              : AppColors.slate300,
                        ),
                        alignment: Alignment.center,
                        child: (index == 2 && group['extraMembers'] > 0)
                            ? Text(
                                "+${group['extraMembers']}",
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.slate500,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : Text(
                                (group['avatars'][index] as String),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),

          // b) Progress Section
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Đã góp",
                style: TextStyle(fontSize: 12, color: AppColors.slate500),
              ),
              Text(
                "${formatCurrency(collected)} / ${formatCurrency(target)}",
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.slate700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Custom Progress Bar
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.slate100,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  return Container(
                    height: 8,
                    width:
                        constraints.maxWidth *
                        progress, // Width theo percentage
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isCompleted
                            ? [AppColors.green500, AppColors.green500]
                            : [AppColors.teal400, AppColors.teal500],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                },
              ),
            ],
          ),

          // c) Footer Row
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: badgeText,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              if (!isCompleted)
                Text(
                  "Còn ${group['daysLeft']} ngày",
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.slate400,
                  ),
                ),
            ],
          ),
        ],
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
        ...pendingSettlements
            .map(
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
            )
            .toList(),
      ],
    );
  }
}
