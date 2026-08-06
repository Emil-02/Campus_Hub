import '../../../courses/data/models/course_model.dart';
import '../../domain/entities/schedule_entity.dart';

final class ScheduleModel extends ScheduleEntity {
  const ScheduleModel({
    required super.id,
    required super.courseId,
    super.course,
    required super.dayOfWeek,
    required super.startTime,
    required super.endTime,
    super.room,
    super.isActive,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    final courseJson = json['courses'];
    return ScheduleModel(
      id: _requiredString(json, 'id'),
      courseId: _requiredString(json, 'course_id'),
      course: courseJson is Map<String, dynamic>
          ? CourseModel.fromJson(courseJson)
          : null,
      dayOfWeek: _requiredInt(json, 'day_of_week'),
      startTime: _time(json, 'start_time'),
      endTime: _time(json, 'end_time'),
      room: _nullableString(json, 'room'),
      isActive: json['is_active'] is bool ? json['is_active'] as bool : true,
    );
  }

  ScheduleEntity toEntity() => this;

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('ScheduleModel "$key" must be a non-empty String.');
    }
    return value;
  }

  static int _requiredInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    throw FormatException('ScheduleModel "$key" must be an int.');
  }

  /// Normalizes Postgres `HH:mm:ss` to `HH:mm`.
  static String _time(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String || value.length < 5) {
      throw FormatException('ScheduleModel "$key" must be a time String.');
    }
    return value.substring(0, 5);
  }

  static String? _nullableString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) {
      return null;
    }
    if (value is! String) {
      throw FormatException('ScheduleModel "$key" must be a String or null.');
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

final class ScheduleConflictModel extends ScheduleConflictEntity {
  const ScheduleConflictModel({
    required super.scheduleId,
    required super.courseName,
    required super.startTime,
    required super.endTime,
  });

  factory ScheduleConflictModel.fromJson(Map<String, dynamic> json) {
    return ScheduleConflictModel(
      scheduleId: json['conflicting_id'] as String? ?? '',
      courseName: json['course_name'] as String? ?? '',
      startTime: _clip(json['start_time']),
      endTime: _clip(json['end_time']),
    );
  }

  static String _clip(Object? value) {
    if (value is String && value.length >= 5) {
      return value.substring(0, 5);
    }
    return value?.toString() ?? '';
  }
}
