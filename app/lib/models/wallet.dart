/// Model cho Wallet - Khớp với server Go (gorm.Model)
class Wallet {
  final String id; // ID từ BaseModel (UUID)
  final String name;
  final double balance;
  final String currency; // Loại tiền (VND)
  final String userId; // UserID (UUID)
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
      id: json['id']?.toString() ?? json['ID']?.toString() ?? '',
      name: json['name'] ?? '',
      balance: _parseDouble(json['balance'] ?? 0),
      currency: json['currency'] ?? 'VND',
      userId: json['user_id']?.toString() ?? json['UserID']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : (json['CreatedAt'] != null
                ? DateTime.parse(json['CreatedAt'])
                : DateTime.now()),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : (json['UpdatedAt'] != null
                ? DateTime.parse(json['UpdatedAt'])
                : null),
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
      'id': id,
      'name': name,
      'balance': balance,
      'currency': currency,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Copy với các giá trị mới
  Wallet copyWith({
    String? id,
    String? name,
    double? balance,
    String? currency,
    String? userId,
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
