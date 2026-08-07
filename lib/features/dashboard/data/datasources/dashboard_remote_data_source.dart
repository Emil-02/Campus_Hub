import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../calendar/data/models/calendar_event_model.dart';
import '../../../schedules/data/models/schedule_model.dart';
import '../../../tasks/data/models/task_model.dart';
import '../models/dashboard_stats_model.dart';

/// Remote aggregation queries for the dashboard (T-145).
abstract interface class DashboardRemoteDataSource {
  Future<List<ScheduleModel>> getTodaySchedules();

  Future<List<TaskModel>> getUpcomingDeadlines();

  Future<List<CalendarEventModel>> getUpcomingEvents();

  Future<DashboardStatsModel> getStatistics();
}

/// Implements dashboard queries using the injected Supabase client.
final class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  const DashboardRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<List<ScheduleModel>> getTodaySchedules() async {
    final rows = await _client
        .from('schedules')
        .select('*, courses(*)')
        .eq('is_active', true)
        .eq('day_of_week', DateTime.now().weekday)
        .order('start_time', ascending: true);
    return rows.map(ScheduleModel.fromJson).toList(growable: false);
  }

  @override
  Future<List<TaskModel>> getUpcomingDeadlines() async {
    final rows = await _client
        .from('tasks')
        .select('*, courses(*), task_checklists(*)')
        .eq('is_deleted', false)
        .neq('status', 'completed')
        .not('deadline', 'is', null)
        .gte('deadline', DateTime.now().toUtc().toIso8601String())
        .order('deadline', ascending: true)
        .limit(5);
    return rows.map(TaskModel.fromJson).toList(growable: false);
  }

  @override
  Future<List<CalendarEventModel>> getUpcomingEvents() async {
    final now = DateTime.now();
    final today =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    final rows = await _client
        .from('calendar_events')
        .select()
        .gte('event_date', today)
        .order('event_date', ascending: true)
        .order('event_time', ascending: true, nullsFirst: true)
        .limit(5);
    return rows.map(CalendarEventModel.fromJson).toList(growable: false);
  }

  @override
  Future<DashboardStatsModel> getStatistics() async {
    final result = await _client.rpc('get_task_statistics');
    if (result is Map<String, dynamic>) {
      return DashboardStatsModel.fromJson(result);
    }
    return const DashboardStatsModel();
  }
}
