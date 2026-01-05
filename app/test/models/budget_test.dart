import 'package:flutter_test/flutter_test.dart';
import 'package:moneypod/models/budget.dart';

void main() {
  group('Budget Model', () {
    group('fromJson', () {
      test('parses complete JSON correctly', () {
        final json = {
          'id': '123',
          'category': 'Ăn uống',
          'amount': 5000000.0,
          'spent': 2500000.0,
          'month': 1,
          'year': 2026,
        };

        final budget = Budget.fromJson(json);

        expect(budget.id, '123');
        expect(budget.category, 'Ăn uống');
        expect(budget.amount, 5000000.0);
        expect(budget.spent, 2500000.0);
        expect(budget.month, 1);
        expect(budget.year, 2026);
      });

      test('handles int amount', () {
        final json = {
          'id': '1',
          'category': 'Food',
          'amount': 1000000,
          'month': 5,
          'year': 2026,
        };

        final budget = Budget.fromJson(json);
        expect(budget.amount, 1000000.0);
      });

      test('defaults spent to 0 when null', () {
        final json = {
          'id': '1',
          'category': 'Food',
          'amount': 1000000,
          'spent': null,
          'month': 5,
          'year': 2026,
        };

        final budget = Budget.fromJson(json);
        expect(budget.spent, 0.0);
      });

      test('handles missing spent field', () {
        final json = {
          'id': '1',
          'category': 'Shopping',
          'amount': 2000000,
          'month': 6,
          'year': 2026,
        };

        final budget = Budget.fromJson(json);
        expect(budget.spent, 0.0);
      });
    });

    group('toJson', () {
      test('serializes all fields correctly', () {
        final budget = Budget(
          id: '123',
          category: 'Entertainment',
          amount: 3000000,
          spent: 1500000,
          month: 12,
          year: 2026,
        );

        final json = budget.toJson();

        expect(json['id'], '123');
        expect(json['category'], 'Entertainment');
        expect(json['amount'], 3000000);
        expect(json['spent'], 1500000);
        expect(json['month'], 12);
        expect(json['year'], 2026);
      });

      test('includes default spent value', () {
        final budget = Budget(
          id: '1',
          category: 'Test',
          amount: 1000,
          month: 1,
          year: 2026,
        );

        final json = budget.toJson();
        expect(json['spent'], 0);
      });
    });

    group('copyWith', () {
      test('copies all fields when provided', () {
        final original = Budget(
          id: '1',
          category: 'Old',
          amount: 1000,
          spent: 500,
          month: 1,
          year: 2025,
        );

        final copied = original.copyWith(
          category: 'New',
          amount: 2000,
          spent: 1000,
          month: 2,
          year: 2026,
        );

        expect(copied.id, '1'); // unchanged
        expect(copied.category, 'New');
        expect(copied.amount, 2000);
        expect(copied.spent, 1000);
        expect(copied.month, 2);
        expect(copied.year, 2026);
      });

      test('preserves original values when not provided', () {
        final original = Budget(
          id: '1',
          category: 'Food',
          amount: 5000000,
          spent: 2000000,
          month: 6,
          year: 2026,
        );

        final copied = original.copyWith(spent: 3000000);

        expect(copied.id, '1');
        expect(copied.category, 'Food');
        expect(copied.amount, 5000000);
        expect(copied.spent, 3000000);
        expect(copied.month, 6);
        expect(copied.year, 2026);
      });
    });

    group('computed properties', () {
      test('remaining calculates correctly', () {
        final budget = Budget(
          id: '1',
          category: 'Food',
          amount: 5000000,
          spent: 2000000,
          month: 1,
          year: 2026,
        );

        expect(budget.remaining, 3000000);
      });

      test('remaining can be negative (overspent)', () {
        final budget = Budget(
          id: '1',
          category: 'Food',
          amount: 1000000,
          spent: 1500000,
          month: 1,
          year: 2026,
        );

        expect(budget.remaining, -500000);
      });

      test('progress calculates percentage correctly', () {
        final budget = Budget(
          id: '1',
          category: 'Food',
          amount: 5000000,
          spent: 2500000,
          month: 1,
          year: 2026,
        );

        expect(budget.progress, 0.5);
      });

      test('progress is clamped to 0 minimum', () {
        final budget = Budget(
          id: '1',
          category: 'Food',
          amount: 1000000,
          spent: 0,
          month: 1,
          year: 2026,
        );

        expect(budget.progress, 0.0);
      });

      test('progress is clamped to 1 maximum (overspent)', () {
        final budget = Budget(
          id: '1',
          category: 'Food',
          amount: 1000000,
          spent: 2000000,
          month: 1,
          year: 2026,
        );

        expect(budget.progress, 1.0);
      });

      test('progress handles zero amount', () {
        final budget = Budget(
          id: '1',
          category: 'Food',
          amount: 0,
          spent: 0,
          month: 1,
          year: 2026,
        );

        // Division by zero should be handled (NaN check)
        expect(budget.progress.isNaN || budget.progress == 1.0, isTrue);
      });
    });

    group('roundtrip', () {
      test('fromJson -> toJson preserves data', () {
        final originalJson = {
          'id': '123',
          'category': 'Shopping',
          'amount': 3000000.0,
          'spent': 1500000.0,
          'month': 3,
          'year': 2026,
        };

        final budget = Budget.fromJson(originalJson);
        final resultJson = budget.toJson();

        expect(resultJson['id'], originalJson['id']);
        expect(resultJson['category'], originalJson['category']);
        expect(resultJson['amount'], originalJson['amount']);
        expect(resultJson['spent'], originalJson['spent']);
        expect(resultJson['month'], originalJson['month']);
        expect(resultJson['year'], originalJson['year']);
      });
    });
  });
}
