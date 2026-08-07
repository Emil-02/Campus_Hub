// T-160: integration-style test of the full schedule flow
// create → conflict check → reminder → edit → delete,
// driven through ScheduleController against a stateful in-memory repository.
import 'package:campusmate/features/schedules/domain/entities/schedule_entity.dart';
import 'package:campusmate/features/schedules/domain/repositories/schedule_repository.dart';
import 'package:campusmate/features/schedules/presentation/providers/schedule_provider.dart';
import 'package:campusmate/features/schedules/presentation/providers/schedule_state.dart';
import 'package:campusmate/services/notification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final class RecordingNotificationService implements NotificationService {
  final scheduledIds = <String>[];
  final cancelledIds = <String>[];

  @override
  Future<bool> initialize() async => true;

  @override
  Future<void> scheduleWeeklyClassReminder({
    required String scheduleId,
    required int dayOfWeek,
    required String startTime,
    required String courseName,
    String? room,
    int minutesBefore = 30,
  }) async {
    scheduledIds.add(scheduleId);
  }

  @override
  Future<void> cancelScheduleReminder(String scheduleId) async {
    cancelledIds.add(scheduleId);
  }

  @override
  Future<void> scheduleTaskReminders({
    required String taskId,
    required String title,
    String? courseName,
    required DateTime deadline,
  }) async {}

  @override
  Future<void> cancelTaskReminders(String taskId) async {}
}

/// In-memory schedule store with real overlap detection (BR-02).
final class InMemoryScheduleRepository implements ScheduleRepository {
  final _schedules = <String, ScheduleEntity>{};
  var _seq = 0;

  @override
  Future<List<ScheduleEntity>> getSchedules() async {
    final schedules = _schedules.values.toList()
      ..sort((a, b) {
        final byDay = a.dayOfWeek.compareTo(b.dayOfWeek);
        return byDay != 0 ? byDay : a.startTime.compareTo(b.startTime);
      });
    return schedules;
  }

  @override
  Future<List<ScheduleConflictEntity>> checkConflict({
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    String? excludeScheduleId,
  }) async {
    return [
      for (final schedule in _schedules.values)
        if (schedule.id != excludeScheduleId &&
            schedule.dayOfWeek == dayOfWeek &&
            startTime.compareTo(schedule.endTime) < 0 &&
            schedule.startTime.compareTo(endTime) < 0)
          ScheduleConflictEntity(
            scheduleId: schedule.id,
            courseName: 'Mata kuliah ${schedule.courseId}',
            startTime: schedule.startTime,
            endTime: schedule.endTime,
          ),
    ];
  }

  @override
  Future<ScheduleEntity> createSchedule({
    required String courseId,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    String? room,
  }) async {
    final schedule = ScheduleEntity(
      id: 'schedule-${++_seq}',
      courseId: courseId,
      dayOfWeek: dayOfWeek,
      startTime: startTime,
      endTime: endTime,
      room: room,
    );
    _schedules[schedule.id] = schedule;
    return schedule;
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
    final updated = ScheduleEntity(
      id: id,
      courseId: courseId,
      dayOfWeek: dayOfWeek,
      startTime: startTime,
      endTime: endTime,
      room: room,
    );
    _schedules[id] = updated;
    return updated;
  }

  @override
  Future<void> deleteSchedule(String id) async {
    _schedules.remove(id);
  }
}

void main() {
  late InMemoryScheduleRepository repository;
  late RecordingNotificationService notifications;
  late ProviderContainer container;

  setUp(() {
    repository = InMemoryScheduleRepository();
    notifications = RecordingNotificationService();
    container = ProviderContainer(
      overrides: [
        scheduleRepositoryProvider.overrideWithValue(repository),
        notificationServiceProvider.overrideWithValue(notifications),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('full flow: create → conflict → reminder → edit → delete', () async {
    final controller = container.read(scheduleControllerProvider.notifier);

    await controller.loadSchedules();
    expect(container.read(scheduleControllerProvider).schedules, isEmpty);

    // Create the Monday morning class.
    final created = await controller.createSchedule(
      courseId: 'course-1',
      dayOfWeek: 1,
      startTime: '08:00',
      endTime: '09:40',
      room: 'R. 3.2',
    );
    expect(created, isTrue);
    var state = container.read(scheduleControllerProvider);
    expect(state.schedules, hasLength(1));
    final schedule = state.schedules.single;
    // A weekly reminder is registered on create.
    expect(notifications.scheduledIds, contains(schedule.id));

    // BR-02: an overlapping Monday slot is reported as a conflict.
    final conflicts = await controller.checkConflict(
      dayOfWeek: 1,
      startTime: '09:00',
      endTime: '10:40',
    );
    expect(conflicts, hasLength(1));
    expect(conflicts.single.scheduleId, schedule.id);

    // A non-overlapping slot on another day is free.
    expect(
      await controller.checkConflict(
        dayOfWeek: 2,
        startTime: '08:00',
        endTime: '09:40',
      ),
      isEmpty,
    );

    // The schedule itself is excluded when editing its own slot.
    expect(
      await controller.checkConflict(
        dayOfWeek: 1,
        startTime: '08:00',
        endTime: '09:40',
        excludeScheduleId: schedule.id,
      ),
      isEmpty,
    );

    // Edit: move the class to Tuesday and re-register the reminder.
    notifications.scheduledIds.clear();
    final updated = await controller.updateSchedule(
      id: schedule.id,
      courseId: 'course-1',
      dayOfWeek: 2,
      startTime: '13:00',
      endTime: '14:40',
      room: 'Lab 2',
    );
    expect(updated, isTrue);
    state = container.read(scheduleControllerProvider);
    expect(state.schedules.single.dayOfWeek, 2);
    expect(state.schedules.single.room, 'Lab 2');
    expect(notifications.scheduledIds, contains(schedule.id));

    // Delete: list empties and the reminder is cancelled.
    final deleted = await controller.deleteSchedule(schedule.id);
    expect(deleted, isTrue);
    expect(
      container.read(scheduleControllerProvider),
      const ScheduleState.loaded([]),
    );
    expect(notifications.cancelledIds, contains(schedule.id));
  });

  test('two classes on the same day without overlap never conflict', () async {
    final controller = container.read(scheduleControllerProvider.notifier);
    await controller.loadSchedules();

    await controller.createSchedule(
      courseId: 'course-1',
      dayOfWeek: 4,
      startTime: '08:00',
      endTime: '09:40',
    );
    // Back-to-back slot starting exactly at the previous end time.
    expect(
      await controller.checkConflict(
        dayOfWeek: 4,
        startTime: '09:40',
        endTime: '11:20',
      ),
      isEmpty,
    );

    final created = await controller.createSchedule(
      courseId: 'course-2',
      dayOfWeek: 4,
      startTime: '09:40',
      endTime: '11:20',
    );
    expect(created, isTrue);
    expect(container.read(scheduleControllerProvider).schedules, hasLength(2));
  });
}
