import '../../models/dashboard_data.dart';

abstract class DashboardState {}

/// Trạng thái khởi tạo
class DashboardInitial extends DashboardState {}

/// Trạng thái đang tải dữ liệu
class DashboardLoading extends DashboardState {}

/// Trạng thái đã load thành công
class DashboardLoaded extends DashboardState {
  final DashboardData data;

  DashboardLoaded(this.data);
}

/// Trạng thái lỗi
class DashboardError extends DashboardState {
  final String message;

  DashboardError(this.message);
}
