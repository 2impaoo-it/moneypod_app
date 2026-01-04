import 'package:flutter_test/flutter_test.dart';
import 'package:moneypod/models/wallet.dart';

void main() {
  group('Wallet Model', () {
    group('fromJson', () {
      test('parses complete data correctly', () {
        final json = {
          'id': 'wallet-123',
          'name': 'Ví tiền mặt',
          'balance': 5000000.0,
          'currency': 'VND',
          'user_id': 'user-456',
          'created_at': '2026-01-01T00:00:00.000Z',
          'updated_at': '2026-01-04T10:00:00.000Z',
        };

        final wallet = Wallet.fromJson(json);

        expect(wallet.id, 'wallet-123');
        expect(wallet.name, 'Ví tiền mặt');
        expect(wallet.balance, 5000000.0);
        expect(wallet.currency, 'VND');
        expect(wallet.userId, 'user-456');
        expect(wallet.createdAt, DateTime.parse('2026-01-01T00:00:00.000Z'));
        expect(wallet.updatedAt, DateTime.parse('2026-01-04T10:00:00.000Z'));
      });

      test('handles GORM-style keys (ID, UserID, CreatedAt)', () {
        final json = {
          'ID': 'gorm-wallet-1',
          'name': 'GORM Wallet',
          'balance': 1000000,
          'currency': 'VND',
          'UserID': 'gorm-user-1',
          'CreatedAt': '2026-01-02T00:00:00.000Z',
          'UpdatedAt': '2026-01-03T00:00:00.000Z',
        };

        final wallet = Wallet.fromJson(json);

        expect(wallet.id, 'gorm-wallet-1');
        expect(wallet.userId, 'gorm-user-1');
        expect(wallet.createdAt, DateTime.parse('2026-01-02T00:00:00.000Z'));
        expect(wallet.updatedAt, DateTime.parse('2026-01-03T00:00:00.000Z'));
      });

      test('handles missing optional updatedAt', () {
        final json = {
          'id': 'wallet-no-update',
          'name': 'New Wallet',
          'balance': 0,
          'currency': 'VND',
          'user_id': 'user-1',
          'created_at': '2026-01-04T00:00:00.000Z',
        };

        final wallet = Wallet.fromJson(json);

        expect(wallet.updatedAt, isNull);
      });

      test('defaults currency to VND when missing', () {
        final json = {
          'id': 'wallet-1',
          'name': 'Test',
          'balance': 100,
          'user_id': 'user-1',
          'created_at': '2026-01-04T00:00:00.000Z',
        };

        final wallet = Wallet.fromJson(json);

        expect(wallet.currency, 'VND');
      });
    });

    group('_parseDouble', () {
      test('parses double correctly', () {
        final json = {
          'id': '1',
          'name': 'Test',
          'balance': 1500000.50,
          'user_id': 'u1',
          'created_at': '2026-01-04T00:00:00.000Z',
        };

        final wallet = Wallet.fromJson(json);
        expect(wallet.balance, 1500000.50);
      });

      test('parses int correctly', () {
        final json = {
          'id': '1',
          'name': 'Test',
          'balance': 2000000,
          'user_id': 'u1',
          'created_at': '2026-01-04T00:00:00.000Z',
        };

        final wallet = Wallet.fromJson(json);
        expect(wallet.balance, 2000000.0);
      });

      test('parses String correctly', () {
        final json = {
          'id': '1',
          'name': 'Test',
          'balance': '3500000',
          'user_id': 'u1',
          'created_at': '2026-01-04T00:00:00.000Z',
        };

        final wallet = Wallet.fromJson(json);
        expect(wallet.balance, 3500000.0);
      });

      test('returns 0 for invalid String', () {
        final json = {
          'id': '1',
          'name': 'Test',
          'balance': 'invalid',
          'user_id': 'u1',
          'created_at': '2026-01-04T00:00:00.000Z',
        };

        final wallet = Wallet.fromJson(json);
        expect(wallet.balance, 0.0);
      });
    });

    group('toJson', () {
      test('serializes all fields correctly', () {
        final createdAt = DateTime.parse('2026-01-01T00:00:00.000Z');
        final updatedAt = DateTime.parse('2026-01-04T10:00:00.000Z');
        final wallet = Wallet(
          id: 'w1',
          name: 'Main Wallet',
          balance: 10000000,
          currency: 'VND',
          userId: 'u1',
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

        final json = wallet.toJson();

        expect(json['id'], 'w1');
        expect(json['name'], 'Main Wallet');
        expect(json['balance'], 10000000);
        expect(json['currency'], 'VND');
        expect(json['user_id'], 'u1');
        expect(json['created_at'], createdAt.toIso8601String());
        expect(json['updated_at'], updatedAt.toIso8601String());
      });

      test('handles null updatedAt', () {
        final wallet = Wallet(
          id: 'w1',
          name: 'New Wallet',
          balance: 0,
          currency: 'VND',
          userId: 'u1',
          createdAt: DateTime.now(),
          updatedAt: null,
        );

        final json = wallet.toJson();

        expect(json['updated_at'], isNull);
      });
    });

    group('copyWith', () {
      test('creates modified copy with new balance', () {
        final original = Wallet(
          id: 'w1',
          name: 'Original',
          balance: 1000,
          currency: 'VND',
          userId: 'u1',
          createdAt: DateTime.now(),
        );

        final modified = original.copyWith(balance: 5000);

        expect(modified.balance, 5000);
        expect(modified.id, 'w1');
        expect(modified.name, 'Original');
      });

      test('creates modified copy with new name', () {
        final original = Wallet(
          id: 'w1',
          name: 'Old Name',
          balance: 1000,
          currency: 'VND',
          userId: 'u1',
          createdAt: DateTime.now(),
        );

        final modified = original.copyWith(name: 'New Name');

        expect(modified.name, 'New Name');
        expect(modified.balance, 1000);
      });
    });
  });
}
