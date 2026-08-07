import 'package:equatable/equatable.dart';

/// Aggregated task statistics for the dashboard (T-142).
class DashboardStatsEntity extends Equatable {
  const DashboardStatsEntity({
    this.totalActive = 0,
    this.completedTotal = 0,
    this.completedThisWeek = 0,
    this.overdue = 0,
  });

  final int totalActive;
  final int completedTotal;
  final int completedThisWeek;
  final int overdue;

  int get totalTasks => totalActive + completedTotal;

  /// 0..1 share of completed tasks; 0 when there are none.
  double get completionRate =>
      totalTasks == 0 ? 0 : completedTotal / totalTasks;

  @override
  List<Object?> get props => [
    totalActive,
    completedTotal,
    completedThisWeek,
    overdue,
  ];
}
