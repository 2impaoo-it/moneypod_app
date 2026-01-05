import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moneypod/screens/voice_assistant_screen.dart';
import 'package:moneypod/services/voice_service.dart';

class MockVoiceService extends Mock implements VoiceService {}

void main() {
  late MockVoiceService mockVoiceService;

  setUp(() {
    mockVoiceService = MockVoiceService();
    when(() => mockVoiceService.initialize()).thenAnswer((_) async => true);
    when(
      () => mockVoiceService.startListening(
        onResult: any(named: 'onResult'),
        onListeningStarted: any(named: 'onListeningStarted'),
        onListeningStopped: any(named: 'onListeningStopped'),
      ),
    ).thenAnswer((_) async {});
    when(() => mockVoiceService.dispose()).thenAnswer((_) {});
  });

  testWidgets('VoiceAssistantScreen builds and inits', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VoiceAssistantScreen(voiceService: mockVoiceService),
        ),
      ),
    );

    expect(find.byType(VoiceAssistantScreen), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Nhấn để nói'), findsOneWidget); // Status text
    verify(() => mockVoiceService.initialize()).called(1);
  });
}
