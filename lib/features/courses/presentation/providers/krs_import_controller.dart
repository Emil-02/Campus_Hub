import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/notification_service.dart';
import '../../../schedules/presentation/providers/schedule_dependencies.dart';
import '../../data/datasources/krs_scan_remote_data_source.dart';
import '../../domain/repositories/course_repository.dart';
import '../../domain/repositories/krs_scan_repository.dart';
import '../widgets/course_color_picker.dart';
import 'course_dependencies.dart';
import 'krs_import_dependencies.dart';
import 'krs_import_state.dart';

/// Coordinates the scan → review → import flow for KRS photos.
final class KrsImportController extends Notifier<KrsImportState> {
  KrsScanRepository get _scanRepository => ref.read(krsScanRepositoryProvider);

  CourseRepository get _courseRepository => ref.read(courseRepositoryProvider);

  NotificationService get _notifications =>
      ref.read(notificationServiceProvider);

  @override
  KrsImportState build() => const KrsImportState.idle();

  /// Restarts the flow so another photo can be picked.
  void reset() {
    state = const KrsImportState.idle();
  }

  /// Toggles whether one reviewed row will be imported.
  void toggleRow(int index) {
    if (index < 0 || index >= state.rows.length) {
      return;
    }
    final rows = [...state.rows];
    rows[index] = rows[index].copyWith(selected: !rows[index].selected);
    state = KrsImportState.review(rows);
  }

  /// Scans the photo and prepares rows for review (duplicates unchecked).
  Future<void> scanImage(File image) async {
    state = const KrsImportState.scanning();
    try {
      final imported = await _scanRepository.scanImage(image);
      final existing = await _courseRepository.getCourses();
      final existingCodes = <String>{
        for (final course in existing) ?_normalize(course.code),
      };
      final existingNames = <String>{
        for (final course in existing) ?_normalize(course.name),
      };

      final rows = <KrsImportRow>[
        for (final course in imported)
          () {
            final duplicate =
                (_normalize(course.code) != null &&
                    existingCodes.contains(_normalize(course.code))) ||
                existingNames.contains(_normalize(course.name));
            return KrsImportRow(
              course: course,
              selected: !duplicate,
              isDuplicate: duplicate,
            );
          }(),
      ];
      state = KrsImportState.review(rows);
    } catch (error) {
      state = KrsImportState.failure(_safeErrorMessage(error));
    }
  }

  /// Imports the selected rows. Returns true when everything selected saved.
  Future<bool> importSelected() async {
    final selectedRows = state.rows.where((row) => row.selected).toList();
    if (selectedRows.isEmpty) {
      return false;
    }
    state = KrsImportState.importing(state.rows);

    var importedCourses = 0;
    var importedSchedules = 0;
    try {
      final existingCount = (await _courseRepository.getCourses()).length;
      final scheduleRepository = ref.read(scheduleRepositoryProvider);
      for (final (index, row) in selectedRows.indexed) {
        final color =
            courseColorPalette[(existingCount + index) %
                courseColorPalette.length];
        final created = await _courseRepository.createCourse(
          name: row.course.name,
          code: row.course.code,
          credits: row.course.credits,
          lecturer: row.course.lecturer,
          color: color,
        );
        importedCourses++;
        for (final meeting in row.course.meetings) {
          final schedule = await scheduleRepository.createSchedule(
            courseId: created.id,
            dayOfWeek: meeting.dayOfWeek,
            startTime: meeting.startTime,
            endTime: meeting.endTime,
            room: meeting.room,
          );
          importedSchedules++;
          unawaited(
            _notifications.scheduleWeeklyClassReminder(
              scheduleId: schedule.id,
              dayOfWeek: schedule.dayOfWeek,
              startTime: schedule.startTime,
              courseName: created.name,
              room: schedule.room,
            ),
          );
        }
      }
      state = KrsImportState.done(
        importedCourses: importedCourses,
        importedSchedules: importedSchedules,
      );
      return true;
    } catch (error) {
      state = KrsImportState.failure(
        importedCourses == 0
            ? _safeErrorMessage(error)
            : 'Sebagian tersimpan ($importedCourses mata kuliah), lalu gagal: '
                  '${_safeErrorMessage(error)}',
        rows: state.rows,
      );
      return false;
    }
  }

  String? _normalize(String? value) {
    final cleaned = value?.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
    return (cleaned == null || cleaned.isEmpty) ? null : cleaned;
  }

  String _safeErrorMessage(Object error) {
    debugPrint('KRS import error: $error');
    if (error is KrsScanException) {
      return error.message;
    }
    if (error is SocketException || error is TimeoutException) {
      return 'Tidak dapat terhubung ke server. Periksa koneksi internet.';
    }
    return 'Terjadi kesalahan. Coba lagi.';
  }
}
