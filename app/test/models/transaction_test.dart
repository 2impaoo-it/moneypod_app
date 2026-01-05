import 'package:flutter_test/flutter_test.dart';
import 'package:moneypod/models/transaction.dart';

void main() {
  group('Transaction Model', () {
    final now = DateTime.now();

    group('fromJson', () {
      test('parses complete JSON correctly', () {
        final json = {
          'id': '123',
          'title': 'Lunch',
          'category': 'Ăn uống',
          'amount': 50000.0,
          'date': now.toIso8601String(),
          'is_expense': true,
          'hashtag': '#food',
          'wallet_id': 'wallet1',
          'proof_image': 'https://example.com/proof.jpg',
        };

        final tx = Transaction.fromJson(json);

        expect(tx.id, '123');
        expect(tx.title, 'Lunch');
        expect(tx.category, 'Ăn uống');
        expect(tx.amount, 50000.0);
        expect(tx.isExpense, true);
        expect(tx.hashtag, '#food');
        expect(tx.walletId, 'wallet1');
        expect(tx.proofImage, 'https://example.com/proof.jpg');
      });

      test('handles uppercase ID key', () {
        final json = {
          'ID': 456,
          'title': 'Test',
          'category': 'Other',
          'amount': 100,
          'date': now.toIso8601String(),
          'is_expense': false,
        };

        final tx = Transaction.fromJson(json);
        expect(tx.id, '456');
      });

      test('handles note field as title alternative', () {
        final json = {
          'id': '1',
          'note': 'This is a note',
          'category': 'Other',
          'amount': 100,
          'date': now.toIso8601String(),
          'is_expense': true,
        };

        final tx = Transaction.fromJson(json);
        expect(tx.title, 'This is a note');
      });

      test('handles type field for expense detection', () {
        final json = {
          'id': '1',
          'title': 'Test',
          'category': 'Other',
          'amount': 100,
          'date': now.toIso8601String(),
          'type': 'expense',
        };

        final tx = Transaction.fromJson(json);
        expect(tx.isExpense, true);
      });

      test('parses amount from String', () {
        final json = {
          'id': '1',
          'title': 'Test',
          'category': 'Other',
          'amount': '123456.78',
          'date': now.toIso8601String(),
          'is_expense': true,
        };

        final tx = Transaction.fromJson(json);
        expect(tx.amount, 123456.78);
      });

      test('parses amount from int', () {
        final json = {
          'id': '1',
          'title': 'Test',
          'category': 'Other',
          'amount': 500000,
          'date': now.toIso8601String(),
          'is_expense': false,
        };

        final tx = Transaction.fromJson(json);
        expect(tx.amount, 500000.0);
      });

      test('handles null/invalid amount', () {
        final json = {
          'id': '1',
          'title': 'Test',
          'category': 'Other',
          'amount': 'invalid',
          'date': now.toIso8601String(),
          'is_expense': true,
        };

        final tx = Transaction.fromJson(json);
        expect(tx.amount, 0.0);
      });

      test('handles nested user object', () {
        final json = {
          'id': '1',
          'title': 'Test',
          'category': 'Other',
          'amount': 100,
          'date': now.toIso8601String(),
          'is_expense': true,
          'user': {
            'full_name': 'Test User',
            'avatar_url': 'https://example.com/avatar.png',
          },
        };

        final tx = Transaction.fromJson(json);
        expect(tx.userName, 'Test User');
        expect(tx.userAvatar, 'https://example.com/avatar.png');
      });

      test('handles nested wallet object', () {
        final json = {
          'id': '1',
          'title': 'Test',
          'category': 'Other',
          'amount': 100,
          'date': now.toIso8601String(),
          'is_expense': true,
          'wallet': {'name': 'Main Wallet'},
        };

        final tx = Transaction.fromJson(json);
        expect(tx.walletName, 'Main Wallet');
      });

      test('handles missing date (defaults to now)', () {
        final json = {
          'id': '1',
          'title': 'Test',
          'category': 'Other',
          'amount': 100,
          'is_expense': true,
        };

        final tx = Transaction.fromJson(json);
        expect(tx.date.year, DateTime.now().year);
      });

      test('uses category as hashtag fallback', () {
        final json = {
          'id': '1',
          'title': 'Test',
          'category': 'Shopping',
          'amount': 100,
          'date': now.toIso8601String(),
          'is_expense': true,
        };

        final tx = Transaction.fromJson(json);
        expect(tx.hashtag, 'Shopping');
      });
    });

    group('toJson', () {
      test('serializes all fields correctly', () {
        final tx = Transaction(
          id: '123',
          title: 'Salary',
          category: 'Lương',
          amount: 10000000,
          date: now,
          isExpense: false,
          hashtag: '#salary',
          walletId: 'wallet1',
          walletName: 'Main',
          userName: 'User',
          userAvatar: 'url',
          proofImage: 'proof_url',
        );

        final json = tx.toJson();

        expect(json['id'], '123');
        expect(json['title'], 'Salary');
        expect(json['category'], 'Lương');
        expect(json['amount'], 10000000);
        expect(json['is_expense'], false);
        expect(json['hashtag'], '#salary');
        expect(json['wallet_id'], 'wallet1');
        expect(json['wallet_name'], 'Main');
        expect(json['user_name'], 'User');
        expect(json['user_avatar'], 'url');
        expect(json['proof_image'], 'proof_url');
      });

      test('handles null optional fields', () {
        final tx = Transaction(
          id: '1',
          title: 'Test',
          category: 'Other',
          amount: 100,
          date: now,
          isExpense: true,
        );

        final json = tx.toJson();
        expect(json['hashtag'], isNull);
        expect(json['wallet_id'], isNull);
        expect(json['proof_image'], isNull);
      });
    });

    group('copyWith', () {
      test('copies all fields when provided', () {
        final original = Transaction(
          id: '1',
          title: 'Old',
          category: 'Old Cat',
          amount: 100,
          date: now,
          isExpense: true,
        );

        final copied = original.copyWith(
          title: 'New',
          category: 'New Cat',
          amount: 200,
          isExpense: false,
        );

        expect(copied.id, '1'); // unchanged
        expect(copied.title, 'New');
        expect(copied.category, 'New Cat');
        expect(copied.amount, 200);
        expect(copied.isExpense, false);
      });

      test('preserves original values when not provided', () {
        final original = Transaction(
          id: '1',
          title: 'Test',
          category: 'Cat',
          amount: 1000,
          date: now,
          isExpense: true,
          proofImage: 'proof.jpg',
        );

        final copied = original.copyWith(title: 'New Title');

        expect(copied.id, '1');
        expect(copied.title, 'New Title');
        expect(copied.category, 'Cat');
        expect(copied.amount, 1000);
        expect(copied.proofImage, 'proof.jpg');
      });
    });

    group('type getter', () {
      test('returns expense for isExpense=true', () {
        final tx = Transaction(
          id: '1',
          title: 'T',
          category: 'C',
          amount: 100,
          date: DateTime.now(),
          isExpense: true,
        );
        expect(tx.type, 'expense');
      });

      test('returns income for isExpense=false', () {
        final tx = Transaction(
          id: '1',
          title: 'T',
          category: 'C',
          amount: 100,
          date: now,
          isExpense: false,
        );
        expect(tx.type, 'income');
      });
    });

    group('Equatable', () {
      test('two transactions with same props are equal', () {
        final tx1 = Transaction(
          id: '1',
          title: 'Test',
          category: 'Cat',
          amount: 100,
          date: now,
          isExpense: true,
        );
        final tx2 = Transaction(
          id: '1',
          title: 'Test',
          category: 'Cat',
          amount: 100,
          date: now,
          isExpense: true,
        );

        expect(tx1, equals(tx2));
        expect(tx1.hashCode, equals(tx2.hashCode));
      });

      test('two transactions with different props are not equal', () {
        final tx1 = Transaction(
          id: '1',
          title: 'Test',
          category: 'Cat',
          amount: 100,
          date: now,
          isExpense: true,
        );
        final tx2 = Transaction(
          id: '2',
          title: 'Test',
          category: 'Cat',
          amount: 100,
          date: now,
          isExpense: true,
        );

        expect(tx1, isNot(equals(tx2)));
      });

      test('props contains all fields', () {
        final tx = Transaction(
          id: '1',
          title: 'Test',
          category: 'Cat',
          amount: 100,
          date: now,
          isExpense: true,
          hashtag: '#tag',
          walletId: 'w1',
          walletName: 'Wallet',
          userName: 'User',
          userAvatar: 'avatar',
          proofImage: 'proof',
        );

        expect(tx.props, hasLength(12));
      });
    });

    group('roundtrip', () {
      test('fromJson -> toJson preserves core data', () {
        final originalJson = {
          'id': '123',
          'title': 'Lunch',
          'category': 'Food',
          'amount': 50000.0,
          'date': now.toIso8601String(),
          'is_expense': true,
          'hashtag': '#food',
          'wallet_id': 'wallet1',
        };

        final tx = Transaction.fromJson(originalJson);
        final resultJson = tx.toJson();

        expect(resultJson['id'], originalJson['id']);
        expect(resultJson['title'], originalJson['title']);
        expect(resultJson['category'], originalJson['category']);
        expect(resultJson['amount'], originalJson['amount']);
        expect(resultJson['is_expense'], originalJson['is_expense']);
      });
    });
  });
}
