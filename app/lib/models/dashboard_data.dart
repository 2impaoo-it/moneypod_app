import 'user.dart';
import 'wallet.dart';
import 'transaction.dart';

/// Model cho dữ liệu dashboard từ API /api/v1/dashboard
class DashboardData {
  final User userInfo;
  final double totalBalance;
  final List<Wallet> wallets;
  final List<Transaction> recentTransactions;

  DashboardData({
    required this.userInfo,
    required this.totalBalance,
    required this.wallets,
    required this.recentTransactions,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      userInfo: User.fromJson(json['user_info']),
      totalBalance: (json['total_balance'] as num).toDouble(),
      wallets: (json['wallets'] as List)
          .map((w) => Wallet.fromJson(w))
          .toList(),
      recentTransactions: (json['recent_transactions'] as List)
          .map((t) => Transaction.fromJson(t))
          .toList(),
    );
  }
}
