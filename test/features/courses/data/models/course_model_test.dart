import 'package:campusmate/features/courses/data/models/course_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> validJson() => <String, dynamic>{
    'id': 'course-1',
    'name': 'Struktur Data',
    'code': 'IF1234',
    'credits': 3,
    'lecturer': 'Dr. Budi',
    'color': '#4A90D9',
    'created_at': '2026-08-06T10:00:00.000Z',
  };

  test('fromJson parses a complete row', () {
    final model = CourseModel.fromJson(validJson());

    expect(model.id, 'course-1');
    expect(model.name, 'Struktur Data');
    expect(model.code, 'IF1234');
    expect(model.credits, 3);
    expect(model.lecturer, 'Dr. Budi');
    expect(model.color, '#4A90D9');
    expect(model.createdAt, DateTime.parse('2026-08-06T10:00:00.000Z'));
  });

  test('fromJson accepts null optional fields', () {
    final json = validJson()
      ..['code'] = null
      ..['credits'] = null
      ..['lecturer'] = null
      ..['created_at'] = null;

    final model = CourseModel.fromJson(json);

    expect(model.code, isNull);
    expect(model.credits, isNull);
    expect(model.lecturer, isNull);
    expect(model.createdAt, isNull);
  });

  test('fromJson normalizes blank optional strings to null', () {
    final json = validJson()..['lecturer'] = '   ';

    expect(CourseModel.fromJson(json).lecturer, isNull);
  });

  test('fromJson rejects a missing name', () {
    final json = validJson()..['name'] = '';

    expect(() => CourseModel.fromJson(json), throwsFormatException);
  });

  test('fromJson rejects a non-numeric credits value', () {
    final json = validJson()..['credits'] = 'tiga';

    expect(() => CourseModel.fromJson(json), throwsFormatException);
  });

  test('fromJson rejects an invalid created_at value', () {
    final json = validJson()..['created_at'] = 'bukan-tanggal';

    expect(() => CourseModel.fromJson(json), throwsFormatException);
  });

  test('toEntity keeps every field', () {
    final entity = CourseModel.fromJson(validJson()).toEntity();

    expect(entity.id, 'course-1');
    expect(entity.name, 'Struktur Data');
    expect(entity.color, '#4A90D9');
  });
}
