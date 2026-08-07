import 'package:equatable/equatable.dart';

/// One class meeting slot read from a KRS photo.
class ImportedMeetingEntity extends Equatable {
  const ImportedMeetingEntity({
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.room,
  });

  /// 1 = Senin ... 7 = Minggu.
  final int dayOfWeek;

  /// Time in `HH:mm` (24-hour).
  final String startTime;
  final String endTime;
  final String? room;

  @override
  List<Object?> get props => [dayOfWeek, startTime, endTime, room];
}

/// One course row read from a KRS photo.
class ImportedCourseEntity extends Equatable {
  const ImportedCourseEntity({
    required this.name,
    this.code,
    this.credits,
    this.lecturer,
    this.meetings = const [],
  });

  final String name;
  final String? code;
  final int? credits;
  final String? lecturer;
  final List<ImportedMeetingEntity> meetings;

  @override
  List<Object?> get props => [name, code, credits, lecturer, meetings];
}
