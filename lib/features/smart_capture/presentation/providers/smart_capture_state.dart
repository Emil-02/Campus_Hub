import 'package:equatable/equatable.dart';

import '../../../courses/domain/entities/course_entity.dart';
import '../../domain/entities/captured_item_entity.dart';

enum SmartCaptureStatus { idle, analyzing, review, saving, failure }

/// One editable review row for a captured task/event.
class SmartCaptureRow extends Equatable {
  const SmartCaptureRow({
    required this.kind,
    required this.title,
    this.description,
    this.date,
    this.time,
    this.courseId,
    this.selected = true,
  });

  final CapturedItemKind kind;
  final String title;
  final String? description;
  final DateTime? date;
  final String? time;
  final String? courseId;
  final bool selected;

  static const _unset = Object();

  SmartCaptureRow copyWith({
    CapturedItemKind? kind,
    String? title,
    bool? selected,
    Object? date = _unset,
    Object? time = _unset,
    Object? courseId = _unset,
  }) {
    return SmartCaptureRow(
      kind: kind ?? this.kind,
      title: title ?? this.title,
      description: description,
      date: date == _unset ? this.date : date as DateTime?,
      time: time == _unset ? this.time : time as String?,
      courseId: courseId == _unset ? this.courseId : courseId as String?,
      selected: selected ?? this.selected,
    );
  }

  @override
  List<Object?> get props => [
    kind,
    title,
    description,
    date,
    time,
    courseId,
    selected,
  ];
}

/// Immutable state for the smart-capture flow.
class SmartCaptureState extends Equatable {
  const SmartCaptureState._({
    required this.status,
    this.rows = const [],
    this.courses = const [],
    this.errorMessage,
    this.savedTasks = 0,
    this.savedEvents = 0,
  });

  const SmartCaptureState.idle() : this._(status: SmartCaptureStatus.idle);

  const SmartCaptureState.analyzing()
    : this._(status: SmartCaptureStatus.analyzing);

  const SmartCaptureState.review(
    List<SmartCaptureRow> rows, {
    List<CourseEntity> courses = const [],
  }) : this._(status: SmartCaptureStatus.review, rows: rows, courses: courses);

  const SmartCaptureState.saving(
    List<SmartCaptureRow> rows, {
    List<CourseEntity> courses = const [],
  }) : this._(status: SmartCaptureStatus.saving, rows: rows, courses: courses);

  const SmartCaptureState.failure(String message)
    : this._(status: SmartCaptureStatus.failure, errorMessage: message);

  const SmartCaptureState.done({
    required int savedTasks,
    required int savedEvents,
  }) : this._(
         status: SmartCaptureStatus.idle,
         savedTasks: savedTasks,
         savedEvents: savedEvents,
       );

  final SmartCaptureStatus status;
  final List<SmartCaptureRow> rows;

  /// User's courses for the course picker in review.
  final List<CourseEntity> courses;
  final String? errorMessage;
  final int savedTasks;
  final int savedEvents;

  int get selectedCount => rows.where((row) => row.selected).length;

  @override
  List<Object?> get props => [
    status,
    rows,
    courses,
    errorMessage,
    savedTasks,
    savedEvents,
  ];
}
