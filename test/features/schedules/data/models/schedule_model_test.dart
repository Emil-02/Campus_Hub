import 'package:campusmate/features/schedules/data/models/schedule_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> validJson() => <String, dynamic>{
    'id': 'schedule-1',
    'course_id': 'course-1',
    'day_of_week': 1,
    'start_time': '08:00:00',
    'end_time': '09:40:00',
    'room': 'R. 3.2',
    'is_active': true,
    'courses': <String, dynamic>{
      'id': 'course-1',
      'name': 'Struktur Data',
      'code': 'IF1234',
      'credits': 3,
      'lecturer': 'Dr. Budi',
      'color': '#4A90D9',
      'created_at': null,
    },
  };

  test('fromJson parses a row with its joined course', () {
    final model = ScheduleModel.fromJson(validJson());

    expect(model.id, 'schedule-1');
    expect(model.courseId, 'course-1');
    expect(model.dayOfWeek, 1);
    expect(model.startTime, '08:00');
    expect(model.endTime, '09:40');
    expect(model.room, 'R. 3.2');
    expect(model.isActive, isTrue);
    expect(model.course?.name, 'Struktur Data');
    expect(model.course?.color, '#4A90D9');
  });

  test('fromJson tolerates a missing joined course', () {
    final json = validJson()..remove('courses');

    final model = ScheduleModel.fromJson(json);

    expect(model.course, isNull);
    expect(model.courseId, 'course-1');
  });

  test('fromJson normalizes HH:mm:ss times to HH:mm', () {
    final model = ScheduleModel.fromJson(validJson());

    expect(model.startTime, hasLength(5));
    expect(model.endTime, hasLength(5));
  });

  test('fromJson rejects a malformed time', () {
    final json = validJson()..['start_time'] = '8';

    expect(() => ScheduleModel.fromJson(json), throwsFormatException);
  });

  test('fromJson rejects a missing day_of_week', () {
    final json = validJson()..['day_of_week'] = null;

    expect(() => ScheduleModel.fromJson(json), throwsFormatException);
  });

  test('conflict model clips times and reads RPC fields', () {
    final conflict = ScheduleConflictModel.fromJson(const <String, dynamic>{
      'conflicting_id': 'schedule-9',
      'course_name': 'Basis Data',
      'start_time': '08:30:00',
      'end_time': '10:00:00',
    });

    expect(conflict.scheduleId, 'schedule-9');
    expect(conflict.courseName, 'Basis Data');
    expect(conflict.startTime, '08:30');
    expect(conflict.endTime, '10:00');
  });
}
