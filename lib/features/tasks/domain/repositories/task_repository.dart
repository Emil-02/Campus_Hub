import '../entities/task_entity.dart';

/// Contract for task data operations.
abstract interface class TaskRepository {
  /// Returns non-deleted tasks ordered by deadline (nulls last).
  Future<List<TaskEntity>> getTasks();

  Future<TaskEntity> createTask({
    required String title,
    String? description,
    DateTime? deadline,
    required TaskPriority priority,
    String? courseId,
    List<String> checklistTitles,
  });

  Future<TaskEntity> updateTask({
    required String id,
    required String title,
    String? description,
    DateTime? deadline,
    required TaskPriority priority,
    String? courseId,
  });

  /// Marks the task completed (or back to todo) manually.
  Future<TaskEntity> setTaskCompleted({
    required String id,
    required bool completed,
  });

  /// BR-06: soft delete.
  Future<void> deleteTask(String id);

  /// T-119: restores a soft-deleted task (undo).
  Future<void> restoreTask(String id);

  Future<void> addChecklistItem({
    required String taskId,
    required String title,
    required int sortOrder,
  });

  Future<void> toggleChecklistItem({
    required String id,
    required bool isCompleted,
  });

  Future<void> deleteChecklistItem(String id);
}
