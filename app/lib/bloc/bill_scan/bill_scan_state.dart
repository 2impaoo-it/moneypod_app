import 'package:equatable/equatable.dart';
import '../../models/bill_scan_result.dart';

abstract class BillScanState extends Equatable {
  const BillScanState();

  @override
  List<Object?> get props => [];
}

/// State: Trạng thái ban đầu
class BillScanInitial extends BillScanState {
  const BillScanInitial();
}

/// State: Đang quét bill (loading)
class BillScanLoading extends BillScanState {
  const BillScanLoading();
}

/// State: Quét bill thành công
class BillScanSuccess extends BillScanState {
  final BillScanResult result;

  const BillScanSuccess(this.result);

  @override
  List<Object?> get props => [result];
}

/// State: Quét bill thất bại
class BillScanFailure extends BillScanState {
  final String error;

  const BillScanFailure(this.error);

  @override
  List<Object?> get props => [error];
}
