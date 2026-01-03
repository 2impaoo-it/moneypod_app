import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service xử lý Speech-to-Text và Text-to-Speech
class VoiceService {
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _isListening = false;
  bool _isInitialized = false;

  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;

  /// Initialize speech recognition
  Future<bool> initialize() async {
    // Request microphone permission
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      return false;
    }

    // Initialize speech to text with timeout
    try {
      _isInitialized = await _speech
          .initialize(
            onError: (error) {
              print('❌ Speech error: $error');
              _isListening = false;
            },
            onStatus: (status) {
              print('🎤 Speech status: $status');
              if (status == 'done' || status == 'notListening') {
                _isListening = false;
              }
            },
          )
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              print('⏰ Speech initialization timed out');
              return false;
            },
          );
    } catch (e) {
      print('❌ Speech initialization failed: $e');
      _isInitialized = false;
    }

    // Setup TTS for Vietnamese
    if (_isInitialized) {
      try {
        await _tts.setLanguage('vi-VN');
        await _tts.setPitch(1.0);
        await _tts.setSpeechRate(0.5);
      } catch (e) {
        print('⚠️ TTS setup failed (non-critical): $e');
      }
    }

    return _isInitialized;
  }

  /// Start listening for voice input
  Future<void> startListening({
    required Function(String text, bool isFinal) onResult,
    Function()? onListeningStarted,
    Function()? onListeningStopped,
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return;
    }

    if (!_isListening) {
      _isListening = true;
      onListeningStarted?.call();

      await _speech.listen(
        onResult: (result) {
          onResult(result.recognizedWords, result.finalResult);
          if (result.finalResult) {
            _isListening = false;
            onListeningStopped?.call();
          }
        },
        localeId: 'vi_VN', // Vietnamese
        listenMode: ListenMode.confirmation,
        cancelOnError: true,
        partialResults: true,
      );
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    if (_isListening) {
      _isListening = false;
      await _speech.stop();
    }
  }

  /// Cancel listening
  Future<void> cancelListening() async {
    _isListening = false;
    await _speech.cancel();
  }

  /// Text-to-speech - đọc text
  Future<void> speak(String text) async {
    await _tts.speak(text);
  }

  /// Dừng đọc
  Future<void> stopSpeaking() async {
    await _tts.stop();
  }

  /// Lấy danh sách locales có sẵn
  Future<List<dynamic>> getAvailableLocales() async {
    return await _speech.locales();
  }

  /// Dispose resources
  void dispose() {
    _speech.stop();
    _tts.stop();
  }
}
