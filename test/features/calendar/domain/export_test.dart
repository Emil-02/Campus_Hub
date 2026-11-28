import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:campusmate/features/calendar/domain/export/icalendar.dart';
import 'package:campusmate/features/calendar/domain/entities/calendar_event_entity.dart';
import 'package:campusmate/features/tasks/domain/entities/task_entity.dart';

void main() {
  test(
    'exports all-day and timed entries, escapes and folds text, excludes other months',
    () {
      final day = DateTime(2026, 11, 9);
      final time = DateTime(2026, 11, 9, 12, 30);
      final out = exportCalendarMonth(
        day,
        [
          CalendarEventEntity(id: 'a', title: 'Libur, kampus', eventDate: day),
          CalendarEventEntity(
            id: 'b',
            title: 'Ujian',
            eventDate: day,
            eventTime: '12:30:00',
            description: 'é' * 80,
          ),
        ],
        [
          TaskEntity(id: 't', title: 'Tugas', deadline: time),
          TaskEntity(id: 'lain', title: 'omit', deadline: DateTime(2026, 12)),
        ],
        generatedAt: DateTime.utc(2026),
      );
      expect(out, contains('DTSTART;VALUE=DATE:20261109\r\n'));
      expect(out, contains(r'SUMMARY:Libur\, kampus'));
      final utc = time
          .toUtc()
          .toIso8601String()
          .split('.')
          .first
          .replaceAll(RegExp('[-:]'), '');
      expect('DTSTART:${utc}Z'.allMatches(out).length, 2);
      expect(out, contains('UID:task-t@campusmate'));
      expect(out, isNot(contains('omit')));
      expect(
        out.split('\r\n').every((line) => utf8.encode(line).length <= 75),
        isTrue,
      );
    },
  );
}
