import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/schedule_model.dart';

/// Remote operations for the `schedules` table.
abstract interface class ScheduleRemoteDataSource {
  Future<List<ScheduleModel>> getSchedules();

  Future<List<ScheduleConflictModel>> checkConflict({
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    String? excludeScheduleId,
  });

  Future<ScheduleModel> createSchedule({
    required String courseId,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    String? room,
  });

  Future<ScheduleModel> updateSchedule({
    required String id,
    required String courseId,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    String? room,
  });

  Future<void> deleteSchedule(String id);
}

/// Implements schedule operations using the injected Supabase client.
final class ScheduleRemoteDataSourceImpl implements ScheduleRemoteDataSource {
  const ScheduleRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  String get _userId {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('A signed-in user is required for schedule operations.');
    }
    return userId;
  }

  @override
  Future<List<ScheduleModel>> getSchedules() async {
    final rows = await _client
        .from('schedules')
        .select('*, courses(*)')
        .eq('is_active', true)
        .order('day_of_week', ascending: true)
        .order('start_time', ascending: true);
    return rows.map(ScheduleModel.fromJson).toList(growable: false);
  }

  @override
  Future<List<ScheduleConflictModel>> checkConflict({
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    String? excludeScheduleId,
  }) async {
    final rows = await _client.rpc(
      'check_schedule_conflict',
      params: {
        'p_user_id': _userId,
        'p_day_of_week': dayOfWeek,
        'p_start_time': startTime,
        'p_end_time': endTime,
        'p_exclude_id': excludeScheduleId,
      },
    );
    if (rows is! List) {
      return const [];
    }
    return rows
        .whereType<Map<String, dynamic>>()
        .map(ScheduleConflictModel.fromJson)
        .toList(growable: false);
  }

  @override
  Future<ScheduleModel> createSchedule({
    required String courseId,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    String? room,
  }) async {
    final row = await _client
        .from('schedules')
        .insert({
          'user_id': _userId,
          'course_id': courseId,
          'day_of_week': dayOfWeek,
          'start_time': startTime,
          'end_time': endTime,
          'room': room,
        })
        .select('*, courses(*)')
        .single();
    return ScheduleModel.fromJson(row);
  }

  @override
  Future<ScheduleModel> updateSchedule({
    required String id,
    required String courseId,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    String? room,
  }) async {
    final row = await _client
        .from('schedules')
        .update({
          'course_id': courseId,
          'day_of_week': dayOfWeek,
          'start_time': startTime,
          'end_time': endTime,
          'room': room,
        })
        .eq('id', id)
        .select('*, courses(*)')
        .single();
    return ScheduleModel.fromJson(row);
  }

  @override
  Future<void> deleteSchedule(String id) async {
    await _client.from('schedules').delete().eq('id', id);
  }
}
