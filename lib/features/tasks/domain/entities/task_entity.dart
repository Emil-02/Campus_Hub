import 'package:equatable/equatable.dart';

import '../../../courses/domain/entities/course_entity.dart';

enum TaskPriority {
  low('low', 'Rendah'),
  medium('medium', 'Sedang'),
  high('high', 'Tinggi'),
  urgent('urgent', 'Urgent');

  const TaskPriority(this.dbValue, this.label);

  final String dbValue;
  final String label;

  static TaskPriority fromDb(String value) {
    return TaskPriority.values.firstWhere(
      (priority) => priority.dbValue == value,
      orElse: () => TaskPriority.medium,
    );
  }
}

enum TaskStatus {
  todo('todo'),
  inProgress('in_progress'),
  completed('completed');

  const TaskStatus(this.dbValue);

  final String dbValue;

  static TaskStatus fromDb(String value) {
    return TaskStatus.values.firstWhere(
      (status) => status.dbValue == value,
      orElse: () => TaskStatus.todo,
    );
  }
}

/// A sub-task inside a task checklist.
class ChecklistEntity extends Equatable {
  const ChecklistEntity({
    required this.id,
    required this.taskId,
    required this.title,
    required this.isCompleted,
    required this.sortOrder,
  });

  final String id;
  final String taskId;
  final String title;
  final bool isCompleted;
  final int sortOrder;

  @override
  List<Object?> get props => [id, taskId, title, isCompleted, sortOrder];
}

/// A student task with optional course, deadline, and checklist.
class TaskEntity extends Equatable {
  const TaskEntity({
    required this.id,
    this.courseId,
    this.course,
    required this.title,
    this.description,
    this.deadline,
    this.priority = TaskPriority.medium,
    this.status = TaskStatus.todo,
    this.completionPercentage = 0,
    this.completedAt,
    this.createdAt,
    this.checklist = const [],
  });

  final String id;
  final String? courseId;
  final CourseEntity? course;
  final String title;
  final String? description;
  final DateTime? deadline;
  final TaskPriority priority;
  final TaskStatus status;
  final int completionPercentage;
  final DateTime? completedAt;
  final DateTime? createdAt;
  final List<ChecklistEntity> checklist;

  bool get isCompleted => status == TaskStatus.completed;

  /// BR-03: past deadline while not completed.
  bool get isOverdue =>
      !isCompleted && deadline != null && deadline!.isBefore(DateTime.now());

  @override
  List<Object?> get props => [
    id,
    courseId,
    course,
    title,
    description,
    deadline,
    priority,
    status,
    completionPercentage,
    completedAt,
    createdAt,
    checklist,
  ];
}
