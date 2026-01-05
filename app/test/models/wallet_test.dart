import 'package:flutter_test/flutter_test.dart';
import 'package:moneypod/models/wallet.dart';

void main() {
  group('Wallet Model', () {
    final now = DateTime.now();
    final updatedAt = now.add(const Duration(hours: 1));

    group('fromJson', () {
      test('parses complete JSON correctly', () {
        final json = {
          'id': '123',
          'name': 'Main Wallet',
          'balance': 1000000.50,
          'currency': 'VND',
          'user_id': 'user123',
          'created_at': now.toIso8601String(),
          'updated_at': updatedAt.toIso8601String(),
        };

        final wallet = Wallet.fromJson(json);

        expect(wallet.id, '123');
        expect(wallet.name, 'Main Wallet');
        expect(wallet.balance, 1000000.50);
        expect(wallet.currency, 'VND');
        expect(wallet.userId, 'user123');
        expect(wallet.createdAt.year, now.year);
        expect(wallet.updatedAt?.year, updatedAt.year);
      });

      test('handles uppercase keys (Go backend format)', () {
        final json = {
          'ID': 456,
          'name': 'Wallet',
          'balance': 500,
          'UserID': 'user789',
          'CreatedAt': now.toIso8601String(),
          'UpdatedAt': updatedAt.toIso8601String(),
        };

        final wallet = Wallet.fromJson(json);

        expect(wallet.id, '456');
        expect(wallet.userId, 'user789');
      });

      test('handles missing optional fields', () {
        final json = {
          'id': '1',
          'name': 'Wallet',
          'balance': 0,
          'user_id': 'user1',
        };

        final wallet = Wallet.fromJson(json);

        expect(wallet.currency, 'VND'); // default
        expect(wallet.updatedAt, isNull);
      });

      test('parses balance from String', () {
        final json = {
          'id': '1',
          'name': 'Wallet',
          'balance': '123456.78',
          'user_id': 'user1',
          'created_at': now.toIso8601String(),
        };

        final wallet = Wallet.fromJson(json);
        expect(wallet.balance, 123456.78);
      });

      test('parses balance from int', () {
        final json = {
          'id': '1',
          'name': 'Wallet',
          'balance': 500000,
          'user_id': 'user1',
          'created_at': now.toIso8601String(),
        };

        final wallet = Wallet.fromJson(json);
        expect(wallet.balance, 500000.0);
      });

      test('handles null balance', () {
        final json = {
          'id': '1',
          'name': 'Wallet',
          'balance': null,
          'user_id': 'user1',
          'created_at': now.toIso8601String(),
        };

        final wallet = Wallet.fromJson(json);
        expect(wallet.balance, 0.0);
      });

      test('handles invalid balance string', () {
        final json = {
          'id': '1',
          'name': 'Wallet',
          'balance': 'invalid',
          'user_id': 'user1',
          'created_at': now.toIso8601String(),
        };

        final wallet = Wallet.fromJson(json);
        expect(wallet.balance, 0.0);
      });
    });

    group('toJson', () {
      test('serializes all fields correctly', () {
        final wallet = Wallet(
          id: '123',
          name: 'Savings',
          balance: 5000000,
          currency: 'VND',
          userId: 'user1',
          createdAt: now,
          updatedAt: updatedAt,
        );

        final json = wallet.toJson();

        expect(json['id'], '123');
        expect(json['name'], 'Savings');
        expect(json['balance'], 5000000);
        expect(json['currency'], 'VND');
        expect(json['user_id'], 'user1');
        expect(json['created_at'], now.toIso8601String());
        expect(json['updated_at'], updatedAt.toIso8601String());
      });

      test('handles null updatedAt', () {
        final wallet = Wallet(
          id: '1',
          name: 'Wallet',
          balance: 0,
          currency: 'VND',
          userId: 'user1',
          createdAt: now,
        );

        final json = wallet.toJson();
        expect(json['updated_at'], isNull);
      });
    });

    group('copyWith', () {
      test('copies all fields when provided', () {
        final original = Wallet(
          id: '1',
          name: 'Old',
          balance: 100,
          currency: 'VND',
          userId: 'user1',
          createdAt: now,
        );

        final copied = original.copyWith(
          name: 'New',
          balance: 200,
          currency: 'USD',
        );

        expect(copied.id, '1'); // unchanged
        expect(copied.name, 'New');
        expect(copied.balance, 200);
        expect(copied.currency, 'USD');
        expect(copied.userId, 'user1'); // unchanged
      });

      test('preserves original values when not provided', () {
        final original = Wallet(
          id: '1',
          name: 'Wallet',
          balance: 1000,
          currency: 'VND',
          userId: 'user1',
          createdAt: now,
          updatedAt: updatedAt,
        );

        final copied = original.copyWith(name: 'New Name');

        expect(copied.id, '1');
        expect(copied.name, 'New Name');
        expect(copied.balance, 1000);
        expect(copied.currency, 'VND');
        expect(copied.updatedAt, updatedAt);
      });
    });

    group('_parseDouble helper', () {
      // Testing through fromJson since _parseDouble is private
      test('handles various numeric types', () {
        // double
        expect(
          Wallet.fromJson({
            'id': '1',
            'name': 'W',
            'balance': 100.5,
            'user_id': 'u',
            'created_at': now.toIso8601String(),
          }).balance,
          100.5,
        );

        // int
        expect(
          Wallet.fromJson({
            'id': '1',
            'name': 'W',
            'balance': 100,
            'user_id': 'u',
            'created_at': now.toIso8601String(),
          }).balance,
          100.0,
        );

        // String
        expect(
          Wallet.fromJson({
            'id': '1',
            'name': 'W',
            'balance': '200.75',
            'user_id': 'u',
            'created_at': now.toIso8601String(),
          }).balance,
          200.75,
        );
      });
    });

    group('roundtrip', () {
      test('fromJson -> toJson preserves data', () {
        final originalJson = {
          'id': '123',
          'name': 'Test Wallet',
          'balance': 1500000.0,
          'currency': 'VND',
          'user_id': 'user123',
          'created_at': now.toIso8601String(),
          'updated_at': updatedAt.toIso8601String(),
        };

        final wallet = Wallet.fromJson(originalJson);
        final resultJson = wallet.toJson();

        expect(resultJson['id'], originalJson['id']);
        expect(resultJson['name'], originalJson['name']);
        expect(resultJson['balance'], originalJson['balance']);
        expect(resultJson['currency'], originalJson['currency']);
        expect(resultJson['user_id'], originalJson['user_id']);
      });
    });
  });
}
