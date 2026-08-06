import '../../domain/entities/schedule_entity.dart';
import '../../domain/repositories/schedule_repository.dart';
import '../datasources/schedule_remote_data_source.dart';

/// Bridges the schedule domain contract to the remote data source.
final class ScheduleRepositoryImpl implements ScheduleRepository {
  const ScheduleRepositoryImpl(this._remoteDataSource);

  final ScheduleRemoteDataSource _remoteDataSource;

  @override
  Future<List<ScheduleEntity>> getSchedules() async {
    final models = await _remoteDataSource.getSchedules();
    return models.map((model) => model.toEntity()).toList(growable: false);
  }

  @override
  Future<List<ScheduleConflictEntity>> checkConflict({
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    String? excludeScheduleId,
  }) async {
    final models = await _remoteDataSource.checkConflict(
      dayOfWeek: dayOfWeek,
      startTime: startTime,
      endTime: endTime,
      excludeScheduleId: excludeScheduleId,
    );
    return models;
  }

  @override
  Future<ScheduleEntity> createSchedule({
    required String courseId,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    String? room,
  }) async {
    final model = await _remoteDataSource.createSchedule(
      courseId: courseId,
      dayOfWeek: dayOfWeek,
      startTime: startTime,
      endTime: endTime,
      room: room,
    );
    return model.toEntity();
  }

  @override
  Future<ScheduleEntity> updateSchedule({
    required String id,
    required String courseId,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    String? room,
  }) async {
    final model = await _remoteDataSource.updateSchedule(
      id: id,
      courseId: courseId,
      dayOfWeek: dayOfWeek,
      startTime: startTime,
      endTime: endTime,
      room: room,
    );
    return model.toEntity();
  }

  @override
  Future<void> deleteSchedule(String id) {
    return _remoteDataSource.deleteSchedule(id);
  }
}
