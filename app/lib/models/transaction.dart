import 'package:equatable/equatable.dart';

class Transaction extends Equatable {
  final String id;
  final String title;
  final String category;
  final double amount;
  final DateTime date;
  final bool isExpense;
  final String? hashtag;
  final String? walletId;
  final String? walletName; // Tên ví
  final String? userName; // Tên người dùng
  final String? userAvatar; // Avatar URL
  final String? proofImage; // Hình ảnh minh chứng

  const Transaction({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    required this.isExpense,
    this.hashtag,
    this.walletId,
    this.walletName,
    this.userName,
    this.userAvatar,
    this.proofImage,
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
    walletId,
    walletName,
    userName,
    userAvatar,
    proofImage,
  ];

  Transaction copyWith({
    String? id,
    String? title,
    String? category,
    double? amount,
    DateTime? date,
    bool? isExpense,
    String? hashtag,
    String? walletId,
    String? walletName,
    String? userName,
    String? userAvatar,
    String? proofImage,
  }) {
    return Transaction(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      isExpense: isExpense ?? this.isExpense,
      hashtag: hashtag ?? this.hashtag,
      walletId: walletId ?? this.walletId,
      walletName: walletName ?? this.walletName,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      proofImage: proofImage ?? this.proofImage,
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
      'wallet_id': walletId,
      'wallet_name': walletName,
      'user_name': userName,
      'user_avatar': userAvatar,
      'proof_image': proofImage,
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    // Support both backend and local keys
    // Parse user info from nested 'user' object
    final userObj = json['user'] as Map<String, dynamic>?;
    final walletObj = json['wallet'] as Map<String, dynamic>?;

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
      walletId: json['wallet_id']?.toString(),
      walletName: walletObj?['name'] as String?,
      userName: userObj?['full_name'] as String?,
      userAvatar: userObj?['avatar_url'] as String?,
      proofImage: json['proof_image'] as String?,
    );
  }
}
