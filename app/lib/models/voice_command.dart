/// Model lưu thông tin command đã parse từ giọng nói
class VoiceCommand {
  final String type; // 'expense', 'income', 'transfer', 'query'
  final double amount;
  final String? category;
  final String? note;
  final String? fromWallet;
  final String? toWallet;

  VoiceCommand({
    required this.type,
    required this.amount,
    this.category,
    this.note,
    this.fromWallet,
    this.toWallet,
    this.walletId,
  });

  final String? walletId;

  VoiceCommand copyWith({
    String? type,
    double? amount,
    String? category,
    String? note,
    String? fromWallet,
    String? toWallet,
    String? walletId,
  }) {
    return VoiceCommand(
      type: type ?? this.type,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      note: note ?? this.note,
      fromWallet: fromWallet ?? this.fromWallet,
      toWallet: toWallet ?? this.toWallet,
      walletId: walletId ?? this.walletId,
    );
  }

  @override
  String toString() {
    switch (type) {
      case 'expense':
        return 'Chi ${_formatAmount(amount)} cho $category${note != null && note!.isNotEmpty ? " - $note" : ""}';
      case 'income':
        return 'Thu nhập ${_formatAmount(amount)}${category != null ? " từ $category" : ""}';
      case 'transfer':
        return 'Chuyển ${_formatAmount(amount)} từ $fromWallet sang $toWallet';
      default:
        return note ?? '';
    }
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(amount % 1000000 == 0 ? 0 : 1)} triệu';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(amount % 1000 == 0 ? 0 : 1)} nghìn';
    }
    return amount.toStringAsFixed(0);
  }

  /// Tạo summary ngắn gọn cho confirmation dialog
  String get summary {
    switch (type) {
      case 'expense':
        return 'Chi tiêu: ${_formatAmount(amount)}đ - ${category ?? "Khác"}';
      case 'income':
        return 'Thu nhập: ${_formatAmount(amount)}đ - ${category ?? "Khác"}';
      case 'transfer':
        return 'Chuyển: ${_formatAmount(amount)}đ';
      default:
        return note ?? '';
    }
  }
}
