import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter;

  CurrencyInputFormatter({String locale = 'vi_VN'})
    : _formatter = NumberFormat.currency(
        locale: locale,
        symbol: '',
        decimalDigits: 0,
      );

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Xóa tất cả ký tự không phải số
    final cleanText = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    // Parse sang số
    final number = double.tryParse(cleanText);
    if (number == null) {
      return oldValue;
    }

    // Format lại
    final newText = _formatter.format(number).trim();

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }

  static double parse(String text) {
    return double.tryParse(text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
  }
}
