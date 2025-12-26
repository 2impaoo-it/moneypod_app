import 'package:equatable/equatable.dart';

abstract class BillScanEvent extends Equatable {
  const BillScanEvent();

  @override
  List<Object?> get props => [];
}

/// Event: Quét bill từ camera
class ScanBillFromCamera extends BillScanEvent {
  const ScanBillFromCamera();
}

/// Event: Quét bill từ thư viện ảnh
class ScanBillFromGallery extends BillScanEvent {
  const ScanBillFromGallery();
}

/// Event: Reset lại trạng thái
class ResetBillScan extends BillScanEvent {
  const ResetBillScan();
}
