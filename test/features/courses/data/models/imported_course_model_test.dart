import 'package:campusmate/features/courses/data/models/imported_course_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses a complete row with multiple meetings', () {
    final course = ImportedCourseModel.fromJson({
      'kode': ' CW6552022433 ',
      'nama': 'SISTEM  BASIS DATA MODERN',
      'sks': 2,
      'dosen': 'MUHYIDDIN A M HAYAT, S.Kom, MT',
      'pertemuan': [
        {
          'hari': 1,
          'jam_mulai': '15:00',
          'jam_selesai': '16:30',
          'ruangan': 'KB3.3',
        },
        {'hari': 3, 'jam_mulai': '9.00', 'jam_selesai': '10.30'},
      ],
    });

    expect(course, isNotNull);
    expect(course!.name, 'SISTEM BASIS DATA MODERN');
    expect(course.code, 'CW6552022433');
    expect(course.credits, 2);
    expect(course.meetings, hasLength(2));
    expect(course.meetings.first.room, 'KB3.3');
    // Dots and single-digit hours are normalized to HH:mm.
    expect(course.meetings.last.startTime, '09:00');
    expect(course.meetings.last.endTime, '10:30');
    expect(course.meetings.last.room, isNull);
  });

  test('returns null without a course name', () {
    expect(ImportedCourseModel.fromJson({'kode': 'X1'}), isNull);
    expect(ImportedCourseModel.fromJson({'nama': '   '}), isNull);
  });

  test('parses sks provided as a string', () {
    final course = ImportedCourseModel.fromJson({
      'nama': 'PRAKTIKUM PEMROGRAMAN WEB',
      'sks': '1',
    });
    expect(course!.credits, 1);
    expect(course.meetings, isEmpty);
  });

  test('drops meetings with invalid day, time, or reversed range', () {
    final course = ImportedCourseModel.fromJson({
      'nama': 'RISET OPERASIONAL',
      'pertemuan': [
        {'hari': 0, 'jam_mulai': '08:00', 'jam_selesai': '09:00'},
        {'hari': 8, 'jam_mulai': '08:00', 'jam_selesai': '09:00'},
        {'hari': 2, 'jam_mulai': 'pagi', 'jam_selesai': '09:00'},
        {'hari': 2, 'jam_mulai': '10:00', 'jam_selesai': '09:00'},
        {'hari': 2, 'jam_mulai': '25:00', 'jam_selesai': '26:00'},
        {'hari': 4, 'jam_mulai': '15:00', 'jam_selesai': '16:30'},
      ],
    });

    expect(course!.meetings, hasLength(1));
    expect(course.meetings.single.dayOfWeek, 4);
  });
}
