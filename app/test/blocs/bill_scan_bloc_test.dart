import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moneypod/bloc/bill_scan/bill_scan_bloc.dart';
import 'package:moneypod/bloc/bill_scan/bill_scan_event.dart';
import 'package:moneypod/bloc/bill_scan/bill_scan_state.dart';
import 'package:moneypod/repositories/bill_scan_repository.dart';
import 'package:moneypod/models/bill_scan_result.dart';

class MockBillScanRepository extends Mock implements BillScanRepository {}

void main() {
  late MockBillScanRepository mockRepository;

  setUp(() {
    mockRepository = MockBillScanRepository();
  });

  group('BillScanBloc', () {
    final mockResult = BillScanResult(
      merchant: 'Test Store',
      amount: 100000,
      date: DateTime.now(),
      category: 'Food',
    );

    blocTest<BillScanBloc, BillScanState>(
      'emits [Loading, Success] when ScanBillFromCamera is added and scanner succeeds',
      build: () {
        when(
          () => mockRepository.scanBillFromCamera(),
        ).thenAnswer((_) async => mockResult);
        return BillScanBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const ScanBillFromCamera()),
      expect: () => [const BillScanLoading(), BillScanSuccess(mockResult)],
    );

    blocTest<BillScanBloc, BillScanState>(
      'emits [Loading, Failure] when ScanBillFromCamera fails',
      build: () {
        when(
          () => mockRepository.scanBillFromCamera(),
        ).thenThrow(Exception('Camera error'));
        return BillScanBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const ScanBillFromCamera()),
      expect: () => [
        const BillScanLoading(),
        isA<BillScanFailure>().having(
          (s) => s.error,
          'error',
          contains('Có lỗi xảy ra'),
        ),
      ],
    );

    blocTest<BillScanBloc, BillScanState>(
      'emits [Loading, Success] when ScanBillFromGallery succeeds',
      build: () {
        when(
          () => mockRepository.scanBillFromGallery(),
        ).thenAnswer((_) async => mockResult);
        return BillScanBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const ScanBillFromGallery()),
      expect: () => [const BillScanLoading(), BillScanSuccess(mockResult)],
    );

    blocTest<BillScanBloc, BillScanState>(
      'emits [Loading, Failure] with generic error when ScanBillFromGallery fails',
      build: () {
        when(
          () => mockRepository.scanBillFromGallery(),
        ).thenThrow(Exception('Unknown'));
        return BillScanBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const ScanBillFromGallery()),
      expect: () => [
        const BillScanLoading(),
        isA<BillScanFailure>().having(
          (s) => s.error,
          'error',
          contains('Có lỗi xảy ra'),
        ),
      ],
    );

    blocTest<BillScanBloc, BillScanState>(
      'emits [Loading, Failure] with specific error when ScanBillFromGallery fails with "Không có ảnh"',
      build: () {
        when(
          () => mockRepository.scanBillFromGallery(),
        ).thenThrow(Exception('Không có ảnh'));
        return BillScanBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const ScanBillFromGallery()),
      expect: () => [
        const BillScanLoading(),
        isA<BillScanFailure>().having(
          (s) => s.error,
          'error',
          'Bạn chưa chọn ảnh nào.',
        ),
      ],
    );

    blocTest<BillScanBloc, BillScanState>(
      'emits [Initial] when ResetBillScan is added',
      build: () => BillScanBloc(repository: mockRepository),
      seed: () => BillScanSuccess(mockResult),
      act: (bloc) => bloc.add(const ResetBillScan()),
      expect: () => [const BillScanInitial()],
    );
  });
}
