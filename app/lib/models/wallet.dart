/// Model cho Wallet - Khớp với server Go (gorm.Model)
class Wallet {
  final int id; // ID từ gorm.Model (uint)
  final String name;
  final double balance;
  final String currency; // Loại tiền (VND)
  final int userId; // UserID (uint)
  final DateTime createdAt; // CreatedAt từ gorm.Model
  final DateTime? updatedAt; // UpdatedAt từ gorm.Model

  Wallet({
    required this.id,
    required this.name,
    required this.balance,
    required this.currency,
    required this.userId,
    required this.createdAt,
    this.updatedAt,
  });

  /// Tạo Wallet từ JSON (từ server Go)
  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: _parseInt(json['ID'] ?? json['id'] ?? 0),
      name: json['name'] ?? '',
      balance: _parseDouble(json['balance'] ?? 0),
      currency: json['currency'] ?? 'VND',
      userId: _parseInt(json['user_id'] ?? json['UserID'] ?? 0),
      createdAt: json['CreatedAt'] != null
          ? DateTime.parse(json['CreatedAt'])
          : DateTime.now(),
      updatedAt: json['UpdatedAt'] != null
          ? DateTime.parse(json['UpdatedAt'])
          : null,
    );
  }

  /// Helper: Parse int từ dynamic (xử lý cả String và num)
  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }

  /// Helper: Parse double từ dynamic (xử lý cả String và num)
  static double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Chuyển Wallet thành JSON
  Map<String, dynamic> toJson() {
    return {
      'ID': id,
      'name': name,
      'balance': balance,
      'currency': currency,
      'user_id': userId,
      'CreatedAt': createdAt.toIso8601String(),
      'UpdatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Copy với các giá trị mới
  Wallet copyWith({
    int? id,
    String? name,
    double? balance,
    String? currency,
    int? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Wallet(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
