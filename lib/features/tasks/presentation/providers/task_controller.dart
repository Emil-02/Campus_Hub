import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../services/notification_service.dart';
import '../../../../services/service_providers.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/repositories/task_repository.dart';
import 'task_dependencies.dart';
import 'task_state.dart';

/// Coordinates task CRUD, checklist toggles, and exposes their state.
final class TaskController extends Notifier<TaskState> {
  TaskRepository get _repository => ref.read(taskRepositoryProvider);

  NotificationService get _notifications =>
      ref.read(notificationServiceProvider);

  @override
  TaskState build() => const TaskState.initial();

  /// Loads all non-deleted tasks.
  Future<void> loadTasks() async {
    state = TaskState.loading(filter: state.filter);
    try {
      final tasks = await _repository.getTasks();
      state = _loaded(tasks);
    } catch (error) {
      state = _failure(error);
    }
  }

  /// Switches the visible status filter without refetching.
  void setFilter(TaskListFilter filter) {
    state = state.copyWithView(filter: filter);
  }

  /// TASK-09: switches the sort order.
  void setSort(TaskSortOption sort) {
    state = state.copyWithView(sort: sort);
  }

  /// Narrows the list to one course (null clears it).
  void setCourseFilter(String? courseId) {
    state = state.copyWithView(courseIdFilter: courseId);
  }

  /// Narrows the list to one priority (null clears it).
  void setPriorityFilter(TaskPriority? priority) {
    state = state.copyWithView(priorityFilter: priority);
  }

  /// Creates a task (with optional checklist). Returns true when saved.
  Future<bool> createTask({
    required String title,
    String? description,
    DateTime? deadline,
    required TaskPriority priority,
    String? courseId,
    List<String> checklistTitles = const [],
  }) async {
    state = _loaded(state.tasks, isMutating: true);
    try {
      final created = await _repository.createTask(
        title: title,
        description: description,
        deadline: deadline,
        priority: priority,
        courseId: courseId,
        checklistTitles: checklistTitles,
      );
      _syncReminders(created);
      await _reload();
      return true;
    } catch (error) {
      state = _failure(error);
      return false;
    }
  }

  /// Updates task fields. Returns true when saved.
  Future<bool> updateTask({
    required String id,
    required String title,
    String? description,
    DateTime? deadline,
    required TaskPriority priority,
    String? courseId,
  }) async {
    state = _loaded(state.tasks, isMutating: true);
    try {
      final updated = await _repository.updateTask(
        id: id,
        title: title,
        description: description,
        deadline: deadline,
        priority: priority,
        courseId: courseId,
      );
      _syncReminders(updated);
      await _reload();
      return true;
    } catch (error) {
      state = _failure(error);
      return false;
    }
  }

  /// TASK-07: toggles manual completion. Returns true when stored.
  Future<bool> setTaskCompleted({
    required String id,
    required bool completed,
  }) async {
    try {
      final updated = await _repository.setTaskCompleted(
        id: id,
        completed: completed,
      );
      _syncReminders(updated);
      _replaceTask(updated);
      return true;
    } catch (error) {
      state = _failure(error);
      return false;
    }
  }

  /// Soft-deletes a task. Returns true when removed.
  Future<bool> deleteTask(String id) async {
    state = _loaded(state.tasks, isMutating: true);
    try {
      await _repository.deleteTask(id);
      unawaited(_notifications.cancelTaskReminders(id));
      await _reload();
      return true;
    } catch (error) {
      state = _failure(error);
      return false;
    }
  }

  /// T-119: restores a soft-deleted task and its reminders.
  Future<bool> restoreTask(String id) async {
    try {
      await _repository.restoreTask(id);
      await _reload();
      final restored = state.tasks.where((task) => task.id == id).firstOrNull;
      if (restored != null) {
        _syncReminders(restored);
      }
      return true;
    } catch (error) {
      state = _failure(error);
      return false;
    }
  }

  /// Toggles one checklist item then reloads so trigger results are visible.
  Future<bool> toggleChecklistItem({
    required String id,
    required bool isCompleted,
  }) async {
    try {
      await _repository.toggleChecklistItem(id: id, isCompleted: isCompleted);
      await _reload();
      return true;
    } catch (error) {
      state = _failure(error);
      return false;
    }
  }

  /// Adds a checklist item to an existing task.
  Future<bool> addChecklistItem({
    required String taskId,
    required String title,
  }) async {
    try {
      final task = state.tasks.where((task) => task.id == taskId).firstOrNull;
      final sortOrder = task == null ? 0 : task.checklist.length;
      await _repository.addChecklistItem(
        taskId: taskId,
        title: title,
        sortOrder: sortOrder,
      );
      await _reload();
      return true;
    } catch (error) {
      state = _failure(error);
      return false;
    }
  }

  /// Removes a checklist item.
  Future<bool> deleteChecklistItem(String id) async {
    try {
      await _repository.deleteChecklistItem(id);
      await _reload();
      return true;
    } catch (error) {
      state = _failure(error);
      return false;
    }
  }

  Future<void> _reload() async {
    final tasks = await _repository.getTasks();
    state = _loaded(tasks);
  }

  /// BR-04: reminders exist only for active tasks with a future deadline.
  void _syncReminders(TaskEntity task) {
    unawaited(_notifications.cancelTaskReminders(task.id));
    final deadline = task.deadline;
    if (deadline != null && !task.isCompleted) {
      unawaited(
        _notifications.scheduleTaskReminders(
          taskId: task.id,
          title: task.title,
          courseName: task.course?.name,
          deadline: deadline,
        ),
      );
    }
  }

  TaskState _loaded(List<TaskEntity> tasks, {bool isMutating = false}) {
    return TaskState.loaded(
      tasks,
      filter: state.filter,
      sort: state.sort,
      courseIdFilter: state.courseIdFilter,
      priorityFilter: state.priorityFilter,
      isMutating: isMutating,
    );
  }

  TaskState _failure(Object error) {
    return TaskState.failure(
      _safeErrorMessage(error),
      tasks: state.tasks,
      filter: state.filter,
      sort: state.sort,
      courseIdFilter: state.courseIdFilter,
      priorityFilter: state.priorityFilter,
    );
  }

  void _replaceTask(TaskEntity updated) {
    final tasks = [
      for (final task in state.tasks)
        if (task.id == updated.id) updated else task,
    ];
    state = _loaded(tasks, isMutating: state.isMutating);
  }

  String _safeErrorMessage(Object error) {
    debugPrint('Task error: $error');
    if (error is PostgrestException) {
      return 'Gagal menyimpan ke server. Coba lagi.';
    }
    if (error is SocketException || error is TimeoutException) {
      return 'Tidak dapat terhubung ke server. Periksa koneksi internet.';
    }
    if (error is StateError) {
      return 'Sesi tidak valid. Silakan login ulang.';
    }
    if (error is FormatException) {
      return 'Data tugas tidak valid.';
    }
    return 'Terjadi kesalahan. Coba lagi.';
  }
}
