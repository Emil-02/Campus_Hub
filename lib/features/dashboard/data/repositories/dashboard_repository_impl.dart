import '../../../calendar/domain/entities/calendar_event_entity.dart';
import '../../../schedules/domain/entities/schedule_entity.dart';
import '../../../tasks/domain/entities/task_entity.dart';
import '../../domain/entities/dashboard_stats_entity.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_remote_data_source.dart';

/// Bridges the dashboard domain contract to the remote data source.
final class DashboardRepositoryImpl implements DashboardRepository {
  const DashboardRepositoryImpl(this._remoteDataSource);

  final DashboardRemoteDataSource _remoteDataSource;

  @override
  Future<List<ScheduleEntity>> getTodaySchedules() async {
    final models = await _remoteDataSource.getTodaySchedules();
    return models.map((model) => model.toEntity()).toList(growable: false);
  }

  @override
  Future<List<TaskEntity>> getUpcomingDeadlines() async {
    final models = await _remoteDataSource.getUpcomingDeadlines();
    return models.map((model) => model.toEntity()).toList(growable: false);
  }

  @override
  Future<List<CalendarEventEntity>> getUpcomingEvents() async {
    final models = await _remoteDataSource.getUpcomingEvents();
    return models.map((model) => model.toEntity()).toList(growable: false);
  }

  @override
  Future<DashboardStatsEntity> getStatistics() async {
    final model = await _remoteDataSource.getStatistics();
    return model.toEntity();
  }
}
