// Currency Input Formatter Tests
import 'package:flutter_test/flutter_test.dart';
import 'package:moneypod/utils/currency_input_formatter.dart';

void main() {
  group('CurrencyInputFormatter', () {
    late CurrencyInputFormatter formatter;

    setUp(() {
      formatter = CurrencyInputFormatter();
    });

    TextEditingValue formatValue(String text) {
      return formatter.formatEditUpdate(
        const TextEditingValue(text: ''),
        TextEditingValue(text: text),
      );
    }

    group('formatEditUpdate', () {
      test('formats numbers with thousand separators', () {
        expect(formatValue('1000').text, '1.000');
        expect(formatValue('1000000').text, '1.000.000');
        expect(formatValue('10000000').text, '10.000.000');
        expect(formatValue('123456789').text, '123.456.789');
      });

      test('handles small numbers (no separator needed)', () {
        expect(formatValue('1').text, '1');
        expect(formatValue('12').text, '12');
        expect(formatValue('123').text, '123');
        expect(formatValue('999').text, '999');
      });

      test('handles empty input', () {
        expect(formatValue('').text, '');
      });

      test('removes non-digit characters', () {
        expect(
          formatValue('1.000.000').text,
          '1.000.000',
        ); // re-formats correctly
        expect(formatValue('abc123').text, '123');
        expect(formatValue('1a2b3c').text, '123');
        expect(formatValue(r'$100').text, '100');
      });

      test('handles input with only non-digits', () {
        expect(formatValue('abc').text, '');
        expect(formatValue('!@#').text, '');
      });

      test('positions cursor at end', () {
        final result = formatValue('1000000');
        expect(result.selection.baseOffset, result.text.length);
        expect(result.selection.extentOffset, result.text.length);
      });

      test('handles incremental updates', () {
        // Simulate typing
        var result = formatter.formatEditUpdate(
          const TextEditingValue(text: ''),
          const TextEditingValue(text: '1'),
        );
        expect(result.text, '1');

        result = formatter.formatEditUpdate(
          result,
          TextEditingValue(text: '${result.text}0'),
        );
        expect(result.text, '10');

        result = formatter.formatEditUpdate(
          result,
          TextEditingValue(text: '${result.text}0'),
        );
        expect(result.text, '100');

        result = formatter.formatEditUpdate(
          result,
          TextEditingValue(text: '${result.text}0'),
        );
        expect(result.text, '1.000');
      });
    });
  });

  group('parseCurrency', () {
    test('parses formatted string to double', () {
      expect(parseCurrency('1.000.000'), 1000000);
      expect(parseCurrency('500.000'), 500000);
      expect(parseCurrency('123'), 123);
    });

    test('handles unformatted string', () {
      expect(parseCurrency('1000000'), 1000000);
    });

    test('returns null for empty string', () {
      expect(parseCurrency(''), isNull);
    });

    test('returns null for non-numeric string', () {
      expect(parseCurrency('abc'), isNull);
    });

    test('ignores non-digit characters', () {
      expect(parseCurrency('₫1.000.000'), 1000000);
      expect(parseCurrency('VND 500,000'), 500000);
    });
  });

  group('formatCurrency', () {
    test('formats numbers with thousand separators', () {
      expect(formatCurrency(1000000), '1.000.000');
      expect(formatCurrency(500000), '500.000');
      expect(formatCurrency(123456789), '123.456.789');
    });

    test('handles small numbers', () {
      expect(formatCurrency(1), '1');
      expect(formatCurrency(12), '12');
      expect(formatCurrency(123), '123');
      expect(formatCurrency(999), '999');
    });

    test('handles zero', () {
      expect(formatCurrency(0), '0');
    });

    test('truncates decimal part', () {
      expect(formatCurrency(1000.99), '1.000');
      expect(formatCurrency(1234.567), '1.234');
    });

    test('handles large numbers', () {
      expect(formatCurrency(1000000000000), '1.000.000.000.000');
    });
  });
}
