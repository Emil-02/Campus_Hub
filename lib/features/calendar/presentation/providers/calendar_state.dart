import 'package:equatable/equatable.dart';

import '../../../tasks/domain/entities/task_entity.dart';
import '../../domain/entities/calendar_event_entity.dart';

enum CalendarStatus { initial, loading, loaded, failure }

/// Immutable state for the monthly calendar view.
class CalendarState extends Equatable {
  const CalendarState._({
    required this.status,
    required this.focusedMonth,
    this.events = const [],
    this.deadlineTasks = const [],
    this.errorMessage,
  });

  CalendarState.initial()
    : this._(status: CalendarStatus.initial, focusedMonth: _thisMonth());

  const CalendarState.loading(DateTime focusedMonth)
    : this._(status: CalendarStatus.loading, focusedMonth: focusedMonth);

  const CalendarState.loaded({
    required DateTime focusedMonth,
    required List<CalendarEventEntity> events,
    required List<TaskEntity> deadlineTasks,
  }) : this._(
         status: CalendarStatus.loaded,
         focusedMonth: focusedMonth,
         events: events,
         deadlineTasks: deadlineTasks,
       );

  const CalendarState.failure(
    String message, {
    required DateTime focusedMonth,
    List<CalendarEventEntity> events = const [],
    List<TaskEntity> deadlineTasks = const [],
  }) : this._(
         status: CalendarStatus.failure,
         focusedMonth: focusedMonth,
         events: events,
         deadlineTasks: deadlineTasks,
         errorMessage: message,
       );

  final CalendarStatus status;

  /// First day of the visible month.
  final DateTime focusedMonth;
  final List<CalendarEventEntity> events;

  /// Tasks whose deadline falls inside the visible month (CAL-04).
  final List<TaskEntity> deadlineTasks;
  final String? errorMessage;

  static DateTime _thisMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  /// Events on one calendar day.
  List<CalendarEventEntity> eventsOn(DateTime day) {
    return events
        .where(
          (event) =>
              event.eventDate.year == day.year &&
              event.eventDate.month == day.month &&
              event.eventDate.day == day.day,
        )
        .toList(growable: false);
  }

  /// Deadline tasks on one calendar day.
  List<TaskEntity> tasksOn(DateTime day) {
    return deadlineTasks
        .where(
          (task) =>
              task.deadline != null &&
              task.deadline!.year == day.year &&
              task.deadline!.month == day.month &&
              task.deadline!.day == day.day,
        )
        .toList(growable: false);
  }

  /// Total markers on one day, for the dot indicator.
  int markerCount(DateTime day) => eventsOn(day).length + tasksOn(day).length;

  @override
  List<Object?> get props => [
    status,
    focusedMonth,
    events,
    deadlineTasks,
    errorMessage,
  ];
}
