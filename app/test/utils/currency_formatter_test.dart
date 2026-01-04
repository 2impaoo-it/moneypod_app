import 'package:flutter_test/flutter_test.dart';
import 'package:moneypod/utils/currency_formatter.dart';

void main() {
  group('CurrencyInputFormatter', () {
    group('parse', () {
      test('parses formatted string correctly', () {
        expect(CurrencyInputFormatter.parse('1.000.000'), 1000000);
      });

      test('parses plain number string', () {
        expect(CurrencyInputFormatter.parse('50000'), 50000);
      });

      test('removes non-numeric characters', () {
        expect(CurrencyInputFormatter.parse('1.500.000 ₫'), 1500000);
      });

      test('handles empty string', () {
        expect(CurrencyInputFormatter.parse(''), 0);
      });

      test('handles string with only non-numeric chars', () {
        expect(CurrencyInputFormatter.parse('abc'), 0);
      });
    });

    // Note: formatEditUpdate tests require TextEditingValue
    // These are more complex and typically tested with integration tests
  });
}
