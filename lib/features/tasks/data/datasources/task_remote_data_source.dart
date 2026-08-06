import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/task_entity.dart';
import '../models/task_model.dart';

const _taskSelect = '*, courses(*), task_checklists(*)';

/// Remote operations for the `tasks` and `task_checklists` tables.
abstract interface class TaskRemoteDataSource {
  Future<List<TaskModel>> getTasks();

  Future<TaskModel> createTask({
    required String title,
    String? description,
    DateTime? deadline,
    required TaskPriority priority,
    String? courseId,
    List<String> checklistTitles,
  });

  Future<TaskModel> updateTask({
    required String id,
    required String title,
    String? description,
    DateTime? deadline,
    required TaskPriority priority,
    String? courseId,
  });

  Future<TaskModel> setTaskCompleted({
    required String id,
    required bool completed,
  });

  Future<void> softDeleteTask(String id);

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

/// Implements task operations using the injected Supabase client.
final class TaskRemoteDataSourceImpl implements TaskRemoteDataSource {
  const TaskRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  String get _userId {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('A signed-in user is required for task operations.');
    }
    return userId;
  }

  @override
  Future<List<TaskModel>> getTasks() async {
    final rows = await _client
        .from('tasks')
        .select(_taskSelect)
        .eq('is_deleted', false)
        .order('deadline', ascending: true, nullsFirst: false)
        .order('created_at', ascending: false);
    return rows.map(TaskModel.fromJson).toList(growable: false);
  }

  @override
  Future<TaskModel> createTask({
    required String title,
    String? description,
    DateTime? deadline,
    required TaskPriority priority,
    String? courseId,
    List<String> checklistTitles = const [],
  }) async {
    final row = await _client
        .from('tasks')
        .insert({
          'user_id': _userId,
          'title': title,
          'description': description,
          'deadline': deadline?.toUtc().toIso8601String(),
          'priority': priority.dbValue,
          'course_id': courseId,
        })
        .select(_taskSelect)
        .single();
    final task = TaskModel.fromJson(row);

    if (checklistTitles.isEmpty) {
      return task;
    }
    await _client.from('task_checklists').insert([
      for (var i = 0; i < checklistTitles.length; i++)
        {'task_id': task.id, 'title': checklistTitles[i], 'sort_order': i},
    ]);
    return _fetchTask(task.id);
  }

  @override
  Future<TaskModel> updateTask({
    required String id,
    required String title,
    String? description,
    DateTime? deadline,
    required TaskPriority priority,
    String? courseId,
  }) async {
    final row = await _client
        .from('tasks')
        .update({
          'title': title,
          'description': description,
          'deadline': deadline?.toUtc().toIso8601String(),
          'priority': priority.dbValue,
          'course_id': courseId,
        })
        .eq('id', id)
        .select(_taskSelect)
        .single();
    return TaskModel.fromJson(row);
  }

  @override
  Future<TaskModel> setTaskCompleted({
    required String id,
    required bool completed,
  }) async {
    final row = await _client
        .from('tasks')
        .update({
          'status': completed
              ? TaskStatus.completed.dbValue
              : TaskStatus.todo.dbValue,
          'completed_at': completed
              ? DateTime.now().toUtc().toIso8601String()
              : null,
        })
        .eq('id', id)
        .select(_taskSelect)
        .single();
    return TaskModel.fromJson(row);
  }

  @override
  Future<void> softDeleteTask(String id) async {
    await _client.from('tasks').update({'is_deleted': true}).eq('id', id);
  }

  @override
  Future<void> restoreTask(String id) async {
    await _client.from('tasks').update({'is_deleted': false}).eq('id', id);
  }

  @override
  Future<void> addChecklistItem({
    required String taskId,
    required String title,
    required int sortOrder,
  }) async {
    await _client.from('task_checklists').insert({
      'task_id': taskId,
      'title': title,
      'sort_order': sortOrder,
    });
  }

  @override
  Future<void> toggleChecklistItem({
    required String id,
    required bool isCompleted,
  }) async {
    await _client
        .from('task_checklists')
        .update({'is_completed': isCompleted})
        .eq('id', id);
  }

  @override
  Future<void> deleteChecklistItem(String id) async {
    await _client.from('task_checklists').delete().eq('id', id);
  }

  Future<TaskModel> _fetchTask(String id) async {
    final row = await _client
        .from('tasks')
        .select(_taskSelect)
        .eq('id', id)
        .single();
    return TaskModel.fromJson(row);
  }
}
