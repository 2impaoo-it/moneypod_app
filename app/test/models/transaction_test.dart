import 'package:flutter_test/flutter_test.dart';
import 'package:moneypod/models/transaction.dart';

void main() {
  group('Transaction Model', () {
    group('fromJson', () {
      test('parses complete data correctly', () {
        final json = {
          'id': '123',
          'title': 'Ăn sáng',
          'category': 'Ăn uống',
          'amount': 50000.0,
          'date': '2026-01-04T10:30:00.000Z',
          'is_expense': true,
          'hashtag': '#caphe',
          'wallet_id': 'wallet-1',
          'user': {
            'full_name': 'Nguyễn Văn A',
            'avatar_url': 'https://example.com/avatar.jpg',
          },
          'wallet': {'name': 'Ví tiền mặt'},
          'proof_image': 'https://example.com/proof.jpg',
        };

        final transaction = Transaction.fromJson(json);

        expect(transaction.id, '123');
        expect(transaction.title, 'Ăn sáng');
        expect(transaction.category, 'Ăn uống');
        expect(transaction.amount, 50000.0);
        expect(transaction.isExpense, true);
        expect(transaction.hashtag, '#caphe');
        expect(transaction.walletId, 'wallet-1');
        expect(transaction.walletName, 'Ví tiền mặt');
        expect(transaction.userName, 'Nguyễn Văn A');
        expect(transaction.userAvatar, 'https://example.com/avatar.jpg');
        expect(transaction.proofImage, 'https://example.com/proof.jpg');
      });

      test('handles missing optional fields', () {
        final json = {
          'id': '456',
          'note': 'Mua đồ',
          'category': 'Mua sắm',
          'amount': 200000,
          'date': '2026-01-04T14:00:00.000Z',
          'type': 'expense',
        };

        final transaction = Transaction.fromJson(json);

        expect(transaction.id, '456');
        expect(transaction.title, 'Mua đồ');
        expect(transaction.isExpense, true);
        expect(transaction.hashtag, 'Mua sắm'); // Falls back to category
        expect(transaction.walletId, isNull);
        expect(transaction.walletName, isNull);
        expect(transaction.userName, isNull);
        expect(transaction.proofImage, isNull);
      });

      test('handles GORM-style keys (ID, CreatedAt)', () {
        final json = {
          'ID': '789',
          'title': 'Lương tháng 1',
          'category': 'Lương',
          'amount': 15000000,
          'date': '2026-01-01T00:00:00.000Z',
          'is_expense': false,
        };

        final transaction = Transaction.fromJson(json);

        expect(transaction.id, '789');
        expect(transaction.isExpense, false);
      });

      test('parses amount from string', () {
        final json = {
          'id': '101',
          'title': 'Test',
          'category': 'Khác',
          'amount': '75000',
          'date': '2026-01-04T12:00:00.000Z',
          'is_expense': true,
        };

        final transaction = Transaction.fromJson(json);

        expect(transaction.amount, 75000.0);
      });

      test('handles null date with fallback to now', () {
        final json = {
          'id': '102',
          'title': 'No date',
          'category': 'Khác',
          'amount': 1000,
          'is_expense': true,
        };

        final transaction = Transaction.fromJson(json);

        expect(transaction.date, isA<DateTime>());
        expect(
          transaction.date.difference(DateTime.now()).inSeconds.abs(),
          lessThan(2),
        );
      });
    });

    group('toJson', () {
      test('serializes all fields correctly', () {
        final date = DateTime.parse('2026-01-04T10:30:00.000Z');
        final transaction = Transaction(
          id: '123',
          title: 'Test transaction',
          category: 'Ăn uống',
          amount: 50000,
          date: date,
          isExpense: true,
          hashtag: '#test',
          walletId: 'wallet-1',
          walletName: 'Ví chính',
          userName: 'User A',
          userAvatar: 'avatar.jpg',
          proofImage: 'proof.jpg',
        );

        final json = transaction.toJson();

        expect(json['id'], '123');
        expect(json['title'], 'Test transaction');
        expect(json['category'], 'Ăn uống');
        expect(json['amount'], 50000);
        expect(json['date'], date.toIso8601String());
        expect(json['is_expense'], true);
        expect(json['hashtag'], '#test');
        expect(json['wallet_id'], 'wallet-1');
        expect(json['wallet_name'], 'Ví chính');
        expect(json['user_name'], 'User A');
        expect(json['user_avatar'], 'avatar.jpg');
        expect(json['proof_image'], 'proof.jpg');
      });
    });

    group('copyWith', () {
      test('creates modified copy with new amount', () {
        final original = Transaction(
          id: '1',
          title: 'Original',
          category: 'Ăn uống',
          amount: 100,
          date: DateTime.now(),
          isExpense: true,
        );

        final modified = original.copyWith(amount: 200);

        expect(modified.amount, 200);
        expect(modified.id, '1');
        expect(modified.title, 'Original');
        expect(modified.category, 'Ăn uống');
      });

      test('preserves all fields when no changes', () {
        final original = Transaction(
          id: '1',
          title: 'Test',
          category: 'Mua sắm',
          amount: 500,
          date: DateTime(2026, 1, 4),
          isExpense: false,
          hashtag: '#shopping',
        );

        final copy = original.copyWith();

        expect(copy, equals(original));
      });
    });

    group('type getter', () {
      test('returns expense for isExpense=true', () {
        final transaction = Transaction(
          id: '1',
          title: 'Chi tiêu',
          category: 'Ăn uống',
          amount: 100,
          date: DateTime.now(),
          isExpense: true,
        );

        expect(transaction.type, 'expense');
      });

      test('returns income for isExpense=false', () {
        final transaction = Transaction(
          id: '2',
          title: 'Thu nhập',
          category: 'Lương',
          amount: 1000000,
          date: DateTime.now(),
          isExpense: false,
        );

        expect(transaction.type, 'income');
      });
    });

    group('Equatable', () {
      test('two transactions with same props are equal', () {
        final date = DateTime(2026, 1, 4);
        final t1 = Transaction(
          id: '1',
          title: 'Test',
          category: 'Ăn uống',
          amount: 100,
          date: date,
          isExpense: true,
        );
        final t2 = Transaction(
          id: '1',
          title: 'Test',
          category: 'Ăn uống',
          amount: 100,
          date: date,
          isExpense: true,
        );

        expect(t1, equals(t2));
        expect(t1.hashCode, equals(t2.hashCode));
      });

      test('two transactions with different id are not equal', () {
        final date = DateTime(2026, 1, 4);
        final t1 = Transaction(
          id: '1',
          title: 'Test',
          category: 'Ăn uống',
          amount: 100,
          date: date,
          isExpense: true,
        );
        final t2 = Transaction(
          id: '2',
          title: 'Test',
          category: 'Ăn uống',
          amount: 100,
          date: date,
          isExpense: true,
        );

        expect(t1, isNot(equals(t2)));
      });
    });
  });
}
