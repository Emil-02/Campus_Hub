import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/calendar_event_entity.dart';
import '../models/calendar_event_model.dart';

/// Remote operations for the `calendar_events` table.
abstract interface class CalendarRemoteDataSource {
  Future<List<CalendarEventModel>> getEventsInRange({
    required DateTime start,
    required DateTime end,
  });

  Future<CalendarEventModel> createEvent({
    required String title,
    String? description,
    required DateTime eventDate,
    String? eventTime,
    required CalendarEventType eventType,
    bool isAllDay,
  });

  Future<void> deleteEvent(String id);
}

/// Implements calendar operations using the injected Supabase client.
final class CalendarRemoteDataSourceImpl implements CalendarRemoteDataSource {
  const CalendarRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  String get _userId {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('A signed-in user is required for calendar operations.');
    }
    return userId;
  }

  static String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  @override
  Future<List<CalendarEventModel>> getEventsInRange({
    required DateTime start,
    required DateTime end,
  }) async {
    final rows = await _client
        .from('calendar_events')
        .select()
        .gte('event_date', _dateOnly(start))
        .lte('event_date', _dateOnly(end))
        .order('event_date', ascending: true)
        .order('event_time', ascending: true, nullsFirst: true);
    return rows.map(CalendarEventModel.fromJson).toList(growable: false);
  }

  @override
  Future<CalendarEventModel> createEvent({
    required String title,
    String? description,
    required DateTime eventDate,
    String? eventTime,
    required CalendarEventType eventType,
    bool isAllDay = false,
  }) async {
    final row = await _client
        .from('calendar_events')
        .insert({
          'user_id': _userId,
          'title': title,
          'description': description,
          'event_date': _dateOnly(eventDate),
          'event_time': eventTime,
          'event_type': eventType.dbValue,
          'is_all_day': isAllDay,
        })
        .select()
        .single();
    return CalendarEventModel.fromJson(row);
  }

  @override
  Future<void> deleteEvent(String id) async {
    await _client.from('calendar_events').delete().eq('id', id);
  }
}
