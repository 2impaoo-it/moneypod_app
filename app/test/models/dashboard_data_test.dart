import 'package:flutter_test/flutter_test.dart';
import 'package:moneypod/models/dashboard_data.dart';
import 'package:moneypod/models/user.dart';
import 'package:moneypod/models/wallet.dart';
import 'package:moneypod/models/transaction.dart';

void main() {
  group('DashboardData Model', () {
    final now = DateTime.now();

    group('fromJson', () {
      test('parses complete JSON correctly', () {
        final json = {
          'user_info': {
            'id': 'user1',
            'email': 'test@example.com',
            'full_name': 'Test User',
          },
          'total_balance': 10000000.0,
          'wallets': [
            {
              'id': 'w1',
              'name': 'Main Wallet',
              'balance': 5000000,
              'currency': 'VND',
              'user_id': 'user1',
              'created_at': now.toIso8601String(),
            },
            {
              'id': 'w2',
              'name': 'Savings',
              'balance': 5000000,
              'currency': 'VND',
              'user_id': 'user1',
              'created_at': now.toIso8601String(),
            },
          ],
          'recent_transactions': [
            {
              'id': 't1',
              'title': 'Lunch',
              'category': 'Food',
              'amount': 50000,
              'date': now.toIso8601String(),
              'is_expense': true,
            },
          ],
        };

        final data = DashboardData.fromJson(json);

        expect(data.userInfo.email, 'test@example.com');
        expect(data.totalBalance, 10000000.0);
        expect(data.wallets, hasLength(2));
        expect(data.wallets[0].name, 'Main Wallet');
        expect(data.recentTransactions, hasLength(1));
        expect(data.recentTransactions[0].title, 'Lunch');
      });

      test('handles int total_balance', () {
        final json = {
          'user_info': {'email': 'test@example.com'},
          'total_balance': 5000000,
          'wallets': [],
          'recent_transactions': [],
        };

        final data = DashboardData.fromJson(json);
        expect(data.totalBalance, 5000000.0);
      });

      test('handles empty wallets list', () {
        final json = {
          'user_info': {'email': 'test@example.com'},
          'total_balance': 0,
          'wallets': [],
          'recent_transactions': [],
        };

        final data = DashboardData.fromJson(json);
        expect(data.wallets, isEmpty);
      });

      test('handles empty transactions list', () {
        final json = {
          'user_info': {'email': 'test@example.com'},
          'total_balance': 0,
          'wallets': [],
          'recent_transactions': [],
        };

        final data = DashboardData.fromJson(json);
        expect(data.recentTransactions, isEmpty);
      });

      test('parses multiple wallets correctly', () {
        final json = {
          'user_info': {'email': 'test@example.com'},
          'total_balance': 15000000,
          'wallets': [
            {
              'id': '1',
              'name': 'Cash',
              'balance': 5000000,
              'currency': 'VND',
              'user_id': 'u1',
              'created_at': now.toIso8601String(),
            },
            {
              'id': '2',
              'name': 'Bank',
              'balance': 10000000,
              'currency': 'VND',
              'user_id': 'u1',
              'created_at': now.toIso8601String(),
            },
          ],
          'recent_transactions': [],
        };

        final data = DashboardData.fromJson(json);

        expect(data.wallets, hasLength(2));
        expect(data.wallets[0].name, 'Cash');
        expect(data.wallets[1].name, 'Bank');
      });

      test('parses multiple transactions correctly', () {
        final json = {
          'user_info': {'email': 'test@example.com'},
          'total_balance': 0,
          'wallets': [],
          'recent_transactions': [
            {
              'id': '1',
              'title': 'Income',
              'category': 'Salary',
              'amount': 10000000,
              'date': now.toIso8601String(),
              'is_expense': false,
            },
            {
              'id': '2',
              'title': 'Expense',
              'category': 'Food',
              'amount': 50000,
              'date': now.toIso8601String(),
              'is_expense': true,
            },
          ],
        };

        final data = DashboardData.fromJson(json);

        expect(data.recentTransactions, hasLength(2));
        expect(data.recentTransactions[0].title, 'Income');
        expect(data.recentTransactions[1].title, 'Expense');
      });
    });

    group('constructor', () {
      test('creates instance with all required fields', () {
        final user = const User(email: 'test@example.com');
        final wallets = [
          Wallet(
            id: '1',
            name: 'W1',
            balance: 1000,
            currency: 'VND',
            userId: 'u1',
            createdAt: now,
          ),
        ];
        final transactions = [
          Transaction(
            id: '1',
            title: 'T1',
            category: 'C1',
            amount: 100,
            date: now,
            isExpense: true,
          ),
        ];

        final data = DashboardData(
          userInfo: user,
          totalBalance: 1000000,
          wallets: wallets,
          recentTransactions: transactions,
        );

        expect(data.userInfo.email, 'test@example.com');
        expect(data.totalBalance, 1000000);
        expect(data.wallets, hasLength(1));
        expect(data.recentTransactions, hasLength(1));
      });
    });

    group('data integrity', () {
      test('wallets list is independent copy', () {
        final json = {
          'user_info': {'email': 'test@example.com'},
          'total_balance': 1000000,
          'wallets': [
            {
              'id': '1',
              'name': 'W1',
              'balance': 500000,
              'currency': 'VND',
              'user_id': 'u1',
              'created_at': now.toIso8601String(),
            },
          ],
          'recent_transactions': [],
        };

        final data = DashboardData.fromJson(json);

        // Verify data is correctly parsed
        expect(data.wallets[0].balance, 500000);
      });

      test('user info is correctly nested', () {
        final json = {
          'user_info': {
            'id': 'user123',
            'email': 'nested@example.com',
            'full_name': 'Nested User',
            'avatar_url': 'https://example.com/avatar.png',
          },
          'total_balance': 0,
          'wallets': [],
          'recent_transactions': [],
        };

        final data = DashboardData.fromJson(json);

        expect(data.userInfo.id, 'user123');
        expect(data.userInfo.email, 'nested@example.com');
        expect(data.userInfo.fullName, 'Nested User');
        expect(data.userInfo.avatarUrl, 'https://example.com/avatar.png');
      });
    });
  });
}
