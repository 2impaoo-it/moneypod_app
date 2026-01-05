import 'package:flutter_test/flutter_test.dart';
import 'package:moneypod/services/voice_service.dart';

// Note: VoiceService uses SpeechToText and FlutterTts which require platform channels.
// These tests verify class structure without platform dependencies.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late VoiceService voiceService;

  setUp(() {
    voiceService = VoiceService();
  });

  group('VoiceService', () {
    test('instance can be created', () {
      expect(voiceService, isA<VoiceService>());
    });

    test('isListening is false initially', () {
      expect(voiceService.isListening, isFalse);
    });

    test('isInitialized is false initially', () {
      expect(voiceService.isInitialized, isFalse);
    });

    test('dispose does not throw', () {
      expect(() => voiceService.dispose(), returnsNormally);
    });

    // Note: initialize(), startListening(), speak() require platform mocks
    // and would need integration tests or platform channel stubbing.
  });
}
