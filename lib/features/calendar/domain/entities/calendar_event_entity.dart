import 'package:equatable/equatable.dart';

enum CalendarEventType {
  academic('academic', 'Akademik'),
  personal('personal', 'Pribadi'),
  organization('organization', 'Organisasi'),
  exam('exam', 'Ujian'),
  holiday('holiday', 'Libur');

  const CalendarEventType(this.dbValue, this.label);

  final String dbValue;
  final String label;

  static CalendarEventType fromDb(String value) {
    return CalendarEventType.values.firstWhere(
      (type) => type.dbValue == value,
      orElse: () => CalendarEventType.personal,
    );
  }
}

/// A custom calendar event outside of task deadlines.
class CalendarEventEntity extends Equatable {
  const CalendarEventEntity({
    required this.id,
    required this.title,
    this.description,
    required this.eventDate,
    this.eventTime,
    this.color = '#4A90D9',
    this.eventType = CalendarEventType.personal,
    this.isAllDay = false,
  });

  final String id;
  final String title;
  final String? description;

  /// Date-only (local); time lives in [eventTime] as `HH:mm`.
  final DateTime eventDate;
  final String? eventTime;
  final String color;
  final CalendarEventType eventType;
  final bool isAllDay;

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    eventDate,
    eventTime,
    color,
    eventType,
    isAllDay,
  ];
}
