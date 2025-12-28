import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/profile.dart';
import '../repositories/group_repository.dart';
import '../repositories/profile_repository.dart';
import '../services/auth_service.dart';
import '../utils/currency_input_formatter.dart';

class AddExpenseScreen extends StatefulWidget {
  final String? preSelectedGroupId;

  const AddExpenseScreen({super.key, this.preSelectedGroupId});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _groupRepo = GroupRepository();
  final _profileRepo = ProfileRepository();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  List<Map<String, dynamic>> _groups = [];
  String? _selectedGroupId;
  String? _selectedPayerId; // If null => will use _currentUserId
  String? _currentUserId;

  bool _isLoading = false;
  bool _isLoadingGroups = true;

  @override
  void initState() {
    super.initState();
    _selectedGroupId = widget.preSelectedGroupId;
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final token = await AuthService().getToken();
      if (token == null) {
        throw Exception('Chưa đăng nhập');
      }

      final groupsFuture = _groupRepo.getGroups();
      final profileFuture = _profileRepo.fetchUserProfile(token);

      final results = await Future.wait([groupsFuture, profileFuture]);
      final groups = results[0] as List<Map<String, dynamic>>;
      final profile = results[1] as Profile?;

      if (mounted) {
        setState(() {
          _groups = groups;
          _currentUserId = profile?.id;
          _isLoadingGroups = false;
          // Ensure pre-selected group is valid, otherwise reset
          if (_selectedGroupId != null) {
            final exists = groups.any((g) => g['id'] == _selectedGroupId);
            if (!exists) _selectedGroupId = null;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingGroups = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi tải dữ liệu: $e')));
      }
    }
  }

  void _handleSave() async {
    final amountText = _amountController.text.trim();
    final description = _descriptionController.text.trim();

    if (amountText.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng nhập số tiền')));
      return;
    }

    final amount = parseCurrency(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Số tiền không hợp lệ')));
      return;
    }

    if (_selectedGroupId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng chọn nhóm')));
      return;
    }

    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập nội dung chi tiêu')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _groupRepo.addExpense(
        groupId: _selectedGroupId!,
        amount: amount,
        description: description,
        payerId: _selectedPayerId ?? _currentUserId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã thêm chi tiêu thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi: $e'), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Thêm chi tiêu nhóm',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount Input
            Center(
              child: Column(
                children: [
                  const Text("Số tiền", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      CurrencyInputFormatter(),
                    ],
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                    decoration: const InputDecoration(
                      hintText: '0 ₫',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Description Input
            const Text(
              "Nội dung",
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                hintText: 'Ví dụ: Ăn trưa, xem phim...',
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Group Selector
            const Text(
              "Nhóm",
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 12),
            if (_isLoadingGroups)
              const Center(child: CircularProgressIndicator())
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedGroupId,
                    isExpanded: true,
                    hint: const Text("Chọn nhóm"),
                    items: _groups
                        .map(
                          (g) => DropdownMenuItem(
                            value: g['id'] as String,
                            child: Text(g['name']),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedGroupId = val;
                        // Logic to reset payer or fetch group members would go here
                      });
                    },
                  ),
                ),
              ),

            const SizedBox(height: 8),
            // Info Text
            if (_selectedGroupId != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.blue.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Chia đều cho tất cả thành viên trong nhóm.",
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Payer Selector
            const Text(
              "Người trả",
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedPayerId,
                  isExpanded: true,
                  hint: const Text("Tôi (Mặc định)"),
                  icon: const Icon(Icons.person),
                  items: const [
                    DropdownMenuItem(value: null, child: Text("Tôi")),
                    // Optional: Add other members here
                  ],
                  onChanged: (val) {
                    setState(() => _selectedPayerId = val);
                  },
                ),
              ),
            ),

            const SizedBox(height: 48),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Lưu chi tiêu",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
