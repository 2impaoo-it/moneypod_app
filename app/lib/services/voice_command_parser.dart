import '../models/voice_command.dart';

/// Parser để convert voice text thành VoiceCommand
class VoiceCommandParser {
  /// Parse voice text to command
  static VoiceCommand? parse(String voiceText) {
    final text = voiceText.toLowerCase().trim();

    if (text.isEmpty) return null;

    // Detect command type và parse
    if (_isExpenseCommand(text)) {
      return _parseExpense(text);
    } else if (_isIncomeCommand(text)) {
      return _parseIncome(text);
    } else if (_isTransferCommand(text)) {
      return _parseTransfer(text);
    } else if (_isQueryCommand(text)) {
      return _parseQuery(text);
    }

    return null;
  }

  // ==================== EXPENSE ====================

  static bool _isExpenseCommand(String text) {
    return text.contains('chi') ||
        text.contains('mua') ||
        text.contains('trả') ||
        text.contains('tiêu');
  }

  static VoiceCommand _parseExpense(String text) {
    final amount = _extractAmount(text);
    final category = _detectExpenseCategory(text);
    final note = _extractNote(text);

    return VoiceCommand(
      type: 'expense',
      amount: amount,
      category: category,
      note: note,
    );
  }

  // ==================== INCOME ====================

  static bool _isIncomeCommand(String text) {
    return text.contains('thu') ||
        text.contains('nhận') ||
        text.contains('lương') ||
        text.contains('thưởng');
  }

  static VoiceCommand _parseIncome(String text) {
    final amount = _extractAmount(text);
    return VoiceCommand(
      type: 'income',
      amount: amount,
      category: _detectIncomeCategory(text),
      note: _extractNote(text),
    );
  }

  // ==================== TRANSFER ====================

  static bool _isTransferCommand(String text) {
    return text.contains('chuyển');
  }

  static VoiceCommand _parseTransfer(String text) {
    final amount = _extractAmount(text);
    // Extract wallet names từ text
    String? fromWallet;
    String? toWallet;

    // Pattern: "từ X sang Y"
    final fromPattern = RegExp(r'từ\s+(?:ví\s+)?(\w+(?:\s+\w+)?)');
    final toPattern = RegExp(r'sang\s+(?:ví\s+)?(\w+(?:\s+\w+)?)');

    final fromMatch = fromPattern.firstMatch(text);
    final toMatch = toPattern.firstMatch(text);

    if (fromMatch != null) fromWallet = fromMatch.group(1);
    if (toMatch != null) toWallet = toMatch.group(1);

    return VoiceCommand(
      type: 'transfer',
      amount: amount,
      fromWallet: fromWallet,
      toWallet: toWallet,
      note: 'Chuyển tiền',
    );
  }

  // ==================== QUERY ====================

  static bool _isQueryCommand(String text) {
    return text.contains('bao nhiêu') ||
        text.contains('tổng') ||
        text.contains('còn lại') ||
        text.contains('tư vấn') ||
        text.contains('gợi ý');
  }

  static VoiceCommand _parseQuery(String text) {
    return VoiceCommand(type: 'query', amount: 0, note: text);
  }

  // ==================== HELPERS ====================

  /// Extract số tiền từ text
  /// Hỗ trợ: "50 nghìn", "2 triệu", "2 triệu 5", "1.5 triệu", "500k"
  static double _extractAmount(String text) {
    // Pattern 1: "X triệu Y" (e.g., "2 triệu 5" → 2,500,000)
    final millionWithExtraPattern = RegExp(
      r'(\d+(?:[,.]?\d+)?)\s*triệu\s*(\d+)',
    );
    final millionWithExtraMatch = millionWithExtraPattern.firstMatch(text);
    if (millionWithExtraMatch != null) {
      final millions = double.parse(
        millionWithExtraMatch.group(1)!.replaceAll(',', '.'),
      );
      final extra = double.parse(millionWithExtraMatch.group(2)!);
      return millions * 1000000 + extra * 100000; // "2 triệu 5" = 2.5 triệu
    }

    // Pattern 2: "X triệu" hoặc "X.Y triệu" (e.g., "1.5 triệu" → 1,500,000)
    final millionPattern = RegExp(r'(\d+(?:[,.]?\d+)?)\s*triệu');
    final millionMatch = millionPattern.firstMatch(text);
    if (millionMatch != null) {
      final millions = double.parse(
        millionMatch.group(1)!.replaceAll(',', '.'),
      );
      return millions * 1000000;
    }

    // Pattern 3: "X nghìn/ngàn/k" (e.g., "50 nghìn" → 50,000)
    final thousandPattern = RegExp(r'(\d+(?:[,.]?\d+)?)\s*(?:nghìn|ngàn|k\b)');
    final thousandMatch = thousandPattern.firstMatch(text);
    if (thousandMatch != null) {
      return double.parse(thousandMatch.group(1)!.replaceAll(',', '.')) * 1000;
    }

    // Pattern 4: Plain number (fallback)
    final numberPattern = RegExp(r'(\d+(?:[,.]?\d+)?)');
    final numberMatch = numberPattern.firstMatch(text);
    if (numberMatch != null) {
      final num = double.parse(numberMatch.group(1)!.replaceAll(',', '.'));
      // Nếu số > 1000 thì giữ nguyên, nếu < 1000 có thể là nghìn
      return num >= 1000 ? num : num * 1000;
    }

    return 0;
  }

  /// Detect expense category từ keywords
  static String _detectExpenseCategory(String text) {
    final categoryMap = {
      'Ăn uống': [
        'ăn',
        'uống',
        'cơm',
        'cafe',
        'cà phê',
        'nhậu',
        'bia',
        'trà',
        'nước',
        'sáng',
        'trưa',
        'tối',
        'đồ ăn',
      ],
      'Di chuyển': [
        'xe',
        'xăng',
        'taxi',
        'grab',
        'bus',
        'tàu',
        'máy bay',
        'gửi xe',
        'đi lại',
      ],
      'Mua sắm': [
        'mua',
        'quần',
        'áo',
        'giày',
        'túi',
        'đồ',
        'shopping',
        'điện thoại',
      ],
      'Hóa đơn': [
        'điện',
        'nước',
        'internet',
        'wifi',
        'gas',
        'rác',
        'hóa đơn',
        'tiền nhà',
      ],
      'Sức khỏe': ['thuốc', 'bệnh viện', 'khám', 'bác sĩ', 'y tế'],
      'Giáo dục': ['học', 'sách', 'khóa học', 'trường', 'học phí'],
      'Giải trí': ['phim', 'game', 'du lịch', 'xem', 'chơi', 'giải trí'],
    };

    for (var entry in categoryMap.entries) {
      for (var keyword in entry.value) {
        if (text.contains(keyword)) {
          return entry.key;
        }
      }
    }

    return 'Khác';
  }

  /// Detect income category
  static String _detectIncomeCategory(String text) {
    if (text.contains('lương') || text.contains('công')) return 'Lương';
    if (text.contains('thưởng') || text.contains('bonus')) return 'Thưởng';
    if (text.contains('đầu tư') ||
        text.contains('cổ tức') ||
        text.contains('lãi')) {
      return 'Đầu tư';
    }
    if (text.contains('bán') || text.contains('kinh doanh')) return 'Bán hàng';
    return 'Khác';
  }

  /// Extract note (phần còn lại sau khi remove amount patterns)
  static String _extractNote(String text) {
    var note = text
        // Remove amount patterns
        .replaceAll(
          RegExp(r'\d+(?:[,.]?\d+)?\s*(?:triệu|nghìn|ngàn|k\b)\s*\d*'),
          '',
        )
        // Remove command keywords
        .replaceAll(RegExp(r'^(chi|thu|mua|trả|nhận|chuyển)\s*'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return note.isEmpty ? '' : note;
  }
}
