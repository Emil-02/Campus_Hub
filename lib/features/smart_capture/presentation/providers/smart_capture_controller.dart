import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/notification_service.dart';
import '../../../calendar/domain/entities/calendar_event_entity.dart';
import '../../../calendar/presentation/providers/calendar_provider.dart';
import '../../../courses/domain/entities/course_entity.dart';
import '../../../courses/presentation/providers/course_dependencies.dart';
import '../../../tasks/domain/entities/task_entity.dart';
import '../../../tasks/presentation/providers/task_dependencies.dart';
import '../../data/datasources/smart_capture_remote_data_source.dart';
import '../../domain/entities/captured_item_entity.dart';
import '../../domain/repositories/smart_capture_repository.dart';
import 'smart_capture_dependencies.dart';
import 'smart_capture_state.dart';

/// Coordinates the analyze → review → save flow for smart capture.
final class SmartCaptureController extends Notifier<SmartCaptureState> {
  SmartCaptureRepository get _repository =>
      ref.read(smartCaptureRepositoryProvider);

  NotificationService get _notifications =>
      ref.read(notificationServiceProvider);

  @override
  SmartCaptureState build() => const SmartCaptureState.idle();

  /// Restarts the flow for a new input.
  void reset() {
    state = const SmartCaptureState.idle();
  }

  /// Analyzes pasted chat text.
  Future<void> analyzeText(String text) => _analyze(
    (courseNames) => _repository.analyzeText(text, courseNames: courseNames),
  );

  /// Analyzes a photo (chat screenshot/announcement).
  Future<void> analyzeImage(File image) => _analyze(
    (courseNames) => _repository.analyzeImage(image, courseNames: courseNames),
  );

  Future<void> _analyze(
    Future<List<CapturedItemEntity>> Function(List<String>) run,
  ) async {
    state = const SmartCaptureState.analyzing();
    try {
      final courses = await ref.read(courseRepositoryProvider).getCourses();
      final items = await run([for (final course in courses) course.name]);
      final rows = [
        for (final item in items)
          SmartCaptureRow(
            kind: item.kind,
            title: item.title,
            description: item.description,
            date: item.date,
            time: item.time,
            courseId: _matchCourseId(item.courseName, courses),
          ),
      ];
      state = SmartCaptureState.review(rows, courses: courses);
    } catch (error) {
      state = SmartCaptureState.failure(_safeErrorMessage(error));
    }
  }

  /// Toggles whether one row will be saved.
  void toggleRow(int index) {
    _updateRow(index, (row) => row.copyWith(selected: !row.selected));
  }

  /// Switches a row between task and event.
  void setRowKind(int index, CapturedItemKind kind) {
    _updateRow(index, (row) => row.copyWith(kind: kind));
  }

  /// Applies an edited title (blank input is ignored).
  void setRowTitle(int index, String title) {
    final cleaned = title.trim();
    if (cleaned.isEmpty) {
      return;
    }
    _updateRow(index, (row) => row.copyWith(title: cleaned));
  }

  void setRowDate(int index, DateTime? date) {
    _updateRow(index, (row) => row.copyWith(date: date));
  }

  void setRowTime(int index, String? time) {
    _updateRow(index, (row) => row.copyWith(time: time));
  }

  void setRowCourse(int index, String? courseId) {
    _updateRow(index, (row) => row.copyWith(courseId: courseId));
  }

  void _updateRow(int index, SmartCaptureRow Function(SmartCaptureRow) update) {
    if (index < 0 || index >= state.rows.length) {
      return;
    }
    final rows = [...state.rows];
    rows[index] = update(rows[index]);
    state = SmartCaptureState.review(rows, courses: state.courses);
  }

  /// Saves the selected rows. Returns true when everything selected saved.
  Future<bool> saveSelected() async {
    final selectedRows = state.rows.where((row) => row.selected).toList();
    if (selectedRows.isEmpty) {
      return false;
    }
    state = SmartCaptureState.saving(state.rows, courses: state.courses);

    var savedTasks = 0;
    var savedEvents = 0;
    try {
      final taskRepository = ref.read(taskRepositoryProvider);
      final calendarRepository = ref.read(calendarRepositoryProvider);
      for (final row in selectedRows) {
        if (row.kind == CapturedItemKind.task) {
          final deadline = _combine(row.date, row.time ?? '23:59');
          final created = await taskRepository.createTask(
            title: row.title,
            description: row.description,
            deadline: deadline,
            priority: TaskPriority.medium,
            courseId: row.courseId,
          );
          savedTasks++;
          if (deadline != null) {
            unawaited(
              _notifications.scheduleTaskReminders(
                taskId: created.id,
                title: created.title,
                courseName: _courseName(row.courseId),
                deadline: deadline,
              ),
            );
          }
        } else {
          await calendarRepository.createEvent(
            title: row.title,
            description: row.description,
            eventDate: row.date ?? DateTime.now(),
            eventTime: row.time,
            eventType: CalendarEventType.academic,
            isAllDay: row.time == null,
          );
          savedEvents++;
        }
      }
      state = SmartCaptureState.done(
        savedTasks: savedTasks,
        savedEvents: savedEvents,
      );
      return true;
    } catch (error) {
      final saved = savedTasks + savedEvents;
      state = SmartCaptureState.failure(
        saved == 0
            ? _safeErrorMessage(error)
            : 'Sebagian tersimpan ($saved item), lalu gagal: '
                  '${_safeErrorMessage(error)}',
      );
      return false;
    }
  }

  String? _matchCourseId(String? courseName, List<CourseEntity> courses) {
    final target = _normalize(courseName);
    if (target == null) {
      return null;
    }
    for (final course in courses) {
      if (_normalize(course.name) == target) {
        return course.id;
      }
    }
    return null;
  }

  String? _courseName(String? courseId) {
    if (courseId == null) {
      return null;
    }
    for (final course in state.courses) {
      if (course.id == courseId) {
        return course.name;
      }
    }
    return null;
  }

  DateTime? _combine(DateTime? date, String time) {
    if (date == null) {
      return null;
    }
    final parts = time.split(':');
    return DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  String? _normalize(String? value) {
    final cleaned = value
        ?.toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return (cleaned == null || cleaned.isEmpty) ? null : cleaned;
  }

  String _safeErrorMessage(Object error) {
    debugPrint('Smart capture error: $error');
    if (error is SmartCaptureException) {
      return error.message;
    }
    if (error is SocketException || error is TimeoutException) {
      return 'Tidak dapat terhubung ke server. Periksa koneksi internet.';
    }
    return 'Terjadi kesalahan. Coba lagi.';
  }
}
