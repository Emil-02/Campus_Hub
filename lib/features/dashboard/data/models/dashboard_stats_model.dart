import '../../domain/entities/dashboard_stats_entity.dart';

final class DashboardStatsModel extends DashboardStatsEntity {
  const DashboardStatsModel({
    super.totalActive,
    super.completedTotal,
    super.completedThisWeek,
    super.overdue,
  });

  /// Parses the JSON returned by the `get_task_statistics` RPC.
  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return DashboardStatsModel(
      totalActive: _intOrZero(json['total_active']),
      completedTotal: _intOrZero(json['completed_total']),
      completedThisWeek: _intOrZero(json['completed_this_week']),
      overdue: _intOrZero(json['overdue']),
    );
  }

  DashboardStatsEntity toEntity() {
    return DashboardStatsEntity(
      totalActive: totalActive,
      completedTotal: completedTotal,
      completedThisWeek: completedThisWeek,
      overdue: overdue,
    );
  }

  static int _intOrZero(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return 0;
  }
}
