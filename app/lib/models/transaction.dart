import 'package:equatable/equatable.dart';

class Transaction extends Equatable {
  final String id;
  final String title;
  final String category;
  final double amount;
  final DateTime date;
  final bool isExpense;
  final String? hashtag;

  const Transaction({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    required this.isExpense,
    this.hashtag,
  });

  @override
  List<Object?> get props => [
    id,
    title,
    category,
    amount,
    date,
    isExpense,
    hashtag,
  ];

  Transaction copyWith({
    String? id,
    String? title,
    String? category,
    double? amount,
    DateTime? date,
    bool? isExpense,
    String? hashtag,
  }) {
    return Transaction(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      isExpense: isExpense ?? this.isExpense,
      hashtag: hashtag ?? this.hashtag,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'amount': amount,
      'date': date.toIso8601String(),
      'is_expense': isExpense,
      'hashtag': hashtag,
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    // Support both backend and local keys
    return Transaction(
      id: json['id']?.toString() ?? json['ID']?.toString() ?? '',
      title: json['title'] ?? json['note'] ?? '',
      category: json['category'] ?? '',
      amount: (json['amount'] is num)
          ? (json['amount'] as num).toDouble()
          : double.tryParse(json['amount']?.toString() ?? '') ?? 0.0,
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      isExpense: json['is_expense'] ?? json['type'] == 'expense',
      hashtag: json['hashtag'] ?? json['category'],
    );
  }
}
