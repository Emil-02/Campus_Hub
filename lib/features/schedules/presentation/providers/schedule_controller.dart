import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../domain/entities/schedule_entity.dart';
import '../../domain/repositories/schedule_repository.dart';
import 'schedule_dependencies.dart';
import 'schedule_state.dart';

/// Coordinates schedule CRUD, conflict checks, and exposes their state.
final class ScheduleController extends Notifier<ScheduleState> {
  ScheduleRepository get _repository => ref.read(scheduleRepositoryProvider);

  @override
  ScheduleState build() => const ScheduleState.initial();

  /// Loads all active schedules.
  Future<void> loadSchedules() async {
    state = const ScheduleState.loading();
    try {
      final schedules = await _repository.getSchedules();
      state = ScheduleState.loaded(schedules);
    } catch (error) {
      state = ScheduleState.failure(_safeErrorMessage(error));
    }
  }

  /// Returns overlapping schedules, or an empty list when the slot is free.
  /// Errors are swallowed into an empty list so saving stays possible.
  Future<List<ScheduleConflictEntity>> checkConflict({
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    String? excludeScheduleId,
  }) async {
    try {
      return await _repository.checkConflict(
        dayOfWeek: dayOfWeek,
        startTime: startTime,
        endTime: endTime,
        excludeScheduleId: excludeScheduleId,
      );
    } catch (error) {
      debugPrint('Schedule conflict check error: $error');
      return const [];
    }
  }

  /// Creates a schedule and refreshes the list. Returns true when saved.
  Future<bool> createSchedule({
    required String courseId,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    String? room,
  }) async {
    state = ScheduleState.loaded(state.schedules, isMutating: true);
    try {
      await _repository.createSchedule(
        courseId: courseId,
        dayOfWeek: dayOfWeek,
        startTime: startTime,
        endTime: endTime,
        room: room,
      );
      await _reload();
      return true;
    } catch (error) {
      state = ScheduleState.failure(
        _safeErrorMessage(error),
        schedules: state.schedules,
      );
      return false;
    }
  }

  /// Updates a schedule and refreshes the list. Returns true when saved.
  Future<bool> updateSchedule({
    required String id,
    required String courseId,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    String? room,
  }) async {
    state = ScheduleState.loaded(state.schedules, isMutating: true);
    try {
      await _repository.updateSchedule(
        id: id,
        courseId: courseId,
        dayOfWeek: dayOfWeek,
        startTime: startTime,
        endTime: endTime,
        room: room,
      );
      await _reload();
      return true;
    } catch (error) {
      state = ScheduleState.failure(
        _safeErrorMessage(error),
        schedules: state.schedules,
      );
      return false;
    }
  }

  /// Deletes a schedule and refreshes the list. Returns true when removed.
  Future<bool> deleteSchedule(String id) async {
    state = ScheduleState.loaded(state.schedules, isMutating: true);
    try {
      await _repository.deleteSchedule(id);
      await _reload();
      return true;
    } catch (error) {
      state = ScheduleState.failure(
        _safeErrorMessage(error),
        schedules: state.schedules,
      );
      return false;
    }
  }

  Future<void> _reload() async {
    final schedules = await _repository.getSchedules();
    state = ScheduleState.loaded(schedules);
  }

  String _safeErrorMessage(Object error) {
    debugPrint('Schedule error: $error');
    if (error is PostgrestException) {
      if (error.code == '23514') {
        return 'Jam mulai harus sebelum jam selesai.';
      }
      if (error.code == '23503') {
        return 'Mata kuliah tidak ditemukan. Muat ulang lalu coba lagi.';
      }
      return 'Gagal menyimpan ke server. Coba lagi.';
    }
    if (error is SocketException || error is TimeoutException) {
      return 'Tidak dapat terhubung ke server. Periksa koneksi internet.';
    }
    if (error is StateError) {
      return 'Sesi tidak valid. Silakan login ulang.';
    }
    if (error is FormatException) {
      return 'Data jadwal tidak valid.';
    }
    return 'Terjadi kesalahan. Coba lagi.';
  }
}
