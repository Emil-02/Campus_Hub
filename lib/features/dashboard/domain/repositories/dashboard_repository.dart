import '../../../schedules/domain/entities/schedule_entity.dart';
import '../../../tasks/domain/entities/task_entity.dart';
import '../entities/dashboard_stats_entity.dart';

/// Contract for the aggregated dashboard data (T-144).
abstract interface class DashboardRepository {
  /// Today's active schedules ordered by start time.
  Future<List<ScheduleEntity>> getTodaySchedules();

  /// Up to five nearest active deadlines from now.
  Future<List<TaskEntity>> getUpcomingDeadlines();

  /// Aggregated task statistics.
  Future<DashboardStatsEntity> getStatistics();
}
