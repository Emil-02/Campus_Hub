import 'package:equatable/equatable.dart';

import '../../../courses/domain/entities/course_entity.dart';

/// A weekly class schedule entry with its course.
class ScheduleEntity extends Equatable {
  const ScheduleEntity({
    required this.id,
    required this.courseId,
    this.course,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.room,
    this.isActive = true,
  });

  final String id;
  final String courseId;
  final CourseEntity? course;

  /// 1 = Senin ... 7 = Minggu.
  final int dayOfWeek;

  /// Time in `HH:mm` (24-hour).
  final String startTime;
  final String endTime;
  final String? room;
  final bool isActive;

  @override
  List<Object?> get props => [
    id,
    courseId,
    course,
    dayOfWeek,
    startTime,
    endTime,
    room,
    isActive,
  ];
}

/// A schedule that overlaps with a proposed time slot.
class ScheduleConflictEntity extends Equatable {
  const ScheduleConflictEntity({
    required this.scheduleId,
    required this.courseName,
    required this.startTime,
    required this.endTime,
  });

  final String scheduleId;
  final String courseName;
  final String startTime;
  final String endTime;

  @override
  List<Object?> get props => [scheduleId, courseName, startTime, endTime];
}
