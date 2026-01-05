class Budget {
  final String id;
  final String category;
  final double amount;
  final double spent; // Current spending in this category
  final int month;
  final int year;

  Budget({
    required this.id,
    required this.category,
    required this.amount,
    this.spent = 0,
    required this.month,
    required this.year,
  });

  // Calculate remaining
  double get remaining => amount - spent;

  // Calculate percentage
  double get progress => (spent / amount).clamp(0.0, 1.0);

  Budget copyWith({
    String? id,
    String? category,
    double? amount,
    double? spent,
    int? month,
    int? year,
  }) {
    return Budget(
      id: id ?? this.id,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      spent: spent ?? this.spent,
      month: month ?? this.month,
      year: year ?? this.year,
    );
  }

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'] as String,
      category: json['category'] as String,
      amount: (json['amount'] as num).toDouble(),
      spent: (json['spent'] as num?)?.toDouble() ?? 0.0,
      month: json['month'] as int,
      year: json['year'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'amount': amount,
      'spent': spent,
      'month': month,
      'year': year,
    };
  }
}
