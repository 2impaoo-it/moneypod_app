import 'package:flutter/material.dart';
import 'dart:ui';

// --- UTILS: Colors & Styles ---
class AppColors {
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate900 = Color(0xFF0F172A);

  static const Color violet500 = Color(0xFF8B5CF6);
  static const Color purple600 = Color(0xFF9333EA);

  // Category Colors
  static const Color blue100 = Color(0xFFDBEAFE);
  static const Color blue500 = Color(0xFF3B82F6);
  static const Color blue600 = Color(0xFF2563EB);

  static const Color teal100 = Color(0xFFCCFBF1);
  static const Color teal500 = Color(0xFF14B8A6);
  static const Color teal600 = Color(0xFF0D9488);

  static const Color orange100 = Color(0xFFFFEDD5);
  static const Color orange600 = Color(0xFFEA580C);

  static const Color purple100 = Color(0xFFF3E8FF);
  // static const Color purple600 đã khai báo ở trên
}

// Helper format tiền tệ
String formatCurrency(int amount) {
  final str = amount.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (Match m) => '${m[1]}.',
  );
  return '$str ₫';
}

// --- MOCK DATA ---
final List<Map<String, dynamic>> savingsGoals = [
  {
    "id": 1,
    "name": "iPhone 16 Pro",
    "icon": "smartphone",
    "color": "blue",
    "current": 3500000,
    "target": 25000000,
    "targetDate": "15/06/2025",
    "monthlyNeeded": 4300000,
  },
  {
    "id": 2,
    "name": "Du lịch Nhật Bản",
    "icon": "plane",
    "color": "teal",
    "current": 5000000,
    "target": 30000000,
    "targetDate": "01/12/2025",
    "monthlyNeeded": 2500000,
  },
  {
    "id": 3,
    "name": "Xe máy mới",
    "icon": "bike",
    "color": "orange",
    "current": 15000000,
    "target": 35000000,
    "targetDate": "01/03/2026",
    "monthlyNeeded": 1500000,
  },
];

final List<Map<String, dynamic>> suggestedGoals = [
  {
    "title": "Quỹ khẩn cấp",
    "description": "Nên có 3-6 tháng chi tiêu",
    "icon": "shield",
  },
  {
    "title": "Quỹ hưu trí",
    "description": "Bắt đầu sớm để hưởng lợi kép",
    "icon": "trending_up",
  },
];

// --- MAIN SCREEN ---
class SavingsScreen extends StatefulWidget {
  const SavingsScreen({super.key});

  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> {
  Future<void> _onRefresh() async {
    // Giả lập delay load lại dữ liệu
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      // Logic reload data sẽ nằm ở đây
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: SingleChildScrollView(
            // AlwaysScrollableScrollPhysics giúp pull-to-refresh hoạt động ngay cả khi nội dung ngắn
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header Section
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: const Text(
                    "Tiết kiệm",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate900,
                    ),
                  ),
                ),

                // 2. Total Savings Card
                _buildTotalSavingsCard(),

                // 3. Savings Goals Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Mục tiêu của bạn",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.slate700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...savingsGoals
                          .map((goal) => _buildSavingsGoalCard(goal))
                          ,
                    ],
                  ),
                ),

                // 4. Suggested Goals Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      const Text(
                        "Gợi ý cho bạn",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.slate700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...suggestedGoals
                          .map((sg) => _buildSuggestionCard(sg))
                          ,
                      const SizedBox(height: 40), // Bottom padding
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGET COMPONENTS ---

  // 2. Total Savings Card
  Widget _buildTotalSavingsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.violet500, AppColors.purple600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.violet500.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Tổng tiết kiệm",
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "8.500.000 ₫",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.trending_up, color: Colors.white, size: 16),
                SizedBox(width: 4),
                Text(
                  "↑ 12% so với tháng trước",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
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

  // 3. Savings Goal Card
  Widget _buildSavingsGoalCard(Map<String, dynamic> goal) {
    // Helper lấy màu và icon theo data
    final String colorKey = goal['color'];
    final IconData iconData = _getIconData(goal['icon']);

    // Define Color Palette cho item này
    Color bgIconColor;
    Color iconColor;
    Color buttonColor;
    List<Color> gradientColors;

    switch (colorKey) {
      case 'blue':
        bgIconColor = AppColors.blue100;
        iconColor = AppColors.blue600;
        buttonColor = AppColors.blue500;
        gradientColors = [AppColors.blue500, AppColors.blue600];
        break;
      case 'teal':
        bgIconColor = AppColors.teal100;
        iconColor = AppColors.teal600;
        buttonColor = AppColors.teal500;
        gradientColors = [AppColors.teal500, AppColors.teal600];
        break;
      case 'orange':
        bgIconColor = AppColors.orange100;
        iconColor = AppColors.orange600;
        buttonColor = AppColors.orange600; // orange600 đậm hơn cho button
        gradientColors = [Colors.orange, AppColors.orange600];
        break;
      default: // Purple
        bgIconColor = AppColors.purple100;
        iconColor = AppColors.purple600;
        buttonColor = AppColors.purple600;
        gradientColors = [AppColors.violet500, AppColors.purple600];
    }

    // Tính toán số liệu
    final double progress = (goal['current'] / goal['target']).clamp(0.0, 1.0);
    final int remaining = goal['target'] - goal['current'];
    final int percentage = (progress * 100).toInt();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            print("Xem chi tiết mục tiêu: ${goal['name']}");
          },
          onLongPress: () {
            _showOptionsDialog(context, goal['name']);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // a) Header Row
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: bgIconColor,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Icon(iconData, color: iconColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goal['name'],
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.slate900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Mục tiêu: ${goal['targetDate']}",
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.slate500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.more_vert, color: AppColors.slate400),
                  ],
                ),

                // b) Progress Section
                const SizedBox(height: 16),
                // Custom Animated Progress Bar
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return Stack(
                      children: [
                        Container(
                          height: 10,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.slate100,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: value,
                          child: Container(
                            height: 10,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: gradientColors),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formatCurrency(goal['current']),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: buttonColor,
                      ),
                    ),
                    Text(
                      "/ ${formatCurrency(goal['target'])}",
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.slate500,
                      ),
                    ),
                  ],
                ),

                // c) Stats Row
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatItem("Tiến độ", "$percentage%"),
                    _buildStatItem("Còn lại", formatCurrency(remaining)),
                    _buildStatItem(
                      "Mỗi tháng",
                      formatCurrency(goal['monthlyNeeded']),
                    ),
                  ],
                ),

                // d) Action Button
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.add, size: 16),
                        SizedBox(width: 4),
                        Text(
                          "Thêm tiền",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.slate400),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.slate700,
          ),
        ),
      ],
    );
  }

  // 4. Suggestion Card
  Widget _buildSuggestionCard(Map<String, dynamic> suggestion) {
    return CustomPaint(
      painter: DashedBorderPainter(color: AppColors.slate300, radius: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.slate50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIconData(suggestion['icon']),
                color: AppColors.teal500,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    suggestion['title'],
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.slate900,
                    ),
                  ),
                  Text(
                    suggestion['description'],
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.slate500,
                    ),
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 6,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.teal500),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "Bắt đầu",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.teal600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Maps
  IconData _getIconData(String name) {
    switch (name) {
      case 'smartphone':
        return Icons.smartphone;
      case 'plane':
        return Icons.flight_takeoff;
      case 'bike':
        return Icons.two_wheeler;
      case 'shield':
        return Icons.shield_outlined;
      case 'trending_up':
        return Icons.trending_up;
      default:
        return Icons.savings_outlined;
    }
  }

  // Dialog Options (Long press)
  void _showOptionsDialog(BuildContext context, String title) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit, color: AppColors.slate700),
                title: Text('Chỉnh sửa "$title"'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(
                  'Xóa mục tiêu',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }
}

// --- HELPER CLASSES ---

// Painter vẽ viền nét đứt (Dashed Border)
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;
  final double radius;

  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1,
    this.dashWidth = 5,
    this.dashSpace = 3,
    this.radius = 12,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final Path path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(radius),
        ),
      );

    final Path dashedPath = Path();
    double distance = 0.0;

    // Convert path to metrics to create dashes
    for (final PathMetric metric in path.computeMetrics()) {
      while (distance < metric.length) {
        dashedPath.addPath(
          metric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }
    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
