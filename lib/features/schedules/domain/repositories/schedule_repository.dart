import '../entities/schedule_entity.dart';

/// Contract for schedule data operations.
abstract interface class ScheduleRepository {
  /// Returns all active schedules ordered by day and start time.
  Future<List<ScheduleEntity>> getSchedules();

  /// Returns schedules overlapping the proposed slot.
  Future<List<ScheduleConflictEntity>> checkConflict({
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    String? excludeScheduleId,
  });

  Future<ScheduleEntity> createSchedule({
    required String courseId,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    String? room,
  });

  Future<ScheduleEntity> updateSchedule({
    required String id,
    required String courseId,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    String? room,
  });

  Future<void> deleteSchedule(String id);
}
