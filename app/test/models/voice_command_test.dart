import 'package:flutter_test/flutter_test.dart';
import 'package:moneypod/models/voice_command.dart';

void main() {
  group('VoiceCommand Model Test', () {
    test('toString returns correct description for expense', () {
      final cmd = VoiceCommand(
        type: 'expense',
        amount: 50000,
        category: 'Food',
        note: 'Lunch',
      );

      // formatAmount: 50000 -> 50 nghìn
      expect(cmd.toString(), 'Chi 50 nghìn cho Food - Lunch');
    });

    test('toString returns correct description for income', () {
      final cmd = VoiceCommand(
        type: 'income',
        amount: 1500000,
        category: 'Salary',
      );

      // formatAmount: 1500000 -> 1.5 triệu
      expect(cmd.toString(), 'Thu nhập 1.5 triệu từ Salary');
    });

    test('summary returns correct brief', () {
      final cmd = VoiceCommand(
        type: 'expense',
        amount: 100000,
        category: 'Shopping',
      );

      expect(cmd.summary, 'Chi tiêu: 100 nghìnđ - Shopping');
    });
  });
}
