class Group {
  final int id;
  final String name;
  final String code;
  final int creatorId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<GroupMember>? members;

  Group({
    required this.id,
    required this.name,
    required this.code,
    required this.creatorId,
    required this.createdAt,
    required this.updatedAt,
    this.members,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: _parseInt(json['ID'] ?? json['id']),
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      creatorId: _parseInt(json['creator_id']),
      createdAt: json['CreatedAt'] != null
          ? DateTime.parse(json['CreatedAt'])
          : DateTime.now(),
      updatedAt: json['UpdatedAt'] != null
          ? DateTime.parse(json['UpdatedAt'])
          : DateTime.now(),
      members: json['members'] != null
          ? (json['members'] as List)
              .map((m) => GroupMember.fromJson(m))
              .toList()
          : null,
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'creator_id': creatorId,
      'CreatedAt': createdAt.toIso8601String(),
      'UpdatedAt': updatedAt.toIso8601String(),
      if (members != null)
        'members': members!.map((m) => m.toJson()).toList(),
    };
  }
}

class GroupMember {
  final int id;
  final int groupId;
  final int userId;
  final String role; // 'admin' or 'member'
  final double balance;
  final DateTime createdAt;
  final DateTime updatedAt;
  final User? user;

  GroupMember({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.role,
    required this.balance,
    required this.createdAt,
    required this.updatedAt,
    this.user,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      id: _parseInt(json['ID'] ?? json['id']),
      groupId: _parseInt(json['group_id']),
      userId: _parseInt(json['user_id']),
      role: json['role']?.toString() ?? 'member',
      balance: _parseDouble(json['balance']),
      createdAt: json['CreatedAt'] != null
          ? DateTime.parse(json['CreatedAt'])
          : DateTime.now(),
      updatedAt: json['UpdatedAt'] != null
          ? DateTime.parse(json['UpdatedAt'])
          : DateTime.now(),
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'user_id': userId,
      'role': role,
      'balance': balance,
      'CreatedAt': createdAt.toIso8601String(),
      'UpdatedAt': updatedAt.toIso8601String(),
      if (user != null) 'user': user!.toJson(),
    };
  }

  bool get isAdmin => role == 'admin';
}

class User {
  final int id;
  final String email;
  final String fullName;

  User({
    required this.id,
    required this.email,
    required this.fullName,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: _parseInt(json['ID'] ?? json['id']),
      email: json['email']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
    };
  }
}

class GroupExpense {
  final int id;
  final int groupId;
  final int paidById;
  final double amount;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final User? paidBy;
  final List<ExpenseSplit>? splits;

  GroupExpense({
    required this.id,
    required this.groupId,
    required this.paidById,
    required this.amount,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
    this.paidBy,
    this.splits,
  });

  factory GroupExpense.fromJson(Map<String, dynamic> json) {
    return GroupExpense(
      id: _parseInt(json['ID'] ?? json['id']),
      groupId: _parseInt(json['group_id']),
      paidById: _parseInt(json['paid_by_id']),
      amount: _parseDouble(json['amount']),
      note: json['note']?.toString() ?? '',
      createdAt: json['CreatedAt'] != null
          ? DateTime.parse(json['CreatedAt'])
          : DateTime.now(),
      updatedAt: json['UpdatedAt'] != null
          ? DateTime.parse(json['UpdatedAt'])
          : DateTime.now(),
      paidBy: json['paid_by'] != null ? User.fromJson(json['paid_by']) : null,
      splits: json['splits'] != null
          ? (json['splits'] as List)
              .map((s) => ExpenseSplit.fromJson(s))
              .toList()
          : null,
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'paid_by_id': paidById,
      'amount': amount,
      'note': note,
      'CreatedAt': createdAt.toIso8601String(),
      'UpdatedAt': updatedAt.toIso8601String(),
      if (paidBy != null) 'paid_by': paidBy!.toJson(),
      if (splits != null) 'splits': splits!.map((s) => s.toJson()).toList(),
    };
  }
}

class ExpenseSplit {
  final int id;
  final int groupExpenseId;
  final int userId;
  final double amount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final User? user;

  ExpenseSplit({
    required this.id,
    required this.groupExpenseId,
    required this.userId,
    required this.amount,
    required this.createdAt,
    required this.updatedAt,
    this.user,
  });

  factory ExpenseSplit.fromJson(Map<String, dynamic> json) {
    return ExpenseSplit(
      id: _parseInt(json['ID'] ?? json['id']),
      groupExpenseId: _parseInt(json['group_expense_id']),
      userId: _parseInt(json['user_id']),
      amount: _parseDouble(json['amount']),
      createdAt: json['CreatedAt'] != null
          ? DateTime.parse(json['CreatedAt'])
          : DateTime.now(),
      updatedAt: json['UpdatedAt'] != null
          ? DateTime.parse(json['UpdatedAt'])
          : DateTime.now(),
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_expense_id': groupExpenseId,
      'user_id': userId,
      'amount': amount,
      'CreatedAt': createdAt.toIso8601String(),
      'UpdatedAt': updatedAt.toIso8601String(),
      if (user != null) 'user': user!.toJson(),
    };
  }
}
