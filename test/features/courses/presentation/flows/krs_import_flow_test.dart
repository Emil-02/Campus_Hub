// Flow test: scan a KRS photo → review rows (duplicates unchecked) →
// import selected rows into courses + schedules with weekly reminders.
import 'dart:io';

import 'package:campusmate/features/courses/domain/entities/course_entity.dart';
import 'package:campusmate/features/courses/domain/entities/imported_course_entity.dart';
import 'package:campusmate/features/courses/domain/repositories/course_repository.dart';
import 'package:campusmate/features/courses/domain/repositories/krs_scan_repository.dart';
import 'package:campusmate/features/courses/presentation/providers/course_dependencies.dart';
import 'package:campusmate/features/courses/presentation/providers/krs_import_dependencies.dart';
import 'package:campusmate/features/courses/presentation/providers/krs_import_state.dart';
import 'package:campusmate/features/schedules/domain/entities/schedule_entity.dart';
import 'package:campusmate/features/schedules/domain/repositories/schedule_repository.dart';
import 'package:campusmate/features/schedules/presentation/providers/schedule_dependencies.dart';
import 'package:campusmate/services/notification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final class FakeScanRepository implements KrsScanRepository {
  FakeScanRepository(this.results);

  final List<ImportedCourseEntity> results;

  @override
  Future<List<ImportedCourseEntity>> scanImage(File image) async => results;
}

final class InMemoryCourseRepository implements CourseRepository {
  final courses = <CourseEntity>[];
  var _seq = 0;

  @override
  Future<List<CourseEntity>> getCourses() async => List.of(courses);

  @override
  Future<CourseEntity> createCourse({
    required String name,
    String? code,
    int? credits,
    String? lecturer,
    required String color,
  }) async {
    final course = CourseEntity(
      id: 'course-${++_seq}',
      name: name,
      code: code,
      credits: credits,
      lecturer: lecturer,
      color: color,
    );
    courses.add(course);
    return course;
  }

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

final class InMemoryScheduleRepository implements ScheduleRepository {
  final schedules = <ScheduleEntity>[];
  var _seq = 0;

  @override
  Future<List<ScheduleEntity>> getSchedules() async => List.of(schedules);

  @override
  Future<List<ScheduleConflictEntity>> checkConflict({
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    String? excludeScheduleId,
  }) async => const [];

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
    schedules.add(schedule);
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
  }) => throw UnimplementedError();

  @override
  Future<void> deleteSchedule(String id) => throw UnimplementedError();
}

final class RecordingNotificationService implements NotificationService {
  final scheduledIds = <String>[];

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
  Future<void> cancelScheduleReminder(String scheduleId) async {}

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
  const kriptografi = ImportedCourseEntity(
    name: 'KRIPTOGRAFI',
    code: 'CW6552022431',
    credits: 2,
    lecturer: 'DESI ANGGREANI, S.kom.,MT',
    meetings: [
      ImportedMeetingEntity(
        dayOfWeek: 2,
        startTime: '07:30',
        endTime: '09:00',
        room: 'KB3.1',
      ),
    ],
  );
  const praktikum = ImportedCourseEntity(
    name: 'PRAKTIKUM PEMROGRAMAN WEB',
    credits: 1,
  );
  const basisData = ImportedCourseEntity(
    name: 'SISTEM BASIS DATA MODERN',
    code: 'CW6552022433',
    credits: 2,
    meetings: [
      ImportedMeetingEntity(dayOfWeek: 1, startTime: '15:00', endTime: '16:30'),
    ],
  );

  late InMemoryCourseRepository courseRepository;
  late InMemoryScheduleRepository scheduleRepository;
  late RecordingNotificationService notifications;

  ProviderContainer buildContainer(List<ImportedCourseEntity> scanResults) {
    final container = ProviderContainer(
      overrides: [
        krsScanRepositoryProvider.overrideWithValue(
          FakeScanRepository(scanResults),
        ),
        courseRepositoryProvider.overrideWithValue(courseRepository),
        scheduleRepositoryProvider.overrideWithValue(scheduleRepository),
        notificationServiceProvider.overrideWithValue(notifications),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  setUp(() {
    courseRepository = InMemoryCourseRepository();
    scheduleRepository = InMemoryScheduleRepository();
    notifications = RecordingNotificationService();
  });

  test('full flow: scan → review → import courses and schedules', () async {
    final container = buildContainer([kriptografi, praktikum, basisData]);
    final controller = container.read(krsImportControllerProvider.notifier);

    await controller.scanImage(File('krs.jpg'));

    var state = container.read(krsImportControllerProvider);
    expect(state.status, KrsImportStatus.review);
    expect(state.rows, hasLength(3));
    expect(state.rows.every((row) => row.selected), isTrue);
    expect(state.selectedCount, 3);

    // Deselect the praktikum row.
    controller.toggleRow(1);
    state = container.read(krsImportControllerProvider);
    expect(state.selectedCount, 2);

    final success = await controller.importSelected();

    expect(success, isTrue);
    state = container.read(krsImportControllerProvider);
    expect(state.importedCourses, 2);
    expect(state.importedSchedules, 2);
    expect(courseRepository.courses.map((c) => c.name), [
      'KRIPTOGRAFI',
      'SISTEM BASIS DATA MODERN',
    ]);
    // Courses get distinct palette colors.
    expect(courseRepository.courses.map((c) => c.color).toSet(), hasLength(2));
    expect(scheduleRepository.schedules, hasLength(2));
    expect(scheduleRepository.schedules.first.room, 'KB3.1');
    // Weekly reminders registered for each imported schedule.
    expect(notifications.scheduledIds, hasLength(2));
  });

  test('marks existing courses as duplicates and deselects them', () async {
    await courseRepository.createCourse(
      name: 'Kriptografi',
      code: 'cw6552022431',
      color: '#4A90D9',
    );
    final container = buildContainer([kriptografi, basisData]);
    final controller = container.read(krsImportControllerProvider.notifier);

    await controller.scanImage(File('krs.jpg'));

    final state = container.read(krsImportControllerProvider);
    expect(state.rows, hasLength(2));
    // Duplicate by code (case-insensitive) is deselected.
    expect(state.rows.first.isDuplicate, isTrue);
    expect(state.rows.first.selected, isFalse);
    expect(state.rows.last.isDuplicate, isFalse);
    expect(state.rows.last.selected, isTrue);
  });

  test('importSelected without selection does nothing', () async {
    final container = buildContainer([kriptografi]);
    final controller = container.read(krsImportControllerProvider.notifier);
    await controller.scanImage(File('krs.jpg'));
    controller.toggleRow(0);

    final success = await controller.importSelected();

    expect(success, isFalse);
    expect(courseRepository.courses, isEmpty);
  });
}
