abstract class DashboardEvent {}

/// Event để load dữ liệu dashboard
class DashboardLoadRequested extends DashboardEvent {}

/// Event để refresh dữ liệu dashboard
class DashboardRefreshRequested extends DashboardEvent {}

/// Event để reset dữ liệu dashboard (khi logout)
class DashboardReset extends DashboardEvent {}
