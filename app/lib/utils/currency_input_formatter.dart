import 'package:flutter/services.dart';

/// TextInputFormatter tự động thêm dấu . phân cách hàng nghìn cho tiền Việt
/// VD: 1000000 -> 1.000.000
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Nếu xóa hết, trả về rỗng
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Chỉ giữ lại số, bỏ dấu . cũ
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    // Nếu không có số, trả về rỗng
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Format lại với dấu . phân cách hàng nghìn
    final formatted = _formatWithThousandSeparator(digitsOnly);

    // Tính vị trí cursor mới
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  /// Thêm dấu . phân cách mỗi 3 chữ số từ phải qua
  String _formatWithThousandSeparator(String digits) {
    final buffer = StringBuffer();
    final length = digits.length;

    for (int i = 0; i < length; i++) {
      buffer.write(digits[i]);
      final remaining = length - i - 1;
      if (remaining > 0 && remaining % 3 == 0) {
        buffer.write('.');
      }
    }

    return buffer.toString();
  }
}

/// Hàm tiện ích: Parse số từ string có dấu . (VD: "1.000.000" -> 1000000)
double? parseCurrency(String text) {
  final digitsOnly = text.replaceAll(RegExp(r'[^\d]'), '');
  if (digitsOnly.isEmpty) return null;
  return double.tryParse(digitsOnly);
}

/// Hàm tiện ích: Format số thành string có dấu . (VD: 1000000 -> "1.000.000")
String formatCurrency(num amount) {
  final str = amount.toInt().toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (Match m) => '${m[1]}.',
  );
  return str;
}
