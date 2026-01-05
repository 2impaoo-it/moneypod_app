import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:moneypod/repositories/bill_scan_repository.dart';
import 'package:moneypod/services/auth_service.dart';

class MockDio extends Mock implements Dio {}

class MockAuthService extends Mock implements AuthService {}

class MockImagePicker extends Mock implements ImagePicker {}

void main() {
  late MockDio mockDio;
  late MockAuthService mockAuthService;
  late MockImagePicker mockImagePicker;
  late BillScanRepository repository;

  setUp(() {
    mockDio = MockDio();
    mockAuthService = MockAuthService();
    mockImagePicker = MockImagePicker();
    repository = BillScanRepository(
      dio: mockDio,
      authService: mockAuthService,
      imagePicker: mockImagePicker,
    );
  });

  group('BillScanRepository', () {
    test('scanBill sends correct request', () async {
      // Create a dummy file for testing
      final file = File('test_image.jpg');
      await file.writeAsBytes([0, 1, 2, 3]);
      addTearDown(() async {
        if (await file.exists()) {
          await file.delete();
        }
      });

      when(() => mockAuthService.getToken()).thenAnswer((_) async => 'token');
      when(
        () => mockDio.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/scan-receipt'),
          statusCode: 200,
          data: {
            'data': {
              'merchant': 'Test Store',
              'amount': 100000,
              'date': '2023-10-27T10:00:00Z',
              'category': 'Food',
            },
          },
        ),
      );

      final result = await repository.scanBill(file);

      expect(result.merchant, 'Test Store');
      expect(result.amount, 100000.0);
      verify(
        () => mockDio.post(
          '/scan-receipt',
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).called(1);
    });
  });
}
