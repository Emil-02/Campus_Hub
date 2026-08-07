import 'package:equatable/equatable.dart';

import '../../../calendar/domain/entities/calendar_event_entity.dart';
import '../../../schedules/domain/entities/schedule_entity.dart';
import '../../../tasks/domain/entities/task_entity.dart';
import '../../domain/entities/dashboard_stats_entity.dart';

enum DashboardStatus { initial, loading, loaded, failure }

/// Immutable state for the dashboard summary.
class DashboardState extends Equatable {
  const DashboardState._({
    required this.status,
    this.todaySchedules = const [],
    this.upcomingTasks = const [],
    this.upcomingEvents = const [],
    this.stats = const DashboardStatsEntity(),
    this.errorMessage,
  });

  const DashboardState.initial() : this._(status: DashboardStatus.initial);

  const DashboardState.loading() : this._(status: DashboardStatus.loading);

  const DashboardState.loaded({
    required List<ScheduleEntity> todaySchedules,
    required List<TaskEntity> upcomingTasks,
    required DashboardStatsEntity stats,
    List<CalendarEventEntity> upcomingEvents = const [],
  }) : this._(
         status: DashboardStatus.loaded,
         todaySchedules: todaySchedules,
         upcomingTasks: upcomingTasks,
         upcomingEvents: upcomingEvents,
         stats: stats,
       );

  const DashboardState.failure(
    String message, {
    List<ScheduleEntity> todaySchedules = const [],
    List<TaskEntity> upcomingTasks = const [],
    List<CalendarEventEntity> upcomingEvents = const [],
    DashboardStatsEntity stats = const DashboardStatsEntity(),
  }) : this._(
         status: DashboardStatus.failure,
         errorMessage: message,
         todaySchedules: todaySchedules,
         upcomingTasks: upcomingTasks,
         upcomingEvents: upcomingEvents,
         stats: stats,
       );

  final DashboardStatus status;
  final List<ScheduleEntity> todaySchedules;
  final List<TaskEntity> upcomingTasks;
  final List<CalendarEventEntity> upcomingEvents;
  final DashboardStatsEntity stats;
  final String? errorMessage;

  @override
  List<Object?> get props => [
    status,
    todaySchedules,
    upcomingTasks,
    upcomingEvents,
    stats,
    errorMessage,
  ];
}
