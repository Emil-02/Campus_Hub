import 'package:campusmate/features/schedules/domain/entities/schedule_entity.dart';
import 'package:campusmate/features/schedules/domain/repositories/schedule_repository.dart';
import 'package:campusmate/features/schedules/presentation/providers/schedule_provider.dart';
import 'package:campusmate/features/schedules/presentation/providers/schedule_state.dart';
import 'package:campusmate/services/notification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockScheduleRepository extends Mock implements ScheduleRepository {}

final class FakeNotificationService implements NotificationService {
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

void main() {
  late MockScheduleRepository repository;
  late FakeNotificationService notifications;
  late ProviderContainer container;

  const mondaySchedule = ScheduleEntity(
    id: 'schedule-1',
    courseId: 'course-1',
    dayOfWeek: 1,
    startTime: '08:00',
    endTime: '09:40',
    room: 'R. 3.2',
  );
  const wednesdaySchedule = ScheduleEntity(
    id: 'schedule-2',
    courseId: 'course-2',
    dayOfWeek: 3,
    startTime: '10:00',
    endTime: '11:40',
  );

  setUp(() {
    repository = MockScheduleRepository();
    notifications = FakeNotificationService();
    container = ProviderContainer(
      overrides: [
        scheduleRepositoryProvider.overrideWithValue(repository),
        notificationServiceProvider.overrideWithValue(notifications),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('loadSchedules exposes the loaded list', () async {
    when(
      () => repository.getSchedules(),
    ).thenAnswer((_) async => [mondaySchedule, wednesdaySchedule]);

    await container.read(scheduleControllerProvider.notifier).loadSchedules();

    expect(
      container.read(scheduleControllerProvider),
      const ScheduleState.loaded([mondaySchedule, wednesdaySchedule]),
    );
  });

  test('byDay groups schedules per weekday', () async {
    when(
      () => repository.getSchedules(),
    ).thenAnswer((_) async => [mondaySchedule, wednesdaySchedule]);

    await container.read(scheduleControllerProvider.notifier).loadSchedules();

    final byDay = container.read(scheduleControllerProvider).byDay;
    expect(byDay[1], [mondaySchedule]);
    expect(byDay[3], [wednesdaySchedule]);
    expect(byDay.containsKey(2), isFalse);
  });

  test('loadSchedules surfaces a safe failure message', () async {
    when(() => repository.getSchedules()).thenThrow(StateError('no session'));

    await container.read(scheduleControllerProvider.notifier).loadSchedules();

    final state = container.read(scheduleControllerProvider);
    expect(state.status, ScheduleStatus.failure);
    expect(state.errorMessage, 'Sesi tidak valid. Silakan login ulang.');
  });

  test('checkConflict returns overlaps from the repository', () async {
    const conflict = ScheduleConflictEntity(
      scheduleId: 'schedule-9',
      courseName: 'Basis Data',
      startTime: '08:30',
      endTime: '10:00',
    );
    when(
      () => repository.checkConflict(
        dayOfWeek: any(named: 'dayOfWeek'),
        startTime: any(named: 'startTime'),
        endTime: any(named: 'endTime'),
        excludeScheduleId: any(named: 'excludeScheduleId'),
      ),
    ).thenAnswer((_) async => [conflict]);

    final conflicts = await container
        .read(scheduleControllerProvider.notifier)
        .checkConflict(dayOfWeek: 1, startTime: '08:00', endTime: '09:40');

    expect(conflicts, [conflict]);
  });

  test('checkConflict swallows errors into an empty list', () async {
    when(
      () => repository.checkConflict(
        dayOfWeek: any(named: 'dayOfWeek'),
        startTime: any(named: 'startTime'),
        endTime: any(named: 'endTime'),
        excludeScheduleId: any(named: 'excludeScheduleId'),
      ),
    ).thenThrow(StateError('rpc missing'));

    final conflicts = await container
        .read(scheduleControllerProvider.notifier)
        .checkConflict(dayOfWeek: 1, startTime: '08:00', endTime: '09:40');

    expect(conflicts, isEmpty);
  });

  test('createSchedule reloads the list and returns true', () async {
    when(
      () => repository.createSchedule(
        courseId: any(named: 'courseId'),
        dayOfWeek: any(named: 'dayOfWeek'),
        startTime: any(named: 'startTime'),
        endTime: any(named: 'endTime'),
        room: any(named: 'room'),
      ),
    ).thenAnswer((_) async => mondaySchedule);
    when(
      () => repository.getSchedules(),
    ).thenAnswer((_) async => [mondaySchedule]);

    final saved = await container
        .read(scheduleControllerProvider.notifier)
        .createSchedule(
          courseId: 'course-1',
          dayOfWeek: 1,
          startTime: '08:00',
          endTime: '09:40',
        );

    expect(saved, isTrue);
    expect(
      container.read(scheduleControllerProvider),
      const ScheduleState.loaded([mondaySchedule]),
    );
    expect(notifications.scheduledIds, ['schedule-1']);
  });

  test('createSchedule keeps previous schedules on failure', () async {
    when(
      () => repository.getSchedules(),
    ).thenAnswer((_) async => [mondaySchedule]);
    await container.read(scheduleControllerProvider.notifier).loadSchedules();

    when(
      () => repository.createSchedule(
        courseId: any(named: 'courseId'),
        dayOfWeek: any(named: 'dayOfWeek'),
        startTime: any(named: 'startTime'),
        endTime: any(named: 'endTime'),
        room: any(named: 'room'),
      ),
    ).thenThrow(const FormatException('bad data'));

    final saved = await container
        .read(scheduleControllerProvider.notifier)
        .createSchedule(
          courseId: 'course-2',
          dayOfWeek: 2,
          startTime: '13:00',
          endTime: '14:40',
        );

    final state = container.read(scheduleControllerProvider);
    expect(saved, isFalse);
    expect(state.status, ScheduleStatus.failure);
    expect(state.schedules, [mondaySchedule]);
    expect(state.errorMessage, 'Data jadwal tidak valid.');
    expect(notifications.scheduledIds, isEmpty);
  });

  test('deleteSchedule reloads the list and returns true', () async {
    when(
      () => repository.deleteSchedule('schedule-1'),
    ).thenAnswer((_) async {});
    when(() => repository.getSchedules()).thenAnswer((_) async => const []);

    final deleted = await container
        .read(scheduleControllerProvider.notifier)
        .deleteSchedule('schedule-1');

    expect(deleted, isTrue);
    expect(
      container.read(scheduleControllerProvider),
      const ScheduleState.loaded([]),
    );
    expect(notifications.cancelledIds, ['schedule-1']);
  });
}
