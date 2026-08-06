import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../domain/entities/task_entity.dart';
import '../../domain/repositories/task_repository.dart';
import 'task_dependencies.dart';
import 'task_state.dart';

/// Coordinates task CRUD, checklist toggles, and exposes their state.
final class TaskController extends Notifier<TaskState> {
  TaskRepository get _repository => ref.read(taskRepositoryProvider);

  @override
  TaskState build() => const TaskState.initial();

  /// Loads all non-deleted tasks.
  Future<void> loadTasks() async {
    state = TaskState.loading(filter: state.filter);
    try {
      final tasks = await _repository.getTasks();
      state = TaskState.loaded(tasks, filter: state.filter);
    } catch (error) {
      state = TaskState.failure(_safeErrorMessage(error), filter: state.filter);
    }
  }

  /// Switches the visible filter without refetching.
  void setFilter(TaskListFilter filter) {
    if (state.status == TaskListStatus.loaded) {
      state = TaskState.loaded(
        state.tasks,
        filter: filter,
        isMutating: state.isMutating,
      );
    } else if (state.status == TaskListStatus.failure) {
      state = TaskState.failure(
        state.errorMessage ?? 'Terjadi kesalahan. Coba lagi.',
        tasks: state.tasks,
        filter: filter,
      );
    }
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
    state = TaskState.loaded(
      state.tasks,
      filter: state.filter,
      isMutating: true,
    );
    try {
      await _repository.createTask(
        title: title,
        description: description,
        deadline: deadline,
        priority: priority,
        courseId: courseId,
        checklistTitles: checklistTitles,
      );
      await _reload();
      return true;
    } catch (error) {
      state = TaskState.failure(
        _safeErrorMessage(error),
        tasks: state.tasks,
        filter: state.filter,
      );
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
    state = TaskState.loaded(
      state.tasks,
      filter: state.filter,
      isMutating: true,
    );
    try {
      await _repository.updateTask(
        id: id,
        title: title,
        description: description,
        deadline: deadline,
        priority: priority,
        courseId: courseId,
      );
      await _reload();
      return true;
    } catch (error) {
      state = TaskState.failure(
        _safeErrorMessage(error),
        tasks: state.tasks,
        filter: state.filter,
      );
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
      _replaceTask(updated);
      return true;
    } catch (error) {
      state = TaskState.failure(
        _safeErrorMessage(error),
        tasks: state.tasks,
        filter: state.filter,
      );
      return false;
    }
  }

  /// Soft-deletes a task. Returns true when removed.
  Future<bool> deleteTask(String id) async {
    state = TaskState.loaded(
      state.tasks,
      filter: state.filter,
      isMutating: true,
    );
    try {
      await _repository.deleteTask(id);
      await _reload();
      return true;
    } catch (error) {
      state = TaskState.failure(
        _safeErrorMessage(error),
        tasks: state.tasks,
        filter: state.filter,
      );
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
      state = TaskState.failure(
        _safeErrorMessage(error),
        tasks: state.tasks,
        filter: state.filter,
      );
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
      state = TaskState.failure(
        _safeErrorMessage(error),
        tasks: state.tasks,
        filter: state.filter,
      );
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
      state = TaskState.failure(
        _safeErrorMessage(error),
        tasks: state.tasks,
        filter: state.filter,
      );
      return false;
    }
  }

  Future<void> _reload() async {
    final tasks = await _repository.getTasks();
    state = TaskState.loaded(tasks, filter: state.filter);
  }

  void _replaceTask(TaskEntity updated) {
    final tasks = [
      for (final task in state.tasks)
        if (task.id == updated.id) updated else task,
    ];
    state = TaskState.loaded(
      tasks,
      filter: state.filter,
      isMutating: state.isMutating,
    );
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
