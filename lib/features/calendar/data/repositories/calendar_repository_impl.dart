import '../../domain/entities/calendar_event_entity.dart';
import '../../domain/repositories/calendar_repository.dart';
import '../datasources/calendar_remote_data_source.dart';

/// Bridges the calendar domain contract to the remote data source.
final class CalendarRepositoryImpl implements CalendarRepository {
  const CalendarRepositoryImpl(this._remoteDataSource);

  final CalendarRemoteDataSource _remoteDataSource;

  @override
  Future<List<CalendarEventEntity>> getEventsInRange({
    required DateTime start,
    required DateTime end,
  }) async {
    final models = await _remoteDataSource.getEventsInRange(
      start: start,
      end: end,
    );
    return models.map((model) => model.toEntity()).toList(growable: false);
  }

  @override
  Future<CalendarEventEntity> createEvent({
    required String title,
    String? description,
    required DateTime eventDate,
    String? eventTime,
    required CalendarEventType eventType,
    bool isAllDay = false,
  }) async {
    final model = await _remoteDataSource.createEvent(
      title: title,
      description: description,
      eventDate: eventDate,
      eventTime: eventTime,
      eventType: eventType,
      isAllDay: isAllDay,
    );
    return model.toEntity();
  }

  @override
  Future<void> deleteEvent(String id) {
    return _remoteDataSource.deleteEvent(id);
  }
}
