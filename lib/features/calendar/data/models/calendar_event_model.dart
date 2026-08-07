import '../../domain/entities/calendar_event_entity.dart';

final class CalendarEventModel extends CalendarEventEntity {
  const CalendarEventModel({
    required super.id,
    required super.title,
    super.description,
    required super.eventDate,
    super.eventTime,
    super.color,
    super.eventType,
    super.isAllDay,
  });

  factory CalendarEventModel.fromJson(Map<String, dynamic> json) {
    return CalendarEventModel(
      id: _requiredString(json, 'id'),
      title: _requiredString(json, 'title'),
      description: _nullableString(json, 'description'),
      eventDate: _requiredDate(json, 'event_date'),
      eventTime: _clipTime(_nullableString(json, 'event_time')),
      color: _nullableString(json, 'color') ?? '#4A90D9',
      eventType: CalendarEventType.fromDb(
        json['event_type'] as String? ?? 'personal',
      ),
      isAllDay: json['is_all_day'] == true,
    );
  }

  CalendarEventEntity toEntity() {
    return CalendarEventEntity(
      id: id,
      title: title,
      description: description,
      eventDate: eventDate,
      eventTime: eventTime,
      color: color,
      eventType: eventType,
      isAllDay: isAllDay,
    );
  }

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException(
        'CalendarEventModel "$key" must be a non-empty String.',
      );
    }
    return value;
  }

  static String? _nullableString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) {
      return null;
    }
    if (value is! String) {
      throw FormatException(
        'CalendarEventModel "$key" must be a String or null.',
      );
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static DateTime _requiredDate(Map<String, dynamic> json, String key) {
    final raw = _requiredString(json, key);
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      throw FormatException('CalendarEventModel "$key" is not a valid date.');
    }
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  /// Postgres TIME arrives as `HH:mm:ss`; keep `HH:mm`.
  static String? _clipTime(String? value) {
    if (value == null) {
      return null;
    }
    return value.length >= 5 ? value.substring(0, 5) : value;
  }
}
