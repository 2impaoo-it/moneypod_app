import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moneypod/bloc/bill_scan/bill_scan_bloc.dart';
import 'package:moneypod/bloc/bill_scan/bill_scan_event.dart';
import 'package:moneypod/bloc/bill_scan/bill_scan_state.dart';
import 'package:moneypod/models/bill_scan_result.dart';
import '../../mocks/repositories.dart';

void main() {
  late MockBillScanRepository mockRepository;

  final mockResult = BillScanResult(
    merchant: 'Test Store',
    amount: 100000,
    date: DateTime.now(),
    category: 'Food',
    note: 'Test note',
  );

  setUp(() {
    mockRepository = MockBillScanRepository();
  });

  group('BillScanBloc', () {
    test('initial state is BillScanInitial', () {
      expect(
        BillScanBloc(repository: mockRepository).state,
        const BillScanInitial(),
      );
    });

    blocTest<BillScanBloc, BillScanState>(
      'emits [BillScanLoading, BillScanSuccess] when ScanBillFromCamera succeeds',
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
      'emits [BillScanLoading, BillScanFailure] when ScanBillFromCamera fails',
      build: () {
        when(
          () => mockRepository.scanBillFromCamera(),
        ).thenThrow(Exception('Camera error'));
        return BillScanBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const ScanBillFromCamera()),
      expect: () => [const BillScanLoading(), isA<BillScanFailure>()],
    );

    blocTest<BillScanBloc, BillScanState>(
      'emits [BillScanLoading, BillScanSuccess] when ScanBillFromGallery succeeds',
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
      'emits [BillScanLoading, BillScanFailure] when ScanBillFromGallery fails',
      build: () {
        when(
          () => mockRepository.scanBillFromGallery(),
        ).thenThrow(Exception('Gallery error'));
        return BillScanBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const ScanBillFromGallery()),
      expect: () => [const BillScanLoading(), isA<BillScanFailure>()],
    );

    blocTest<BillScanBloc, BillScanState>(
      'emits [BillScanInitial] when ResetBillScan is added',
      build: () => BillScanBloc(repository: mockRepository),
      seed: () => BillScanSuccess(mockResult),
      act: (bloc) => bloc.add(const ResetBillScan()),
      expect: () => [const BillScanInitial()],
    );
  });
}
