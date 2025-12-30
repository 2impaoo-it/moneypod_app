import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../main.dart';
import '../bloc/savings/savings_bloc.dart';
import '../bloc/savings/savings_event.dart';
import '../bloc/savings/savings_state.dart';
import '../repositories/savings_repository.dart';

/// Màn hình tạo mục tiêu tiết kiệm mới
class CreateSavingsGoalScreen extends StatelessWidget {
  const CreateSavingsGoalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SavingsBloc(SavingsRepository()),
      child: const CreateSavingsGoalContent(),
    );
  }
}

class CreateSavingsGoalContent extends StatefulWidget {
  const CreateSavingsGoalContent({super.key});

  @override
  State<CreateSavingsGoalContent> createState() =>
      _CreateSavingsGoalContentState();
}

class _CreateSavingsGoalContentState extends State<CreateSavingsGoalContent> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetAmountController = TextEditingController();
  final _initialAmountController = TextEditingController(text: '0');

  DateTime? _selectedDate;
  bool _isLoading = false;

  // Selected icon and color
  String _selectedIcon = 'savings';
  String _selectedColor = 'blue';

  final currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  // Available icons
  final List<Map<String, dynamic>> _availableIcons = [
    {'key': 'savings', 'icon': LucideIcons.piggyBank, 'label': 'Tiết kiệm'},
    {
      'key': 'smartphone',
      'icon': LucideIcons.smartphone,
      'label': 'Điện thoại',
    },
    {'key': 'laptop', 'icon': LucideIcons.laptop, 'label': 'Laptop'},
    {'key': 'plane', 'icon': LucideIcons.plane, 'label': 'Du lịch'},
    {'key': 'car', 'icon': LucideIcons.car, 'label': 'Xe hơi'},
    {'key': 'bike', 'icon': LucideIcons.bike, 'label': 'Xe máy'},
    {'key': 'home', 'icon': LucideIcons.home, 'label': 'Nhà'},
    {
      'key': 'graduationCap',
      'icon': LucideIcons.graduationCap,
      'label': 'Học tập',
    },
    {'key': 'heart', 'icon': LucideIcons.heart, 'label': 'Sức khỏe'},
    {'key': 'gift', 'icon': LucideIcons.gift, 'label': 'Quà tặng'},
    {'key': 'shield', 'icon': LucideIcons.shield, 'label': 'Khẩn cấp'},
    {'key': 'trending', 'icon': LucideIcons.trendingUp, 'label': 'Đầu tư'},
  ];

  // Available colors
  final List<Map<String, dynamic>> _availableColors = [
    {
      'key': 'blue',
      'color': const Color(0xFF3B82F6),
      'gradient': [const Color(0xFF3B82F6), const Color(0xFF2563EB)],
    },
    {
      'key': 'teal',
      'color': const Color(0xFF14B8A6),
      'gradient': [const Color(0xFF14B8A6), const Color(0xFF0D9488)],
    },
    {
      'key': 'purple',
      'color': const Color(0xFF8B5CF6),
      'gradient': [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)],
    },
    {
      'key': 'orange',
      'color': const Color(0xFFF97316),
      'gradient': [const Color(0xFFF97316), const Color(0xFFEA580C)],
    },
    {
      'key': 'green',
      'color': const Color(0xFF22C55E),
      'gradient': [const Color(0xFF22C55E), const Color(0xFF16A34A)],
    },
    {
      'key': 'red',
      'color': const Color(0xFFEF4444),
      'gradient': [const Color(0xFFEF4444), const Color(0xFFDC2626)],
    },
    {
      'key': 'pink',
      'color': const Color(0xFFEC4899),
      'gradient': [const Color(0xFFEC4899), const Color(0xFFDB2777)],
    },
    {
      'key': 'indigo',
      'color': const Color(0xFF6366F1),
      'gradient': [const Color(0xFF6366F1), const Color(0xFF4F46E5)],
    },
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _targetAmountController.dispose();
    _initialAmountController.dispose();
    super.dispose();
  }

  Color get _currentColor {
    return _availableColors.firstWhere(
      (c) => c['key'] == _selectedColor,
      orElse: () => _availableColors.first,
    )['color'];
  }

  List<Color> get _currentGradient {
    return _availableColors.firstWhere(
      (c) => c['key'] == _selectedColor,
      orElse: () => _availableColors.first,
    )['gradient'];
  }

  IconData get _currentIcon {
    return _availableIcons.firstWhere(
      (i) => i['key'] == _selectedIcon,
      orElse: () => _availableIcons.first,
    )['icon'];
  }

  void _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedDate ?? DateTime.now().add(const Duration(days: 180)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _currentColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ngày mục tiêu'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Parse số tiền
      final targetAmount =
          double.tryParse(
            _targetAmountController.text.replaceAll(RegExp(r'[^\d]'), ''),
          ) ??
          0;

      // Convert color key to hex
      String colorHex = '#8B5CF6'; // Default purple
      switch (_selectedColor) {
        case 'blue':
          colorHex = '#3B82F6';
          break;
        case 'teal':
          colorHex = '#14B8A6';
          break;
        case 'purple':
          colorHex = '#8B5CF6';
          break;
        case 'orange':
          colorHex = '#F97316';
          break;
        case 'green':
          colorHex = '#22C55E';
          break;
        case 'red':
          colorHex = '#EF4444';
          break;
        case 'pink':
          colorHex = '#EC4899';
          break;
        case 'indigo':
          colorHex = '#6366F1';
          break;
      }

      // Tạo mục tiêu qua Bloc
      context.read<SavingsBloc>().add(
        CreateSavingsGoal(
          name: _nameController.text,
          targetAmount: targetAmount,
          color: colorHex,
          icon: _selectedIcon,
          deadline: _selectedDate,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SavingsBloc, SavingsState>(
      listener: (context, state) {
        if (state is SavingsLoading) {
          setState(() => _isLoading = true);
        } else if (state is SavingsActionSuccess) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.success,
            ),
          );
          context.pop(true);
        } else if (state is SavingsError) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.x, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Mục tiêu mới',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Preview Card
                _buildPreviewCard(),
                const SizedBox(height: 20),

                // Basic Info
                _buildBasicInfoCard(),
                const SizedBox(height: 20),

                // Icon Selection
                _buildIconSelectionCard(),
                const SizedBox(height: 20),

                // Color Selection
                _buildColorSelectionCard(),
                const SizedBox(height: 24),

                // Action Buttons
                _buildActionButtons(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    final targetAmount =
        double.tryParse(
          _targetAmountController.text.replaceAll(RegExp(r'[^\d]'), ''),
        ) ??
        0;
    final initialAmount =
        double.tryParse(
          _initialAmountController.text.replaceAll(RegExp(r'[^\d]'), ''),
        ) ??
        0;
    final progress = targetAmount > 0
        ? (initialAmount / targetAmount).clamp(0.0, 1.0)
        : 0.0;
    final name = _nameController.text.isEmpty
        ? 'Mục tiêu tiết kiệm'
        : _nameController.text;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _currentGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _currentColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_currentIcon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_selectedDate != null)
                      Text(
                        'Mục tiêu: ${DateFormat('dd/MM/yyyy').format(_selectedDate!)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Progress
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                initialAmount > 0
                    ? currencyFormat.format(initialAmount)
                    : '0 ₫',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                targetAmount > 0
                    ? '/ ${currencyFormat.format(targetAmount)}'
                    : '/ 0 ₫',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thông tin mục tiêu',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Name field
          _buildTextField(
            controller: _nameController,
            label: 'Tên mục tiêu',
            hint: 'VD: iPhone 16 Pro, Du lịch Nhật Bản...',
            icon: LucideIcons.target,
            isRequired: true,
            validator: (value) {
              if (value?.trim().isEmpty ?? true) {
                return 'Vui lòng nhập tên mục tiêu';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Target amount
          _buildTextField(
            controller: _targetAmountController,
            label: 'Số tiền mục tiêu',
            hint: '25.000.000',
            icon: LucideIcons.banknote,
            isRequired: true,
            keyboardType: TextInputType.number,
            suffix: '₫',
            validator: (value) {
              final amount = double.tryParse(
                value?.replaceAll(RegExp(r'[^\d]'), '') ?? '',
              );
              if (amount == null || amount <= 0) {
                return 'Vui lòng nhập số tiền hợp lệ';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Date picker
          _buildDateField(),
          const SizedBox(height: 16),

          // Initial amount
          _buildTextField(
            controller: _initialAmountController,
            label: 'Số tiền ban đầu',
            hint: '0',
            icon: LucideIcons.wallet,
            keyboardType: TextInputType.number,
            suffix: '₫',
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isRequired = false,
    TextInputType? keyboardType,
    String? suffix,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: _currentColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(fontSize: 13, color: AppColors.danger),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: AppColors.textMuted.withOpacity(0.5),
              fontWeight: FontWeight.normal,
            ),
            suffixText: suffix,
            suffixStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
            filled: true,
            fillColor: AppColors.background,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.textMuted.withOpacity(0.1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _currentColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.danger),
            ),
          ),
          validator: validator,
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(LucideIcons.calendar, size: 16, color: _currentColor),
            const SizedBox(width: 8),
            const Text(
              'Ngày mục tiêu',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const Text(
              ' *',
              style: TextStyle(fontSize: 13, color: AppColors.danger),
            ),
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectDate,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.textMuted.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedDate != null
                        ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                        : 'Chọn ngày hoàn thành mục tiêu',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: _selectedDate != null
                          ? FontWeight.w500
                          : FontWeight.normal,
                      color: _selectedDate != null
                          ? AppColors.textPrimary
                          : AppColors.textMuted.withOpacity(0.5),
                    ),
                  ),
                ),
                Icon(
                  LucideIcons.chevronDown,
                  size: 20,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIconSelectionCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chọn biểu tượng',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _availableIcons.map((item) {
              final isSelected = item['key'] == _selectedIcon;
              return GestureDetector(
                onTap: () => setState(() => _selectedIcon = item['key']),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _currentColor.withOpacity(0.1)
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? _currentColor : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    item['icon'],
                    color: isSelected ? _currentColor : AppColors.textMuted,
                    size: 24,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildColorSelectionCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chọn màu sắc',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _availableColors.map((item) {
              final isSelected = item['key'] == _selectedColor;
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = item['key']),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: item['gradient']),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.textPrimary
                          : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: item['color'].withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(
                          LucideIcons.check,
                          color: Colors.white,
                          size: 20,
                        )
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: _currentColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              disabledBackgroundColor: _currentColor.withOpacity(0.5),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.check, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Tạo mục tiêu',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: BorderSide(
                color: AppColors.textMuted.withOpacity(0.3),
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Hủy',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}
