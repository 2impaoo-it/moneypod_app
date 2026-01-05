import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../main.dart'; // Import for AppColors

import '../models/profile.dart';
import '../repositories/group_repository.dart';
import '../repositories/profile_repository.dart';
import '../services/auth_service.dart';
import '../utils/currency_input_formatter.dart';
import '../utils/popup_notification.dart';

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
  List<dynamic> _groupMembers = []; // Members of selected group
  String? _selectedGroupId;
  String? _selectedPayerId; // If null => will use _currentUserId
  String? _currentUserId;

  // Multi-image
  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  bool _isLoadingGroups = true;
  bool _isAnalyzing = false; // Analyzing AI

  bool _isSplitEqually = true;
  final Map<String, TextEditingController> _splitControllers = {};

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
          // Ensure pre-selected group is valid
          if (_selectedGroupId != null) {
            final exists = groups.any((g) => g['id'] == _selectedGroupId);
            if (!exists) {
              _selectedGroupId = null;
            } else {
              // If group selected, load members
              _loadGroupMembers(_selectedGroupId!);
            }
          }
          // Default payer to current user if available
          if (_selectedPayerId == null && _currentUserId != null) {
            _selectedPayerId = _currentUserId;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingGroups = false);
        PopupNotification.showError(context, 'Lỗi tải dữ liệu: $e');
      }
    }
  }

  Future<void> _loadGroupMembers(String groupId) async {
    try {
      final groupDetails = await _groupRepo.getGroupDetails(groupId);
      if (mounted) {
        setState(() {
          _groupMembers = groupDetails['members'] ?? [];
          // Reset split controllers
          for (var controller in _splitControllers.values) {
            controller.dispose();
          }
          _splitControllers.clear();

          for (var member in _groupMembers) {
            final user = member['user'] ?? {};
            final userId = user['id'] ?? member['id'] ?? '';
            if (userId.toString().isNotEmpty) {
              _splitControllers[userId.toString()] = TextEditingController();
            }
          }
        });
      }
    } catch (e) {
      print('Error loading members: $e');
    }
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Chụp ảnh'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: AppColors.primary,
              ),
              title: const Text('Chọn từ thư viện'),
              onTap: () {
                Navigator.pop(context);
                _pickMultiImage();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedImages.add(File(image.path));
        });
      }
    } catch (e) {
      PopupNotification.showError(context, 'Lỗi chụp ảnh: $e');
    }
  }

  Future<void> _pickMultiImage() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(imageQuality: 85);
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images.map((img) => File(img.path)));
        });
      }
    } catch (e) {
      PopupNotification.showError(context, 'Lỗi chọn ảnh: $e');
    }
  }

  Future<void> _analyzeReceipts() async {
    if (_selectedImages.isEmpty) return;

    setState(() => _isAnalyzing = true);
    try {
      final result = await _groupRepo.scanReceipts(_selectedImages);

      if (mounted) {
        // Auto-fill data
        // Amount
        if (result['amount'] != null) {
          final amount = result['amount'];
          _amountController.text = amount.toString(); // Simple set
        }

        // Description
        if (result['merchant'] != null || result['category'] != null) {
          String desc = result['merchant'] ?? '';
          if (result['category'] != null) {
            desc += " (${result['category']})";
          }
          _descriptionController.text = desc;
        }

        PopupNotification.showSuccess(context, '✅ Đã phân tích hóa đơn!');
      }
    } catch (e) {
      if (mounted) {
        PopupNotification.showError(context, '⚠️ Lỗi AI: $e');
      }
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }

  void _handleSave() async {
    final amountText = _amountController.text.trim();
    final description = _descriptionController.text.trim();

    if (amountText.isEmpty) {
      PopupNotification.showError(context, 'Vui lòng nhập số tiền');
      return;
    }

    final amount = parseCurrency(amountText);
    if (amount == null || amount <= 0) {
      PopupNotification.showError(context, 'Số tiền không hợp lệ');
      return;
    }

    if (_selectedGroupId == null) {
      PopupNotification.showError(context, 'Vui lòng chọn nhóm');
      return;
    }

    if (description.isEmpty) {
      PopupNotification.showError(context, 'Vui lòng nhập nội dung chi tiêu');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Just upload the first image for now as 'bill image'
      // or we can skip if backend doesn't support array in AddExpenseRequest yet
      String? imageUrl;
      if (_selectedImages.isNotEmpty) {
        // Upload the first one as representative
        imageUrl = await _groupRepo.uploadImage(_selectedImages.first);
      }

      List<Map<String, dynamic>>? splitDetails = [];
      if (_isSplitEqually) {
        if (_groupMembers.isNotEmpty) {
          final share = amount / _groupMembers.length;
          for (var member in _groupMembers) {
            final user = member['user'] ?? {};
            final userId =
                user['id'] ?? member['user_id'] ?? member['id'] ?? '';
            if (userId.toString().isNotEmpty) {
              splitDetails.add({'user_id': userId, 'amount': share});
            }
          }
        }
      } else {
        // Chia cụ thể (Existing logic)
        double totalSplit = 0;
        for (var member in _groupMembers) {
          final user = member['user'] ?? {};
          final userId = user['id'] ?? member['user_id'] ?? member['id'] ?? '';
          final controller = _splitControllers[userId.toString()];
          if (userId.toString().isNotEmpty && controller != null) {
            final val = parseCurrency(controller.text) ?? 0;
            if (val > 0) {
              splitDetails.add({'user_id': userId, 'amount': val});
              totalSplit += val;
            }
          }
        }

        if ((totalSplit - amount).abs() > 1000) {
          // Tolerance 1000 VND
          if (mounted) {
            PopupNotification.showError(
              context,
              'Tổng tiền chia (${formatCurrency(totalSplit)}) không khớp với tổng hóa đơn (${formatCurrency(amount)})',
            );
            setState(() => _isLoading = false);
            return;
          }
        }
      }

      await _groupRepo.addExpense(
        groupId: _selectedGroupId!,
        amount: amount,
        description: description,
        payerId:
            _selectedPayerId ?? _currentUserId, // Updated to use selected payer
        imageUrl: imageUrl,
        splitDetails: splitDetails,
      );

      if (mounted) {
        setState(() => _isLoading = false);

        // Pop trước để quay về màn hình nhóm
        Navigator.pop(context, true);

        // Show notification sau khi đã pop
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            PopupNotification.showSuccess(
              context,
              '✅ Đã thêm chi tiêu thành công!',
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        PopupNotification.showError(context, '❌ Lỗi: $e');
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    for (var controller in _splitControllers.values) {
      controller.dispose();
    }
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
                    onChanged: (value) =>
                        setState(() {}), // Refresh for summary
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
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
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
                        // Reset Payer to current user (default)
                        // Will be updated when members load if current user is in list
                        if (_currentUserId != null) {
                          _selectedPayerId = _currentUserId;
                        }
                        // Load members for new group
                        if (val != null) {
                          _loadGroupMembers(val);
                        } else {
                          _groupMembers = [];
                        }
                      });
                    },
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Payer Selector (Only show if group selected)
            if (_selectedGroupId != null && _groupMembers.isNotEmpty) ...[
              const Text(
                "Người trả tiền",
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
                    hint: const Text("Chọn người trả"),
                    items: _groupMembers.map((member) {
                      final user = member['user'] ?? {};
                      final userId =
                          user['id'] ?? member['user_id'] ?? member['id'] ?? '';
                      final name =
                          user['full_name'] ??
                          user['name'] ??
                          member['email'] ??
                          'Thành viên';
                      final isMe = userId == _currentUserId;
                      return DropdownMenuItem<String>(
                        value: userId.toString(),
                        child: Text(isMe ? 'Tôi ($name)' : name),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedPayerId = val;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Info Text
            if (_selectedGroupId != null) ...[
              const Text(
                "Cách chia tiền",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text("Chia đều"),
                      value: true,
                      groupValue: _isSplitEqually,
                      onChanged: (val) =>
                          setState(() => _isSplitEqually = val!),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text("Chia cụ thể"),
                      value: false,
                      groupValue: _isSplitEqually,
                      onChanged: (val) =>
                          setState(() => _isSplitEqually = val!),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),

              if (!_isSplitEqually) ...[
                const SizedBox(height: 12),
                ..._groupMembers.map((member) {
                  final user = member['user'] ?? {};
                  final userId = user['id'] ?? member['id'] ?? '';
                  final userName =
                      user['full_name'] ??
                      user['name'] ??
                      member['email'] ??
                      'Thành viên';
                  final controller = _splitControllers[userId.toString()];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(child: Text(userName)),
                        SizedBox(
                          width: 150,
                          child: TextField(
                            controller: controller,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              CurrencyInputFormatter(),
                            ],
                            decoration: const InputDecoration(
                              hintText: '0 ₫',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const Divider(),
              ] else ...[
                Builder(
                  builder: (context) {
                    final amount =
                        parseCurrency(_amountController.text.trim()) ?? 0;
                    final memberCount = _groupMembers.length;
                    final share = memberCount > 0
                        ? (amount / memberCount)
                        : 0.0;

                    String payerName = 'Ai đó';
                    if (_selectedPayerId != null) {
                      final payer = _groupMembers.firstWhere(
                        (m) =>
                            (m['user']?['id'] ?? m['user_id'] ?? m['id'])
                                .toString() ==
                            _selectedPayerId,
                        orElse: () => null,
                      );
                      if (payer != null) {
                        final u = payer['user'] ?? {};
                        payerName = u['full_name'] ?? u['name'] ?? 'Thành viên';
                        if (_selectedPayerId == _currentUserId) {
                          payerName = 'Bạn';
                        }
                      }
                    }

                    return Container(
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
                              "$payerName đã trả, mỗi người đóng ${formatCurrency(share)}.",
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: 24),
            ],

            // Multi-Image Picker & Analyze
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Ảnh hóa đơn (Tùy chọn)",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                if (_selectedImages.isNotEmpty && !_isAnalyzing)
                  TextButton.icon(
                    onPressed: _analyzeReceipts,
                    icon: const Icon(Icons.auto_awesome, size: 16),
                    label: const Text("Phân tích AI"),
                    style: TextButton.styleFrom(foregroundColor: Colors.purple),
                  ),
                if (_isAnalyzing)
                  const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Image List
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Add Button
                  GestureDetector(
                    onTap: _showImageOptions,
                    child: Container(
                      width: 100,
                      height: 100,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, color: Colors.grey, size: 32),
                          SizedBox(height: 4),
                          Text(
                            "Thêm ảnh",
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Selected Images
                  ..._selectedImages.asMap().entries.map((entry) {
                    final index = entry.key;
                    final file = entry.value;
                    return Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          margin: const EdgeInsets.only(right: 12),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(file, fit: BoxFit.cover),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 16, // offset for margin
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedImages.removeAt(index);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
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
