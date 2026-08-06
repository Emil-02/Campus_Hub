import 'package:campusmate/features/tasks/data/models/task_model.dart';
import 'package:campusmate/features/tasks/domain/entities/task_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> validJson() => <String, dynamic>{
    'id': 'task-1',
    'course_id': 'course-1',
    'courses': {
      'id': 'course-1',
      'name': 'Struktur Data',
      'code': 'IF1234',
      'credits': 3,
      'lecturer': 'Dr. Budi',
      'color': '#4A90D9',
      'created_at': '2026-08-01T10:00:00.000Z',
    },
    'title': 'Laporan praktikum',
    'description': 'Bab 1-3',
    'deadline': '2026-08-10T16:59:00.000Z',
    'priority': 'high',
    'status': 'in_progress',
    'completion_percentage': 50,
    'completed_at': null,
    'task_checklists': [
      {
        'id': 'check-2',
        'task_id': 'task-1',
        'title': 'Bab 2',
        'is_completed': false,
        'sort_order': 1,
      },
      {
        'id': 'check-1',
        'task_id': 'task-1',
        'title': 'Bab 1',
        'is_completed': true,
        'sort_order': 0,
      },
    ],
  };

  test('fromJson parses a complete row with nested course and checklist', () {
    final model = TaskModel.fromJson(validJson());

    expect(model.id, 'task-1');
    expect(model.course?.name, 'Struktur Data');
    expect(model.title, 'Laporan praktikum');
    expect(model.priority, TaskPriority.high);
    expect(model.status, TaskStatus.inProgress);
    expect(model.completionPercentage, 50);
    expect(model.checklist, hasLength(2));
  });

  test('fromJson sorts checklist by sort_order', () {
    final model = TaskModel.fromJson(validJson());

    expect(model.checklist.first.title, 'Bab 1');
    expect(model.checklist.last.title, 'Bab 2');
  });

  test('fromJson accepts missing optional fields', () {
    final json = validJson()
      ..['course_id'] = null
      ..['courses'] = null
      ..['description'] = null
      ..['deadline'] = null
      ..['task_checklists'] = null;

    final model = TaskModel.fromJson(json);

    expect(model.course, isNull);
    expect(model.deadline, isNull);
    expect(model.checklist, isEmpty);
  });

  test('fromJson falls back to medium/todo on unknown enum values', () {
    final json = validJson()
      ..['priority'] = 'nonsense'
      ..['status'] = 'nonsense';

    final model = TaskModel.fromJson(json);

    expect(model.priority, TaskPriority.medium);
    expect(model.status, TaskStatus.todo);
  });

  test('fromJson rejects an empty title', () {
    final json = validJson()..['title'] = '';

    expect(() => TaskModel.fromJson(json), throwsFormatException);
  });

  test('isOverdue is true for a past deadline on an active task', () {
    final json = validJson()
      ..['deadline'] = DateTime.now()
          .subtract(const Duration(days: 1))
          .toUtc()
          .toIso8601String();

    expect(TaskModel.fromJson(json).isOverdue, isTrue);
  });

  test('isOverdue is false for completed tasks', () {
    final json = validJson()
      ..['status'] = 'completed'
      ..['deadline'] = DateTime.now()
          .subtract(const Duration(days: 1))
          .toUtc()
          .toIso8601String();

    expect(TaskModel.fromJson(json).isOverdue, isFalse);
  });
}
