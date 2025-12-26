import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/bill_scan_repository.dart';
import 'bill_scan_event.dart';
import 'bill_scan_state.dart';

class BillScanBloc extends Bloc<BillScanEvent, BillScanState> {
  final BillScanRepository repository;

  BillScanBloc({required this.repository}) : super(const BillScanInitial()) {
    on<ScanBillFromCamera>(_onScanBillFromCamera);
    on<ScanBillFromGallery>(_onScanBillFromGallery);
    on<ResetBillScan>(_onResetBillScan);
  }

  /// Xử lý event quét bill từ camera
  Future<void> _onScanBillFromCamera(
    ScanBillFromCamera event,
    Emitter<BillScanState> emit,
  ) async {
    emit(const BillScanLoading());
    try {
      final result = await repository.scanBillFromCamera();
      emit(BillScanSuccess(result));
    } catch (e) {
      emit(BillScanFailure(_getErrorMessage(e)));
    }
  }

  /// Xử lý event quét bill từ thư viện ảnh
  Future<void> _onScanBillFromGallery(
    ScanBillFromGallery event,
    Emitter<BillScanState> emit,
  ) async {
    emit(const BillScanLoading());
    try {
      final result = await repository.scanBillFromGallery();
      emit(BillScanSuccess(result));
    } catch (e) {
      emit(BillScanFailure(_getErrorMessage(e)));
    }
  }

  /// Xử lý event reset
  Future<void> _onResetBillScan(
    ResetBillScan event,
    Emitter<BillScanState> emit,
  ) async {
    emit(const BillScanInitial());
  }

  /// Lấy thông báo lỗi thân thiện
  String _getErrorMessage(dynamic error) {
    final errorString = error.toString();

    if (errorString.contains('camera')) {
      return 'Không thể truy cập camera. Vui lòng kiểm tra quyền truy cập.';
    } else if (errorString.contains('Không có ảnh')) {
      return 'Bạn chưa chọn ảnh nào.';
    } else if (errorString.contains('Gemini')) {
      return 'Lỗi khi phân tích hóa đơn. Vui lòng thử lại.';
    } else if (errorString.contains('quyền')) {
      return 'Ứng dụng cần quyền truy cập camera để quét bill.';
    } else {
      return 'Có lỗi xảy ra: $errorString';
    }
  }
}
