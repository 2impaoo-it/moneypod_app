import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:moneypod/services/biometric_service.dart';

class MockLocalAuthentication extends Mock implements LocalAuthentication {}

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockLocalAuthentication mockAuth;
  late MockFlutterSecureStorage mockStorage;
  late BiometricService biometricService;

  setUp(() {
    mockAuth = MockLocalAuthentication();
    mockStorage = MockFlutterSecureStorage();
    biometricService = BiometricService(auth: mockAuth, storage: mockStorage);
  });

  group('BiometricService', () {
    test('can be instantiated with DI', () {
      expect(biometricService, isA<BiometricService>());
    });

    test('can be instantiated without DI (default)', () {
      final service = BiometricService();
      expect(service, isA<BiometricService>());
    });
  });

  group('isBiometricAvailable', () {
    test('returns true when both biometrics and device supported', () async {
      when(() => mockAuth.canCheckBiometrics).thenAnswer((_) async => true);
      when(() => mockAuth.isDeviceSupported()).thenAnswer((_) async => true);

      final result = await biometricService.isBiometricAvailable();

      expect(result, isTrue);
    });

    test('returns true when only device supported', () async {
      when(() => mockAuth.canCheckBiometrics).thenAnswer((_) async => false);
      when(() => mockAuth.isDeviceSupported()).thenAnswer((_) async => true);

      final result = await biometricService.isBiometricAvailable();

      expect(result, isTrue);
    });

    test('returns false when neither supported', () async {
      when(() => mockAuth.canCheckBiometrics).thenAnswer((_) async => false);
      when(() => mockAuth.isDeviceSupported()).thenAnswer((_) async => false);

      final result = await biometricService.isBiometricAvailable();

      expect(result, isFalse);
    });

    test('returns false on PlatformException', () async {
      when(
        () => mockAuth.canCheckBiometrics,
      ).thenThrow(PlatformException(code: 'error'));

      final result = await biometricService.isBiometricAvailable();

      expect(result, isFalse);
    });
  });

  group('getAvailableBiometrics', () {
    test('returns list of biometric types', () async {
      when(() => mockAuth.getAvailableBiometrics()).thenAnswer(
        (_) async => [BiometricType.fingerprint, BiometricType.face],
      );

      final result = await biometricService.getAvailableBiometrics();

      expect(result, hasLength(2));
      expect(result, contains(BiometricType.fingerprint));
      expect(result, contains(BiometricType.face));
    });

    test('returns empty list on PlatformException', () async {
      when(
        () => mockAuth.getAvailableBiometrics(),
      ).thenThrow(PlatformException(code: 'error'));

      final result = await biometricService.getAvailableBiometrics();

      expect(result, isEmpty);
    });
  });

  group('authenticate', () {
    test('returns true on successful authentication', () async {
      when(
        () => mockAuth.authenticate(
          localizedReason: any(named: 'localizedReason'),
        ),
      ).thenAnswer((_) async => true);

      final result = await biometricService.authenticate();

      expect(result, isTrue);
    });

    test('returns false on failed authentication', () async {
      when(
        () => mockAuth.authenticate(
          localizedReason: any(named: 'localizedReason'),
        ),
      ).thenAnswer((_) async => false);

      final result = await biometricService.authenticate();

      expect(result, isFalse);
    });

    test('returns false on exception', () async {
      when(
        () => mockAuth.authenticate(
          localizedReason: any(named: 'localizedReason'),
        ),
      ).thenThrow(Exception('Auth error'));

      final result = await biometricService.authenticate();

      expect(result, isFalse);
    });
  });

  group('getPassword', () {
    test('returns password when exists', () async {
      when(
        () => mockStorage.read(key: 'biometric_pass_test@example.com'),
      ).thenAnswer((_) async => 'secret123');

      final result = await biometricService.getPassword('test@example.com');

      expect(result, equals('secret123'));
    });

    test('returns null when password not found', () async {
      when(
        () => mockStorage.read(key: 'biometric_pass_test@example.com'),
      ).thenAnswer((_) async => null);

      final result = await biometricService.getPassword('test@example.com');

      expect(result, isNull);
    });

    // Note: getPassword doesn't catch exceptions - they propagate to caller
    // This is intended behavior for secure storage operations
  });
}
