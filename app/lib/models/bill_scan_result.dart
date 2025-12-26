import 'package:equatable/equatable.dart';

class BillScanResult extends Equatable {
  final String merchant; // Tên cửa hàng (VD: Highlands)
  final double amount; // Tổng tiền (VD: 59000)
  final DateTime date; // Ngày hóa đơn
  final String category; // Gợi ý: Ăn uống, Di chuyển, Mua sắm...
  final String? note; // Ghi chú thêm

  const BillScanResult({
    required this.merchant,
    required this.amount,
    required this.date,
    required this.category,
    this.note,
  });

  factory BillScanResult.fromJson(Map<String, dynamic> json) {
    return BillScanResult(
      merchant: json['merchant'] ?? 'Không rõ',
      amount: _parseAmount(json['amount']),
      date: _parseDate(json['date']),
      category: json['category'] ?? 'Khác',
      note: json['note'],
    );
  }

  static double _parseAmount(dynamic amount) {
    if (amount == null) return 0.0;
    if (amount is double) return amount;
    if (amount is int) return amount.toDouble();
    if (amount is String) {
      // Loại bỏ ký tự không phải số và dấu chấm/phẩy
      final cleaned = amount.replaceAll(RegExp(r'[^\d.,]'), '');
      final normalized = cleaned.replaceAll(',', '.');
      return double.tryParse(normalized) ?? 0.0;
    }
    return 0.0;
  }

  static DateTime _parseDate(dynamic date) {
    if (date == null) return DateTime.now();
    if (date is DateTime) return date;
    if (date is String) {
      try {
        return DateTime.parse(date);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'merchant': merchant,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': category,
      'note': note,
    };
  }

  /// Tạo title từ merchant và category để hiển thị
  String get title => '$category tại $merchant';

  @override
  List<Object?> get props => [merchant, amount, date, category, note];
}
