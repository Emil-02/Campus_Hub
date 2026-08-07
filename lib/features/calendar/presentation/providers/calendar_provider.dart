import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/network/supabase_provider.dart';
import '../../../tasks/presentation/providers/task_dependencies.dart';
import '../../data/datasources/calendar_remote_data_source.dart';
import '../../data/repositories/calendar_repository_impl.dart';
import '../../domain/entities/calendar_event_entity.dart';
import '../../domain/repositories/calendar_repository.dart';
import 'calendar_state.dart';

/// Provides the remote calendar datasource from the existing client.
final calendarRemoteDataSourceProvider = Provider<CalendarRemoteDataSource>((
  ref,
) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) {
    throw StateError(
      'Supabase is not initialized; calendar data is unavailable.',
    );
  }
  return CalendarRemoteDataSourceImpl(client);
});

/// Provides the domain calendar repository implementation.
final calendarRepositoryProvider = Provider<CalendarRepository>((ref) {
  return CalendarRepositoryImpl(ref.watch(calendarRemoteDataSourceProvider));
});

/// Provides the calendar controller and its current state.
final calendarControllerProvider =
    NotifierProvider<CalendarController, CalendarState>(CalendarController.new);

/// Loads month events merged with task deadlines (CAL-01, CAL-04).
final class CalendarController extends Notifier<CalendarState> {
  CalendarRepository get _repository => ref.read(calendarRepositoryProvider);

  @override
  CalendarState build() => CalendarState.initial();

  /// Loads events and deadline tasks for the month containing [month].
  Future<void> loadMonth(DateTime month) async {
    final focused = DateTime(month.year, month.month);
    state = CalendarState.loading(focused);
    try {
      final start = focused;
      final end = DateTime(focused.year, focused.month + 1, 0);
      final events = await _repository.getEventsInRange(start: start, end: end);
      final tasks = await ref.read(taskRepositoryProvider).getTasks();
      final deadlineTasks = tasks
          .where(
            (task) =>
                task.deadline != null &&
                !task.deadline!.isBefore(start) &&
                task.deadline!.isBefore(end.add(const Duration(days: 1))),
          )
          .toList(growable: false);
      state = CalendarState.loaded(
        focusedMonth: focused,
        events: events,
        deadlineTasks: deadlineTasks,
      );
    } catch (error) {
      state = CalendarState.failure(
        _safeErrorMessage(error),
        focusedMonth: focused,
        events: state.events,
        deadlineTasks: state.deadlineTasks,
      );
    }
  }

  /// CAL-05: creates a custom event then reloads the month. True on success.
  Future<bool> addEvent({
    required String title,
    String? description,
    required DateTime eventDate,
    String? eventTime,
    required CalendarEventType eventType,
  }) async {
    try {
      await _repository.createEvent(
        title: title,
        description: description,
        eventDate: eventDate,
        eventTime: eventTime,
        eventType: eventType,
        isAllDay: eventTime == null,
      );
      await loadMonth(eventDate);
      return true;
    } catch (error) {
      state = CalendarState.failure(
        _safeErrorMessage(error),
        focusedMonth: state.focusedMonth,
        events: state.events,
        deadlineTasks: state.deadlineTasks,
      );
      return false;
    }
  }

  /// Deletes a custom event then reloads the month. True on success.
  Future<bool> deleteEvent(String id) async {
    try {
      await _repository.deleteEvent(id);
      await loadMonth(state.focusedMonth);
      return true;
    } catch (error) {
      state = CalendarState.failure(
        _safeErrorMessage(error),
        focusedMonth: state.focusedMonth,
        events: state.events,
        deadlineTasks: state.deadlineTasks,
      );
      return false;
    }
  }

  String _safeErrorMessage(Object error) {
    debugPrint('Calendar error: $error');
    if (error is PostgrestException) {
      return 'Gagal memuat data kalender. Coba lagi.';
    }
    if (error is SocketException || error is TimeoutException) {
      return 'Tidak dapat terhubung ke server. Periksa koneksi internet.';
    }
    if (error is StateError) {
      return 'Sesi tidak valid. Silakan login ulang.';
    }
    if (error is FormatException) {
      return 'Data kalender tidak valid.';
    }
    return 'Terjadi kesalahan. Coba lagi.';
  }
}
