import 'package:campusmate/features/calendar/data/models/calendar_event_model.dart';
import 'package:campusmate/features/calendar/domain/entities/calendar_event_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> validJson() => <String, dynamic>{
    'id': 'event-1',
    'title': 'UTS Struktur Data',
    'description': 'Ruang 3.2',
    'event_date': '2026-08-20',
    'event_time': '09:30:00',
    'color': '#D94A4A',
    'event_type': 'exam',
    'is_all_day': false,
  };

  test('fromJson parses a complete row', () {
    final model = CalendarEventModel.fromJson(validJson());

    expect(model.id, 'event-1');
    expect(model.title, 'UTS Struktur Data');
    expect(model.eventDate, DateTime(2026, 8, 20));
    expect(model.eventTime, '09:30');
    expect(model.eventType, CalendarEventType.exam);
    expect(model.isAllDay, isFalse);
  });

  test('fromJson accepts null optional fields', () {
    final json = validJson()
      ..['description'] = null
      ..['event_time'] = null
      ..['color'] = null
      ..['is_all_day'] = true;

    final model = CalendarEventModel.fromJson(json);

    expect(model.description, isNull);
    expect(model.eventTime, isNull);
    expect(model.color, '#4A90D9');
    expect(model.isAllDay, isTrue);
  });

  test('fromJson falls back to personal on unknown event types', () {
    final json = validJson()..['event_type'] = 'nonsense';

    expect(
      CalendarEventModel.fromJson(json).eventType,
      CalendarEventType.personal,
    );
  });

  test('fromJson rejects a missing date', () {
    final json = validJson()..['event_date'] = null;

    expect(() => CalendarEventModel.fromJson(json), throwsFormatException);
  });
}
