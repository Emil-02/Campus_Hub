import '../entities/calendar_event_entity.dart';

/// Contract for calendar event data operations.
abstract interface class CalendarRepository {
  /// Returns events between [start] and [end] (inclusive).
  Future<List<CalendarEventEntity>> getEventsInRange({
    required DateTime start,
    required DateTime end,
  });

  Future<CalendarEventEntity> createEvent({
    required String title,
    String? description,
    required DateTime eventDate,
    String? eventTime,
    required CalendarEventType eventType,
    bool isAllDay,
  });

  Future<void> deleteEvent(String id);
}
