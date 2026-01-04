import 'package:flutter_test/flutter_test.dart';
import 'package:moneypod/models/user.dart';
import 'package:moneypod/models/wallet.dart';
import 'package:moneypod/models/transaction.dart';
import 'package:moneypod/models/dashboard_data.dart';

void main() {
  group('DashboardData Model Test', () {
    test('fromJson parses correctly', () {
      final json = {
        'user_info': {
          'id': 'user1',
          'email': 'test@test.com',
          'full_name': 'Test User',
        },
        'total_balance': 1500000,
        'wallets': [
          {'id': 'w1', 'name': 'Cash', 'balance': 500000, 'type': 'cash'},
        ],
        'recent_transactions': [
          {
            'id': 't1',
            'amount': 50000,
            'category': 'Food',
            'date': '2023-10-27T10:00:00Z',
            'type': 'expense',
          },
        ],
      };

      final data = DashboardData.fromJson(json);

      expect(data.userInfo, isA<User>());
      expect(data.userInfo.id, 'user1');
      expect(data.totalBalance, 1500000.0);
      expect(data.wallets.length, 1);
      expect(data.wallets.first, isA<Wallet>());
      expect(data.recentTransactions.length, 1);
      expect(data.recentTransactions.first, isA<Transaction>());
    });
  });
}
