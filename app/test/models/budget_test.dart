import 'package:flutter_test/flutter_test.dart';
import 'package:moneypod/models/budget.dart';

void main() {
  group('Budget Model', () {
    group('fromJson', () {
      test('parses complete data correctly', () {
        final json = {
          'id': 'budget-123',
          'category': 'Ăn uống',
          'amount': 5000000.0,
          'spent': 2500000.0,
          'month': 1,
          'year': 2026,
        };

        final budget = Budget.fromJson(json);

        expect(budget.id, 'budget-123');
        expect(budget.category, 'Ăn uống');
        expect(budget.amount, 5000000.0);
        expect(budget.spent, 2500000.0);
        expect(budget.month, 1);
        expect(budget.year, 2026);
      });

      test('handles missing spent field with default 0', () {
        final json = {
          'id': 'budget-456',
          'category': 'Di chuyển',
          'amount': 2000000.0,
          'month': 1,
          'year': 2026,
        };

        final budget = Budget.fromJson(json);

        expect(budget.spent, 0.0);
      });

      test('parses int amount correctly', () {
        final json = {
          'id': 'budget-789',
          'category': 'Mua sắm',
          'amount': 3000000,
          'spent': 1000000,
          'month': 2,
          'year': 2026,
        };

        final budget = Budget.fromJson(json);

        expect(budget.amount, 3000000.0);
        expect(budget.spent, 1000000.0);
      });
    });

    group('toJson', () {
      test('serializes all fields correctly', () {
        final budget = Budget(
          id: 'b1',
          category: 'Giải trí',
          amount: 1000000,
          spent: 500000,
          month: 1,
          year: 2026,
        );

        final json = budget.toJson();

        expect(json['id'], 'b1');
        expect(json['category'], 'Giải trí');
        expect(json['amount'], 1000000);
        expect(json['spent'], 500000);
        expect(json['month'], 1);
        expect(json['year'], 2026);
      });
    });

    group('remaining getter', () {
      test('calculates remaining correctly', () {
        final budget = Budget(
          id: 'b1',
          category: 'Ăn uống',
          amount: 5000000,
          spent: 3000000,
          month: 1,
          year: 2026,
        );

        expect(budget.remaining, 2000000);
      });

      test('returns negative when overspent', () {
        final budget = Budget(
          id: 'b2',
          category: 'Mua sắm',
          amount: 1000000,
          spent: 1500000,
          month: 1,
          year: 2026,
        );

        expect(budget.remaining, -500000);
      });

      test('returns full amount when nothing spent', () {
        final budget = Budget(
          id: 'b3',
          category: 'Di chuyển',
          amount: 2000000,
          spent: 0,
          month: 1,
          year: 2026,
        );

        expect(budget.remaining, 2000000);
      });
    });

    group('progress getter', () {
      test('calculates progress correctly (50%)', () {
        final budget = Budget(
          id: 'b1',
          category: 'Ăn uống',
          amount: 1000000,
          spent: 500000,
          month: 1,
          year: 2026,
        );

        expect(budget.progress, 0.5);
      });

      test('clamps progress to 1.0 when overspent', () {
        final budget = Budget(
          id: 'b2',
          category: 'Mua sắm',
          amount: 1000000,
          spent: 1500000, // 150%
          month: 1,
          year: 2026,
        );

        expect(budget.progress, 1.0);
      });

      test('returns 0 when nothing spent', () {
        final budget = Budget(
          id: 'b3',
          category: 'Di chuyển',
          amount: 2000000,
          spent: 0,
          month: 1,
          year: 2026,
        );

        expect(budget.progress, 0.0);
      });

      test('handles full budget usage (100%)', () {
        final budget = Budget(
          id: 'b4',
          category: 'Hóa đơn',
          amount: 500000,
          spent: 500000,
          month: 1,
          year: 2026,
        );

        expect(budget.progress, 1.0);
      });
    });

    group('copyWith', () {
      test('creates modified copy with new spent', () {
        final original = Budget(
          id: 'b1',
          category: 'Ăn uống',
          amount: 5000000,
          spent: 1000000,
          month: 1,
          year: 2026,
        );

        final modified = original.copyWith(spent: 2000000);

        expect(modified.spent, 2000000);
        expect(modified.id, 'b1');
        expect(modified.amount, 5000000);
        expect(modified.category, 'Ăn uống');
      });

      test('creates modified copy with new amount', () {
        final original = Budget(
          id: 'b1',
          category: 'Mua sắm',
          amount: 1000000,
          spent: 500000,
          month: 1,
          year: 2026,
        );

        final modified = original.copyWith(amount: 2000000);

        expect(modified.amount, 2000000);
        expect(modified.spent, 500000);
      });

      test('creates modified copy for next month', () {
        final original = Budget(
          id: 'b1',
          category: 'Ăn uống',
          amount: 5000000,
          spent: 0,
          month: 1,
          year: 2026,
        );

        final modified = original.copyWith(month: 2, spent: 0);

        expect(modified.month, 2);
        expect(modified.spent, 0);
      });
    });
  });
}
