import '../../domain/entities/task_entity.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_remote_data_source.dart';

/// Bridges the task domain contract to the remote data source.
final class TaskRepositoryImpl implements TaskRepository {
  const TaskRepositoryImpl(this._remoteDataSource);

  final TaskRemoteDataSource _remoteDataSource;

  @override
  Future<List<TaskEntity>> getTasks() async {
    final models = await _remoteDataSource.getTasks();
    return models.map((model) => model.toEntity()).toList(growable: false);
  }

  @override
  Future<TaskEntity> createTask({
    required String title,
    String? description,
    DateTime? deadline,
    required TaskPriority priority,
    String? courseId,
    List<String> checklistTitles = const [],
  }) async {
    final model = await _remoteDataSource.createTask(
      title: title,
      description: description,
      deadline: deadline,
      priority: priority,
      courseId: courseId,
      checklistTitles: checklistTitles,
    );
    return model.toEntity();
  }

  @override
  Future<TaskEntity> updateTask({
    required String id,
    required String title,
    String? description,
    DateTime? deadline,
    required TaskPriority priority,
    String? courseId,
  }) async {
    final model = await _remoteDataSource.updateTask(
      id: id,
      title: title,
      description: description,
      deadline: deadline,
      priority: priority,
      courseId: courseId,
    );
    return model.toEntity();
  }

  @override
  Future<TaskEntity> setTaskCompleted({
    required String id,
    required bool completed,
  }) async {
    final model = await _remoteDataSource.setTaskCompleted(
      id: id,
      completed: completed,
    );
    return model.toEntity();
  }

  @override
  Future<void> deleteTask(String id) {
    return _remoteDataSource.softDeleteTask(id);
  }

  @override
  Future<void> addChecklistItem({
    required String taskId,
    required String title,
    required int sortOrder,
  }) {
    return _remoteDataSource.addChecklistItem(
      taskId: taskId,
      title: title,
      sortOrder: sortOrder,
    );
  }

  @override
  Future<void> toggleChecklistItem({
    required String id,
    required bool isCompleted,
  }) {
    return _remoteDataSource.toggleChecklistItem(
      id: id,
      isCompleted: isCompleted,
    );
  }

  @override
  Future<void> deleteChecklistItem(String id) {
    return _remoteDataSource.deleteChecklistItem(id);
  }
}
