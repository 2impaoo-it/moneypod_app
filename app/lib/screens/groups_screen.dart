import 'package:flutter/material.dart';
import '../services/group_service.dart';
import '../models/group.dart';
import 'group_detail_screen.dart';

// --- UTILS: Colors & Helpers (Copy-paste friendly) ---
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
  static const Color green700 = Color(0xFF15803D);

  static const Color amber50  = Color(0xFFFFFBEB);
  static const Color amber200 = Color(0xFFFDE68A);
  static const Color amber500 = Color(0xFFF59E0B);

  static const Color orange50 = Color(0xFFFFF7ED);
  static const Color red500   = Color(0xFFEF4444);
}

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
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final GroupService _groupService = GroupService();
  bool _isCreating = false;
  bool _isLoading = true;
  List<Group> _groups = [];

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    setState(() => _isLoading = true);
    
    try {
      final response = await _groupService.getMyGroups();
      if (mounted && response['success'] == true) {
        setState(() {
          _groups = response['groups'] as List<Group>;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải danh sách: ${e.toString()}'),
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

  Future<void> _handleCreateGroup() async {
    final TextEditingController nameController = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Tạo quỹ nhóm mới',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.slate900,
            ),
          ),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Tên quỹ nhóm',
              hintText: 'VD: Du lịch Đà Lạt',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vui lòng nhập tên quỹ nhóm'),
                      backgroundColor: AppColors.red500,
                    ),
                  );
                  return;
                }
                Navigator.of(context).pop(name);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.teal500,
                foregroundColor: Colors.white,
              ),
              child: const Text('Tạo'),
            ),
          ],
        );
      },
    );

    if (result == null || result.isEmpty) return;

    setState(() => _isCreating = true);

    try {
      final response = await _groupService.createGroup(name: result);
      
      if (!mounted) return;
      
      if (response['success'] == true) {
        // Reload danh sách groups
        await _loadGroups();
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Tạo quỹ thành công!'),
            backgroundColor: AppColors.green500,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Tạo quỹ thất bại'),
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
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.teal500),
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadGroups,
                color: AppColors.teal500,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Header Section
                      _buildHeader(),

                      // 2. Groups Section
                      if (_groups.isEmpty) ...[
                        const SizedBox(height: 60),
                        Center(
                          child: Column(
                            children: const [
                              Icon(
                                Icons.groups_outlined,
                                size: 80,
                                color: AppColors.slate300,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Chưa có quỹ nhóm nào',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.slate500,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Tạo quỹ mới để bắt đầu',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.slate400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 20),
                        const Text(
                          "Danh sách quỹ nhóm",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.slate700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._groups.map((g) => _buildGroupCard(g)),
                      ],

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // --- WIDGET COMPONENTS ---  // --- WIDGET COMPONENTS ---

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
          onTap: _isCreating ? null : _handleCreateGroup,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: _isCreating ? AppColors.slate300 : AppColors.teal500,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                if (_isCreating)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else
                  const Icon(Icons.add, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text(
                  _isCreating ? "Đang tạo..." : "Tạo quỹ mới",
                  style: const TextStyle(
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

  // 2. Group Card
  Widget _buildGroupCard(Group group) {
    final memberCount = group.members?.length ?? 0;

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => GroupDetailScreen(group: group),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon Circle
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.teal400, AppColors.teal500],
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
                  group.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate900,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  "$memberCount thành viên",
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.slate500,
                  ),
                ),
              ],
            ),
          ),
          // Code badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.teal50,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              group.code,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.teal700,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),     
    ),
    );
  }
}