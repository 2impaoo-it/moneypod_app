import 'package:flutter_test/flutter_test.dart';
import 'package:moneypod/models/bill_scan_result.dart';

void main() {
  group('BillScanResult Model Test', () {
    test('supports value equality', () {
      final date = DateTime(2023, 10, 27);
      final result1 = BillScanResult(
        merchant: 'Test Store',
        amount: 100.0,
        date: date,
        category: 'Food',
        note: 'Lunch',
      );
      final result2 = BillScanResult(
        merchant: 'Test Store',
        amount: 100.0,
        date: date,
        category: 'Food',
        note: 'Lunch',
      );

      expect(result1, equals(result2));
    });

    test('fromJson parses correctly', () {
      final json = {
        'merchant': 'Coffee Shop',
        'amount': 55000,
        'date': '2023-10-27T10:00:00Z',
        'category': 'Drink',
        'note': 'Morning coffee',
      };

      final result = BillScanResult.fromJson(json);

      expect(result.merchant, 'Coffee Shop');
      expect(result.amount, 55000.0);
      expect(result.date.year, 2023);
      expect(result.category, 'Drink');
      expect(result.note, 'Morning coffee');
    });

    test('fromJson parses string amount correctly', () {
      final json = {
        'merchant': 'Shop',
        'amount': '55.000', // string with dot
        'date': null,
        'category': null,
      };

      final result = BillScanResult.fromJson(json);

      // Regex [^\d.,] keeps digits, dots, commas.
      // '55.000' -> cleaned '55.000' -> normalized '55.000'
      // double.tryParse('55.000') is 55.0 (standard double format)
      expect(result.amount, 55.0);
      expect(result.merchant, 'Shop');
      expect(result.category, 'Khác');
    });

    test('toJson returns correct map', () {
      final date = DateTime(2023, 10, 27);
      final result = BillScanResult(
        merchant: 'Store',
        amount: 123.0,
        date: date,
        category: 'Shopping',
      );

      final json = result.toJson();

      expect(json['merchant'], 'Store');
      expect(json['amount'], 123.0);
      expect(json['date'], date.toIso8601String());
      expect(json['category'], 'Shopping');
      expect(json['note'], null);
    });

    test('title getter returns correct format', () {
      final result = BillScanResult(
        merchant: 'Highlands',
        amount: 0,
        date: DateTime.now(),
        category: 'Coffee',
      );

      expect(result.title, 'Coffee tại Highlands');
    });
  });
}
