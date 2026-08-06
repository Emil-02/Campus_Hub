import '../../../courses/data/models/course_model.dart';
import '../../domain/entities/task_entity.dart';

final class ChecklistModel extends ChecklistEntity {
  const ChecklistModel({
    required super.id,
    required super.taskId,
    required super.title,
    required super.isCompleted,
    required super.sortOrder,
  });

  factory ChecklistModel.fromJson(Map<String, dynamic> json) {
    return ChecklistModel(
      id: _requiredString(json, 'id'),
      taskId: _requiredString(json, 'task_id'),
      title: _requiredString(json, 'title'),
      isCompleted: json['is_completed'] == true,
      sortOrder: _intOrZero(json['sort_order']),
    );
  }

  ChecklistEntity toEntity() {
    return ChecklistEntity(
      id: id,
      taskId: taskId,
      title: title,
      isCompleted: isCompleted,
      sortOrder: sortOrder,
    );
  }

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException(
        'ChecklistModel "$key" must be a non-empty String.',
      );
    }
    return value;
  }

  static int _intOrZero(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return 0;
  }
}

final class TaskModel extends TaskEntity {
  const TaskModel({
    required super.id,
    super.courseId,
    super.course,
    required super.title,
    super.description,
    super.deadline,
    super.priority,
    super.status,
    super.completionPercentage,
    super.completedAt,
    super.createdAt,
    super.checklist,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    final courseJson = json['courses'];
    final checklistJson = json['task_checklists'];

    final checklist =
        (checklistJson is List
              ? checklistJson
                    .whereType<Map<String, dynamic>>()
                    .map(ChecklistModel.fromJson)
                    .toList()
              : <ChecklistModel>[])
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return TaskModel(
      id: _requiredString(json, 'id'),
      courseId: _nullableString(json, 'course_id'),
      course: courseJson is Map<String, dynamic>
          ? CourseModel.fromJson(courseJson).toEntity()
          : null,
      title: _requiredString(json, 'title'),
      description: _nullableString(json, 'description'),
      deadline: _nullableDate(json, 'deadline'),
      priority: TaskPriority.fromDb(json['priority'] as String? ?? 'medium'),
      status: TaskStatus.fromDb(json['status'] as String? ?? 'todo'),
      completionPercentage: _intOrZero(json['completion_percentage']),
      completedAt: _nullableDate(json, 'completed_at'),
      createdAt: _nullableDate(json, 'created_at'),
      checklist: checklist,
    );
  }

  TaskEntity toEntity() {
    return TaskEntity(
      id: id,
      courseId: courseId,
      course: course,
      title: title,
      description: description,
      deadline: deadline,
      priority: priority,
      status: status,
      completionPercentage: completionPercentage,
      completedAt: completedAt,
      createdAt: createdAt,
      checklist: checklist,
    );
  }

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('TaskModel "$key" must be a non-empty String.');
    }
    return value;
  }

  static String? _nullableString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) {
      return null;
    }
    if (value is! String) {
      throw FormatException('TaskModel "$key" must be a String or null.');
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static DateTime? _nullableDate(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) {
      return null;
    }
    if (value is! String) {
      throw FormatException('TaskModel "$key" must be a String or null.');
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      throw FormatException('TaskModel "$key" is not a valid timestamp.');
    }
    return parsed.toLocal();
  }

  static int _intOrZero(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return 0;
  }
}
