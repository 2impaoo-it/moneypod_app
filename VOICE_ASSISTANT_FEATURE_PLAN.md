# 🎤 Voice Assistant Feature - Kế hoạch Implement

## 📋 Tổng quan

Chức năng trợ lý giọng nói cho phép người dùng thao tác với app bằng giọng nói, tăng tốc độ nhập liệu và trải nghiệm người dùng.

---

## 🎯 Các chức năng chính

### Priority 1: Thêm giao dịch bằng giọng nói ⭐⭐⭐⭐⭐

**Mô tả:** User nói lệnh, app tự động tạo transaction

**Use cases:**

- ✅ "Chi 50 nghìn ăn sáng" → Expense: 50,000đ, category: Ăn uống, note: "ăn sáng"
- ✅ "Thu nhập 5 triệu lương tháng 1" → Income: 5,000,000đ, category: Lương
- ✅ "Chuyển 500 nghìn từ ví tiền mặt sang ngân hàng" → Transfer between wallets
- ✅ "Chi 2 triệu 5 mua điện thoại" → Parse số thập phân: 2,500,000

**Flow:**

1. User nhấn nút mic trên dashboard
2. Bottom sheet hiện lên với animation wave (đang nghe)
3. User nói lệnh
4. App parse giọng nói → text
5. NLP extract: type, amount, category, note
6. Show confirmation dialog với thông tin đã parse
7. User xác nhận → Gọi API tạo transaction
8. Show success notification

---

### Priority 2: AI Assistant kết hợp Gemini ⭐⭐⭐⭐

**Mô tả:** Trợ lý AI trả lời câu hỏi về tài chính và đưa lời khuyên

**Use cases:**

- ✅ "Tư vấn giúp tôi tiết kiệm" → Gemini analyze spending + suggest
- ✅ "Đánh giá chi tiêu tháng này" → Read insight + voice response
- ✅ "Nên cắt giảm gì để tiết kiệm?" → AI recommendations
- ✅ "So sánh chi tiêu tháng này với tháng trước" → Analytics

**Flow:**

1. User nói câu hỏi
2. App gửi voice → text
3. Gửi text + transaction data → Gemini API
4. Gemini generate response
5. App đọc response bằng text-to-speech
6. Hiện response dạng text trong bottom sheet

---

### Priority 3: Hỏi thông tin nhanh ⭐⭐⭐

**Mô tả:** Query thông tin tài chính bằng giọng nói

**Use cases:**

- ✅ "Tổng chi hôm nay bao nhiêu?" → Calculate today expenses
- ✅ "Còn bao nhiêu tiền trong ví?" → Read wallet balance
- ✅ "Chi nhiều nhất cho danh mục nào?" → Top category
- ✅ "Giao dịch gần nhất của tôi" → Last transaction

**Flow:**

1. User hỏi
2. App parse intent
3. Query local data (không cần Gemini)
4. Format response
5. Text-to-speech đọc kết quả

---

### Priority 4: Báo cáo bằng giọng nói ⭐⭐

**Mô tả:** Đọc báo cáo tài chính

**Use cases:**

- ✅ "Đọc báo cáo tuần này"
- ✅ "Tóm tắt chi tiêu hôm qua"
- ✅ "Insight tháng này"

---

## 🛠️ Tech Stack

### Flutter Packages

```yaml
dependencies:
  # Speech to Text
  speech_to_text: ^7.0.0

  # Text to Speech (đọc response)
  flutter_tts: ^4.0.2

  # Permission handling
  permission_handler: ^11.3.1

  # Audio visualization (wave animation)
  avatar_glow: ^3.0.1
  # hoặc
  lottie: ^3.1.0 # Dùng Lottie animation cho wave


  # NLP parsing (nếu không dùng Gemini)
  # intl package đã có sẵn cho number parsing
```

---

## 📁 File Structure

```
lib/
├── services/
│   ├── voice_service.dart              # Speech-to-text & Text-to-speech
│   ├── voice_command_parser.dart       # Parse voice commands
│   └── gemini_voice_assistant.dart     # AI assistant với Gemini
├── screens/
│   └── voice_assistant_screen.dart     # Bottom sheet voice UI
├── widgets/
│   ├── voice_wave_animation.dart       # Animation khi đang nghe
│   └── voice_confirmation_dialog.dart  # Confirm parsed transaction
└── models/
    └── voice_command.dart              # Model cho parsed command
```

---

## 🔧 Implementation Plan

### Phase 1: Setup cơ bản (1-2 giờ)

#### 1.1. Install packages

```bash
flutter pub add speech_to_text flutter_tts permission_handler avatar_glow
```

#### 1.2. Tạo VoiceService

**File:** `lib/services/voice_service.dart`

```dart
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';

class VoiceService {
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _isListening = false;
  bool get isListening => _isListening;

  // Initialize
  Future<bool> initialize() async {
    return await _speech.initialize();
  }

  // Start listening
  Future<void> startListening({
    required Function(String) onResult,
  }) async {
    if (!_isListening) {
      _isListening = true;
      await _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            onResult(result.recognizedWords);
          }
        },
        localeId: 'vi_VN', // Vietnamese
      );
    }
  }

  // Stop listening
  Future<void> stopListening() async {
    _isListening = false;
    await _speech.stop();
  }

  // Text-to-speech
  Future<void> speak(String text) async {
    await _tts.setLanguage('vi-VN');
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(0.5);
    await _tts.speak(text);
  }
}
```

---

### Phase 2: Voice Command Parser (2-3 giờ)

#### 2.1. Tạo VoiceCommandParser

**File:** `lib/services/voice_command_parser.dart`

```dart
import '../models/voice_command.dart';

class VoiceCommandParser {
  // Parse voice text to command
  static VoiceCommand? parse(String voiceText) {
    final text = voiceText.toLowerCase().trim();

    // Detect command type
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

  // Check if expense command
  static bool _isExpenseCommand(String text) {
    return text.contains('chi') ||
           text.contains('mua') ||
           text.contains('trả');
  }

  // Parse expense
  static VoiceCommand _parseExpense(String text) {
    final amount = _extractAmount(text);
    final category = _detectCategory(text);
    final note = _extractNote(text);

    return VoiceCommand(
      type: 'expense',
      amount: amount,
      category: category,
      note: note,
    );
  }

  // Extract amount từ text
  static double _extractAmount(String text) {
    // Pattern: "50 nghìn", "2 triệu", "1.5 triệu", "500k"

    // Check "X triệu Y"
    final millionPattern = RegExp(r'(\d+(?:[,.]\d+)?)\s*triệu\s*(\d+)?');
    final millionMatch = millionPattern.firstMatch(text);
    if (millionMatch != null) {
      final millions = double.parse(millionMatch.group(1)!.replaceAll(',', '.'));
      final extra = millionMatch.group(2);
      if (extra != null) {
        return millions * 1000000 + double.parse(extra) * 1000;
      }
      return millions * 1000000;
    }

    // Check "X nghìn"
    final thousandPattern = RegExp(r'(\d+(?:[,.]\d+)?)\s*(?:nghìn|ngàn|k)');
    final thousandMatch = thousandPattern.firstMatch(text);
    if (thousandMatch != null) {
      return double.parse(thousandMatch.group(1)!.replaceAll(',', '.')) * 1000;
    }

    // Check plain number
    final numberPattern = RegExp(r'(\d+(?:[,.]\d+)?)');
    final numberMatch = numberPattern.firstMatch(text);
    if (numberMatch != null) {
      return double.parse(numberMatch.group(1)!.replaceAll(',', '.'));
    }

    return 0;
  }

  // Detect category
  static String _detectCategory(String text) {
    final categoryMap = {
      'ăn': 'Ăn uống',
      'uống': 'Ăn uống',
      'cơm': 'Ăn uống',
      'cafe': 'Ăn uống',
      'bia': 'Ăn uống',

      'xe': 'Di chuyển',
      'xăng': 'Di chuyển',
      'taxi': 'Di chuyển',
      'grab': 'Di chuyển',

      'điện': 'Hóa đơn',
      'nước': 'Hóa đơn',
      'internet': 'Hóa đơn',
      'wifi': 'Hóa đơn',

      'quần': 'Mua sắm',
      'áo': 'Mua sắm',
      'giày': 'Mua sắm',
      'mua': 'Mua sắm',

      'thuốc': 'Sức khỏe',
      'bệnh viện': 'Sức khỏe',
      'khám': 'Sức khỏe',

      'học': 'Giáo dục',
      'sách': 'Giáo dục',
      'khóa': 'Giáo dục',
    };

    for (var entry in categoryMap.entries) {
      if (text.contains(entry.key)) {
        return entry.value;
      }
    }

    return 'Khác';
  }

  // Extract note
  static String _extractNote(String text) {
    // Remove amount patterns
    var note = text
        .replaceAll(RegExp(r'\d+(?:[,.]\d+)?\s*(?:triệu|nghìn|ngàn|k)?'), '')
        .replaceAll(RegExp(r'^(chi|thu|mua|trả)\s*'), '')
        .trim();

    return note.isEmpty ? '' : note;
  }

  // Similar methods for income, transfer, query...
  static bool _isIncomeCommand(String text) {
    return text.contains('thu') || text.contains('nhận');
  }

  static VoiceCommand _parseIncome(String text) {
    // Similar to expense
    final amount = _extractAmount(text);
    return VoiceCommand(
      type: 'income',
      amount: amount,
      category: _detectIncomeCategory(text),
      note: _extractNote(text),
    );
  }

  static String _detectIncomeCategory(String text) {
    if (text.contains('lương')) return 'Lương';
    if (text.contains('thưởng')) return 'Thưởng';
    if (text.contains('đầu tư')) return 'Đầu tư';
    return 'Khác';
  }

  static bool _isTransferCommand(String text) {
    return text.contains('chuyển');
  }

  static VoiceCommand _parseTransfer(String text) {
    final amount = _extractAmount(text);
    // Extract wallet names from text
    return VoiceCommand(
      type: 'transfer',
      amount: amount,
      note: text,
    );
  }

  static bool _isQueryCommand(String text) {
    return text.contains('bao nhiêu') ||
           text.contains('tổng') ||
           text.contains('còn lại');
  }

  static VoiceCommand _parseQuery(String text) {
    return VoiceCommand(
      type: 'query',
      amount: 0,
      note: text,
    );
  }
}
```

#### 2.2. Tạo VoiceCommand Model

**File:** `lib/models/voice_command.dart`

```dart
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
  });

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
}
```

---

### Phase 3: UI Implementation (3-4 giờ)

#### 3.1. Voice Assistant Bottom Sheet

**File:** `lib/screens/voice_assistant_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:avatar_glow/avatar_glow.dart';
import '../services/voice_service.dart';
import '../services/voice_command_parser.dart';
import '../widgets/voice_confirmation_dialog.dart';

class VoiceAssistantScreen extends StatefulWidget {
  const VoiceAssistantScreen({super.key});

  @override
  State<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen> {
  final VoiceService _voiceService = VoiceService();
  String _recognizedText = '';
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initVoice();
  }

  Future<void> _initVoice() async {
    final initialized = await _voiceService.initialize();
    setState(() {
      _isInitialized = initialized;
    });

    if (initialized) {
      _startListening();
    }
  }

  Future<void> _startListening() async {
    await _voiceService.startListening(
      onResult: (text) {
        setState(() {
          _recognizedText = text;
        });

        // Parse command
        final command = VoiceCommandParser.parse(text);
        if (command != null) {
          _showConfirmation(command);
        }
      },
    );
  }

  void _showConfirmation(VoiceCommand command) async {
    await _voiceService.stopListening();

    if (mounted) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => VoiceConfirmationDialog(command: command),
      );

      if (confirmed == true) {
        // Execute command
        Navigator.pop(context, command);
      } else {
        // Restart listening
        _startListening();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 24),

          // Title
          const Text(
            'Nói gì đó...',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 32),

          // Microphone with glow animation
          AvatarGlow(
            animate: _voiceService.isListening,
            glowColor: Theme.of(context).primaryColor,
            child: Material(
              elevation: 8,
              shape: const CircleBorder(),
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Theme.of(context).primaryColor,
                child: Icon(
                  _voiceService.isListening ? Icons.mic : Icons.mic_off,
                  size: 48,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Recognized text
          if (_recognizedText.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _recognizedText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ),

          const SizedBox(height: 24),

          // Examples
          Text(
            'Ví dụ: "Chi 50 nghìn ăn sáng"',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _voiceService.stopListening();
    super.dispose();
  }
}
```

#### 3.2. Confirmation Dialog

**File:** `lib/widgets/voice_confirmation_dialog.dart`

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/voice_command.dart';

class VoiceConfirmationDialog extends StatelessWidget {
  final VoiceCommand command;

  const VoiceConfirmationDialog({
    super.key,
    required this.command,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Text(
        'Xác nhận giao dịch',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRow('Loại:', _getTypeLabel(command.type)),
          const SizedBox(height: 8),
          _buildRow('Số tiền:', currencyFormat.format(command.amount)),
          if (command.category != null) ...[
            const SizedBox(height: 8),
            _buildRow('Danh mục:', command.category!),
          ],
          if (command.note != null && command.note!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildRow('Ghi chú:', command.note!),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Xác nhận'),
        ),
      ],
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'expense':
        return 'Chi tiêu';
      case 'income':
        return 'Thu nhập';
      case 'transfer':
        return 'Chuyển tiền';
      default:
        return type;
    }
  }
}
```

#### 3.3. Tích hợp vào Dashboard

**File:** `lib/screens/dashboard_screen.dart` (thêm vào nút mic)

```dart
// Trong phần build của dashboard, nơi có nút mic:
IconButton(
  icon: const Icon(LucideIcons.mic),
  onPressed: _openVoiceAssistant,
),

// Thêm method:
Future<void> _openVoiceAssistant() async {
  final command = await showModalBottomSheet<VoiceCommand>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const VoiceAssistantScreen(),
  );

  if (command != null) {
    // Execute command
    await _executeVoiceCommand(command);
  }
}

Future<void> _executeVoiceCommand(VoiceCommand command) async {
  try {
    switch (command.type) {
      case 'expense':
      case 'income':
        // Create transaction
        await _transactionRepository.createTransaction(
          type: command.type,
          amount: command.amount,
          category: command.category ?? 'Khác',
          note: command.note,
          date: DateTime.now(),
          walletId: _selectedWallet?.id ?? '',
        );

        PopupNotification.showSuccess(
          context,
          'Đã thêm ${command.type == 'expense' ? 'chi tiêu' : 'thu nhập'}',
        );

        // Refresh data
        _loadTransactions();
        break;

      case 'transfer':
        // Handle transfer
        break;

      case 'query':
        // Handle query
        break;
    }
  } catch (e) {
    PopupNotification.showError(context, 'Lỗi: $e');
  }
}
```

---

### Phase 4: Gemini AI Assistant (2-3 giờ)

#### 4.1. Tạo GeminiVoiceAssistant

**File:** `lib/services/gemini_voice_assistant.dart`

```dart
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiVoiceAssistant {
  final GenerativeModel _model;

  GeminiVoiceAssistant(String apiKey)
      : _model = GenerativeModel(
          model: 'gemini-1.5-flash',
          apiKey: apiKey,
        );

  Future<String> processQuery(String query, Map<String, dynamic> context) async {
    // Build prompt with context
    final prompt = _buildPrompt(query, context);

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? 'Xin lỗi, tôi không thể trả lời câu hỏi này.';
    } catch (e) {
      return 'Đã xảy ra lỗi khi xử lý yêu cầu của bạn.';
    }
  }

  String _buildPrompt(String query, Map<String, dynamic> context) {
    return '''
Bạn là trợ lý tài chính cá nhân thông minh. Phân tích dữ liệu và trả lời câu hỏi của người dùng một cách ngắn gọn (1-2 câu).

Dữ liệu tài chính:
- Tổng thu nhập tháng này: ${context['totalIncome']} VNĐ
- Tổng chi tiêu tháng này: ${context['totalExpense']} VNĐ
- Số dư hiện tại: ${context['balance']} VNĐ
- Danh mục chi nhiều nhất: ${context['topCategory']}

Câu hỏi: $query

Trả lời ngắn gọn bằng tiếng Việt, giọng thân thiện:
''';
  }
}
```

---

## 🎨 UI/UX Design Notes

### Voice Assistant Bottom Sheet

- **Background:** White với border radius 24px
- **Microphone icon:** Circle 120x120, primary color, elevation 8
- **Animation:** AvatarGlow với pulse effect khi đang nghe
- **Text display:** Grey background box hiển thị recognized text
- **Examples:** Small grey text phía dưới

### Confirmation Dialog

- **Style:** Alert dialog với rounded corners
- **Content:** Label-value pairs, bold labels
- **Actions:** Hủy (text button) + Xác nhận (elevated button)

---

## ⚠️ Important Notes

### 1. Permissions

Cần request microphone permission trong `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.INTERNET"/>
```

iOS: `Info.plist`

```xml
<key>NSMicrophoneUsageDescription</key>
<string>Cần quyền mic để nhận lệnh giọng nói</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>Cần quyền nhận dạng giọng nói</string>
```

### 2. Error Handling

- Network errors khi call Gemini API
- Speech recognition errors
- Parse errors khi command không hợp lệ
- Permission denied

### 3. Performance

- Cache Gemini responses cho queries phổ biến
- Debounce voice recognition để tránh spam
- Timeout cho speech recognition (10s)

### 4. Testing

- Test với nhiều giọng nói khác nhau
- Test với background noise
- Test edge cases (số tiền rất lớn, category không tồn tại)

---

## 📊 Metrics to Track

- **Voice command success rate:** % commands parsed correctly
- **Most used commands:** Track popular voice patterns
- **User retention:** Do users continue using voice after first time?
- **Error rate:** Track parse failures and recognition errors

---

## 🚀 Future Enhancements

1. **Multi-language support:** English, Chinese
2. **Custom voice commands:** User-defined shortcuts
3. **Voice reminders:** "Nhắc tôi trả tiền điện vào ngày 5"
4. **Conversation mode:** Multi-turn dialogue với AI
5. **Voice analytics:** "So sánh 3 tháng gần nhất"

---

## ✅ Checklist trước khi implement

- [ ] Fix xong các bugs hiện tại
- [ ] Test kỹ chức năng thêm giao dịch thủ công
- [ ] Có API key Gemini hợp lệ
- [ ] Device có microphone hoạt động tốt
- [ ] Network ổn định cho voice recognition

---

**Ước lượng thời gian tổng:** 8-12 giờ (bao gồm testing)

**Priority implement:**

1. Phase 1 + 2: Voice recognition + Parser (4-5h)
2. Phase 3: UI implementation (3-4h)
3. Phase 4: Gemini AI (2-3h)
4. Testing & refinement (1-2h)
