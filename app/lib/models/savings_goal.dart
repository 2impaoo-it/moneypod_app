/// Model cho Savings Goal - Khớp với server Go
class SavingsGoal {
  final String id; // UUID
  final String userId; // UUID
  final String name;
  final double targetAmount;
  final double currentAmount;
  final String? color; // Hex color code
  final String? icon;
  final String status; // IN_PROGRESS, COMPLETED
  final DateTime? deadline;
  final bool isOverdue; // Virtual field từ server
  final DateTime createdAt;
  final DateTime? updatedAt;

  SavingsGoal({
    required this.id,
    required this.userId,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    this.color,
    this.icon,
    required this.status,
    this.deadline,
    required this.isOverdue,
    required this.createdAt,
    this.updatedAt,
  });

  /// Tạo SavingsGoal từ JSON (từ server Go)
  factory SavingsGoal.fromJson(Map<String, dynamic> json) {
    return SavingsGoal(
      id: json['id']?.toString() ?? json['ID']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? json['UserID']?.toString() ?? '',
      name: json['name'] ?? '',
      targetAmount: _parseDouble(json['target_amount'] ?? 0),
      currentAmount: _parseDouble(json['current_amount'] ?? 0),
      color: json['color'],
      icon: json['icon'],
      status: json['status'] ?? 'IN_PROGRESS',
      deadline: _parseDateTime(json['deadline']),
      isOverdue: json['is_overdue'] ?? false,
      createdAt: _parseDateTime(json['created_at']) ?? 
          _parseDateTime(json['CreatedAt']) ?? 
          DateTime.now(),
      updatedAt: _parseDateTime(json['updated_at']) ?? 
          _parseDateTime(json['UpdatedAt']),
    );
  }

  /// Helper: Parse DateTime từ string, chỉ lấy ngày tháng năm
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) {
      return DateTime(value.year, value.month, value.day);
    }
    
    try {
      String dateStr = value.toString().trim();
      
      // Xử lý các format phổ biến từ server:
      // "2026-07-15T00:00:00.000+07:00"
      // "2026-07-15T00:00:00.000"
      // "2026-07-15T00:00:00"
      
      // Loại bỏ timezone nếu có (+07:00, -07:00, Z)
      dateStr = dateStr.replaceAll(RegExp(r'[+-]\d{2}:\d{2}$'), '');
      dateStr = dateStr.replaceAll('Z', '');
      
      // Loại bỏ milliseconds nếu có (.000, .123)
      if (dateStr.contains('.')) {
        dateStr = dateStr.split('.')[0];
      }
      
      // Parse và chỉ lấy phần date
      final parsed = DateTime.parse(dateStr);
      return DateTime(parsed.year, parsed.month, parsed.day);
    } catch (e) {
      print('⚠️ Lỗi parse datetime: $value - $e');
      return null;
    }
  }

  /// Helper: Parse double từ dynamic
  static double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Chuyển thành JSON để gửi lên server
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'target_amount': targetAmount,
      'color': color,
      'icon': icon,
      'deadline': deadline != null ? _formatDateTimeForServer(deadline!) : null,
    };
  }

  /// Format DateTime cho server Go (RFC3339 với timezone)
  static String _formatDateTimeForServer(DateTime dt) {
    // Chuyển sang UTC để có timezone Z ở cuối
    // Server Go expect: 2006-01-02T15:04:05Z07:00
    // Gửi format: 2026-06-28T00:00:00Z (UTC)
    final utc = DateTime.utc(dt.year, dt.month, dt.day, 0, 0, 0);
    return utc.toIso8601String(); // Tự động có 'Z' ở cuối vì là UTC
  }

  /// Copy with để tạo instance mới với các giá trị thay đổi
  SavingsGoal copyWith({
    String? id,
    String? userId,
    String? name,
    double? targetAmount,
    double? currentAmount,
    String? color,
    String? icon,
    String? status,
    DateTime? deadline,
    bool? isOverdue,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      status: status ?? this.status,
      deadline: deadline ?? this.deadline,
      isOverdue: isOverdue ?? this.isOverdue,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Tính % hoàn thành
  double get progressPercentage {
    if (targetAmount == 0) return 0;
    return (currentAmount / targetAmount * 100).clamp(0, 100);
  }

  /// Còn thiếu bao nhiêu
  double get remainingAmount {
    return (targetAmount - currentAmount).clamp(0, double.infinity);
  }
}

/// Model cho Savings Transaction (lịch sử nạp/rút)
class SavingsTransaction {
  final String id;
  final String goalId;
  final String walletId;
  final double amount;
  final String type; // DEPOSIT hoặc WITHDRAW
  final String? note;
  final DateTime createdAt;

  SavingsTransaction({
    required this.id,
    required this.goalId,
    required this.walletId,
    required this.amount,
    required this.type,
    this.note,
    required this.createdAt,
  });

  factory SavingsTransaction.fromJson(Map<String, dynamic> json) {
    return SavingsTransaction(
      id: json['id']?.toString() ?? json['ID']?.toString() ?? '',
      goalId: json['goal_id']?.toString() ?? '',
      walletId: json['wallet_id']?.toString() ?? '',
      amount: _parseDouble(json['amount'] ?? 0),
      type: json['type'] ?? 'DEPOSIT',
      note: json['note'],
      createdAt: _parseDateTimeNonNull(
        json['created_at'] ?? json['CreatedAt']
      ),
    );
  }

  static DateTime _parseDateTimeNonNull(dynamic value) {
    if (value == null) {
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day);
    }
    if (value is DateTime) {
      return DateTime(value.year, value.month, value.day);
    }
    
    try {
      String dateStr = value.toString().trim();
      
      // Loại bỏ timezone
      dateStr = dateStr.replaceAll(RegExp(r'[+-]\d{2}:\d{2}$'), '');
      dateStr = dateStr.replaceAll('Z', '');
      
      // Loại bỏ milliseconds
      if (dateStr.contains('.')) {
        dateStr = dateStr.split('.')[0];
      }
      
      final parsed = DateTime.parse(dateStr);
      return DateTime(parsed.year, parsed.month, parsed.day);
    } catch (e) {
      print('⚠️ Lỗi parse datetime: $value - $e');
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day);
    }
  }

  static double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
