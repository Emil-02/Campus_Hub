import 'dart:convert';

import '../../../tasks/domain/entities/task_entity.dart';
import '../entities/calendar_event_entity.dart';

String _two(int value) => value.toString().padLeft(2, '0');
String _date(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}${_two(d.month)}${_two(d.day)}';
String _stamp(DateTime value) {
  final d = value.toUtc();
  return '${_date(d)}T${_two(d.hour)}${_two(d.minute)}${_two(d.second)}Z';
}

String _text(String value) => value
    .replaceAll('\\', r'\\')
    .replaceAll(RegExp(r'\r\n?|\n'), r'\n')
    .replaceAll(';', r'\;')
    .replaceAll(',', r'\,');

// Fold at 75 UTF-8 octets, including the space on continuation lines.
String _fold(String line) {
  final out = StringBuffer();
  var width = 0;
  for (final rune in line.runes) {
    final ch = String.fromCharCode(rune);
    final size = utf8.encode(ch).length;
    if (width + size > 75) {
      out.write('\r\n ');
      width = 1;
    }
    out.write(ch);
    width += size;
  }
  return out.toString();
}

String exportCalendarMonth(
  DateTime month,
  List<CalendarEventEntity> events,
  List<TaskEntity> tasks, {
  required DateTime generatedAt,
}) {
  final lines = [
    'BEGIN:VCALENDAR',
    'VERSION:2.0',
    'PRODID:-//CampusMate//Calendar//ID',
    'CALSCALE:GREGORIAN',
  ];
  bool inMonth(DateTime d) => month.year == d.year && month.month == d.month;
  void add(String uid, String title, String start, String? description) {
    lines.addAll([
      'BEGIN:VEVENT',
      'UID:${_text(uid)}@campusmate',
      'DTSTAMP:${_stamp(generatedAt)}',
      start,
      'SUMMARY:${_text(title)}',
      if (description != null && description.isNotEmpty)
        'DESCRIPTION:${_text(description)}',
      'END:VEVENT',
    ]);
  }

  for (final event in events) {
    final d = event.eventDate;
    if (!inMonth(d)) continue;
    final time = event.eventTime;
    var start = 'DTSTART;VALUE=DATE:${_date(d)}';
    if (!event.isAllDay && time != null) {
      final clock = time.split(':');
      final local = DateTime(
        d.year,
        d.month,
        d.day,
        int.parse(clock[0]),
        int.parse(clock[1]),
        clock.length > 2 ? double.parse(clock[2]).floor() : 0,
      );
      start = 'DTSTART:${_stamp(local)}';
    }
    add('event-${event.id}', event.title, start, event.description);
  }
  for (final task in tasks) {
    final deadline = task.deadline?.toLocal();
    if (deadline != null && inMonth(deadline)) {
      add(
        'task-${task.id}',
        'Deadline: ${task.title}',
        'DTSTART:${_stamp(deadline)}',
        task.description,
      );
    }
  }
  return [...lines, 'END:VCALENDAR', ''].map(_fold).join('\r\n');
}
