// Flow test: analyze chat text → review (edit rows) → save tasks + events.
import 'dart:io';

import 'package:campusmate/features/calendar/domain/entities/calendar_event_entity.dart';
import 'package:campusmate/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:campusmate/features/calendar/presentation/providers/calendar_provider.dart';
import 'package:campusmate/features/courses/domain/entities/course_entity.dart';
import 'package:campusmate/features/courses/domain/repositories/course_repository.dart';
import 'package:campusmate/features/courses/presentation/providers/course_dependencies.dart';
import 'package:campusmate/features/smart_capture/domain/entities/captured_item_entity.dart';
import 'package:campusmate/features/smart_capture/domain/repositories/smart_capture_repository.dart';
import 'package:campusmate/features/smart_capture/presentation/providers/smart_capture_dependencies.dart';
import 'package:campusmate/features/smart_capture/presentation/providers/smart_capture_state.dart';
import 'package:campusmate/features/tasks/domain/entities/task_entity.dart';
import 'package:campusmate/features/tasks/domain/repositories/task_repository.dart';
import 'package:campusmate/features/tasks/presentation/providers/task_dependencies.dart';
import 'package:campusmate/services/notification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final class FakeCaptureRepository implements SmartCaptureRepository {
  FakeCaptureRepository(this.items);

  final List<CapturedItemEntity> items;
  List<String>? lastCourseNames;

  @override
  Future<List<CapturedItemEntity>> analyzeText(
    String text, {
    required List<String> courseNames,
  }) async {
    lastCourseNames = courseNames;
    return items;
  }

  @override
  Future<List<CapturedItemEntity>> analyzeImage(
    File image, {
    required List<String> courseNames,
  }) async {
    lastCourseNames = courseNames;
    return items;
  }
}

final class FakeCourseRepository implements CourseRepository {
  FakeCourseRepository(this.courses);

  final List<CourseEntity> courses;

  @override
  Future<List<CourseEntity>> getCourses() async => courses;

  @override
  Future<CourseEntity> createCourse({
    required String name,
    String? code,
    int? credits,
    String? lecturer,
    required String color,
  }) => throw UnimplementedError();

  @override
  Future<CourseEntity> updateCourse({
    required String id,
    required String name,
    String? code,
    int? credits,
    String? lecturer,
    required String color,
  }) => throw UnimplementedError();

  @override
  Future<void> deleteCourse(String id) => throw UnimplementedError();
}

final class RecordingTaskRepository implements TaskRepository {
  final created = <TaskEntity>[];
  var _seq = 0;

  @override
  Future<TaskEntity> createTask({
    required String title,
    String? description,
    DateTime? deadline,
    required TaskPriority priority,
    String? courseId,
    List<String> checklistTitles = const [],
  }) async {
    final task = TaskEntity(
      id: 'task-${++_seq}',
      title: title,
      description: description,
      deadline: deadline,
      priority: priority,
      courseId: courseId,
    );
    created.add(task);
    return task;
  }

  @override
  Future<List<TaskEntity>> getTasks() async => created;

  @override
  Future<TaskEntity> updateTask({
    required String id,
    required String title,
    String? description,
    DateTime? deadline,
    required TaskPriority priority,
    String? courseId,
  }) => throw UnimplementedError();

  @override
  Future<TaskEntity> setTaskCompleted({
    required String id,
    required bool completed,
  }) => throw UnimplementedError();

  @override
  Future<void> deleteTask(String id) => throw UnimplementedError();

  @override
  Future<void> restoreTask(String id) => throw UnimplementedError();

  @override
  Future<void> addChecklistItem({
    required String taskId,
    required String title,
    required int sortOrder,
  }) => throw UnimplementedError();

  @override
  Future<void> toggleChecklistItem({
    required String id,
    required bool isCompleted,
  }) => throw UnimplementedError();

  @override
  Future<void> deleteChecklistItem(String id) => throw UnimplementedError();
}

final class RecordingCalendarRepository implements CalendarRepository {
  final created = <CalendarEventEntity>[];
  var _seq = 0;

  @override
  Future<CalendarEventEntity> createEvent({
    required String title,
    String? description,
    required DateTime eventDate,
    String? eventTime,
    required CalendarEventType eventType,
    bool isAllDay = false,
  }) async {
    final event = CalendarEventEntity(
      id: 'event-${++_seq}',
      title: title,
      description: description,
      eventDate: eventDate,
      eventTime: eventTime,
      eventType: eventType,
      isAllDay: isAllDay,
    );
    created.add(event);
    return event;
  }

  @override
  Future<List<CalendarEventEntity>> getEventsInRange({
    required DateTime start,
    required DateTime end,
  }) async => created;

  @override
  Future<void> deleteEvent(String id) => throw UnimplementedError();
}

final class RecordingNotificationService implements NotificationService {
  final taskReminderIds = <String>[];

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
  }) async {}

  @override
  Future<void> cancelScheduleReminder(String scheduleId) async {}

  @override
  Future<void> scheduleTaskReminders({
    required String taskId,
    required String title,
    String? courseName,
    required DateTime deadline,
  }) async {
    taskReminderIds.add(taskId);
  }

  @override
  Future<void> cancelTaskReminders(String taskId) async {}
}

void main() {
  const imk = CourseEntity(
    id: 'course-imk',
    name: 'Interaksi Manusia dan Komputer',
    color: '#4A90D9',
  );

  final capturedTask = CapturedItemEntity(
    kind: CapturedItemKind.task,
    title: 'Laporan Analisis UI',
    description: 'Kumpul lewat LMS',
    date: DateTime(2026, 8, 14),
    time: '23:59',
    courseName: 'Interaksi Manusia dan Komputer',
  );
  final capturedEvent = CapturedItemEntity(
    kind: CapturedItemKind.event,
    title: 'Kelas pengganti IMK',
    date: DateTime(2026, 8, 10),
    time: '13:00',
  );

  late RecordingTaskRepository taskRepository;
  late RecordingCalendarRepository calendarRepository;
  late RecordingNotificationService notifications;
  late FakeCaptureRepository captureRepository;
  late ProviderContainer container;

  ProviderContainer buildContainer(List<CapturedItemEntity> items) {
    captureRepository = FakeCaptureRepository(items);
    final container = ProviderContainer(
      overrides: [
        smartCaptureRepositoryProvider.overrideWithValue(captureRepository),
        courseRepositoryProvider.overrideWithValue(
          FakeCourseRepository(const [imk]),
        ),
        taskRepositoryProvider.overrideWithValue(taskRepository),
        calendarRepositoryProvider.overrideWithValue(calendarRepository),
        notificationServiceProvider.overrideWithValue(notifications),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  setUp(() {
    taskRepository = RecordingTaskRepository();
    calendarRepository = RecordingCalendarRepository();
    notifications = RecordingNotificationService();
  });

  test('full flow: analyze → review → save task and event', () async {
    container = buildContainer([capturedTask, capturedEvent]);
    final controller = container.read(smartCaptureControllerProvider.notifier);

    await controller.analyzeText('Tugas IMK ... kelas pengganti ...');

    var state = container.read(smartCaptureControllerProvider);
    expect(state.status, SmartCaptureStatus.review);
    expect(state.rows, hasLength(2));
    // The user's course names were passed to the AI prompt.
    expect(captureRepository.lastCourseNames, [
      'Interaksi Manusia dan Komputer',
    ]);
    // AI course hint is resolved to an id.
    expect(state.rows.first.courseId, 'course-imk');
    expect(state.rows.first.kind, CapturedItemKind.task);
    expect(state.rows.last.kind, CapturedItemKind.event);

    final success = await controller.saveSelected();

    expect(success, isTrue);
    state = container.read(smartCaptureControllerProvider);
    expect(state.savedTasks, 1);
    expect(state.savedEvents, 1);

    final task = taskRepository.created.single;
    expect(task.title, 'Laporan Analisis UI');
    expect(task.courseId, 'course-imk');
    expect(task.deadline, DateTime(2026, 8, 14, 23, 59));
    // H-3/H-1 reminders registered for the deadline.
    expect(notifications.taskReminderIds, [task.id]);

    final event = calendarRepository.created.single;
    expect(event.title, 'Kelas pengganti IMK');
    expect(event.eventDate, DateTime(2026, 8, 10));
    expect(event.eventTime, '13:00');
    expect(event.isAllDay, isFalse);
  });

  test('review edits: switch kind, retitle, change date/time/course', () async {
    container = buildContainer([capturedTask]);
    final controller = container.read(smartCaptureControllerProvider.notifier);
    await controller.analyzeText('pesan');

    controller.setRowKind(0, CapturedItemKind.event);
    controller.setRowTitle(0, 'Presentasi Analisis UI');
    controller.setRowTitle(0, '   '); // ignored
    controller.setRowDate(0, DateTime(2026, 8, 20));
    controller.setRowTime(0, '09:00');

    final row = container.read(smartCaptureControllerProvider).rows.single;
    expect(row.kind, CapturedItemKind.event);
    expect(row.title, 'Presentasi Analisis UI');
    expect(row.date, DateTime(2026, 8, 20));
    expect(row.time, '09:00');

    final success = await controller.saveSelected();
    expect(success, isTrue);
    expect(taskRepository.created, isEmpty);
    expect(calendarRepository.created.single.title, 'Presentasi Analisis UI');
  });

  test('task without deadline saves without reminders', () async {
    container = buildContainer([
      const CapturedItemEntity(
        kind: CapturedItemKind.task,
        title: 'Baca modul 5',
      ),
    ]);
    final controller = container.read(smartCaptureControllerProvider.notifier);
    await controller.analyzeText('pesan');

    final success = await controller.saveSelected();

    expect(success, isTrue);
    expect(taskRepository.created.single.deadline, isNull);
    expect(notifications.taskReminderIds, isEmpty);
  });

  test('deselected rows are not saved', () async {
    container = buildContainer([capturedTask, capturedEvent]);
    final controller = container.read(smartCaptureControllerProvider.notifier);
    await controller.analyzeText('pesan');

    controller.toggleRow(0);
    final success = await controller.saveSelected();

    expect(success, isTrue);
    expect(taskRepository.created, isEmpty);
    expect(calendarRepository.created, hasLength(1));
  });
}
