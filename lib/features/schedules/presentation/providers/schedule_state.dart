import 'package:equatable/equatable.dart';

import '../../domain/entities/schedule_entity.dart';

enum ScheduleStatus { initial, loading, loaded, failure }

/// Immutable state for the weekly schedule list.
class ScheduleState extends Equatable {
  const ScheduleState._({
    required this.status,
    this.schedules = const [],
    this.errorMessage,
    this.isMutating = false,
  });

  const ScheduleState.initial() : this._(status: ScheduleStatus.initial);

  const ScheduleState.loading() : this._(status: ScheduleStatus.loading);

  const ScheduleState.loaded(
    List<ScheduleEntity> schedules, {
    bool isMutating = false,
  }) : this._(
         status: ScheduleStatus.loaded,
         schedules: schedules,
         isMutating: isMutating,
       );

  const ScheduleState.failure(
    String message, {
    List<ScheduleEntity> schedules = const [],
  }) : this._(
         status: ScheduleStatus.failure,
         errorMessage: message,
         schedules: schedules,
       );

  final ScheduleStatus status;
  final List<ScheduleEntity> schedules;
  final String? errorMessage;

  /// True while a create/update/delete request is in flight.
  final bool isMutating;

  /// Schedules grouped per day (1=Senin..7=Minggu), preserving order.
  Map<int, List<ScheduleEntity>> get byDay {
    final grouped = <int, List<ScheduleEntity>>{};
    for (final schedule in schedules) {
      grouped.putIfAbsent(schedule.dayOfWeek, () => []).add(schedule);
    }
    return grouped;
  }

  @override
  List<Object?> get props => [status, schedules, errorMessage, isMutating];
}
