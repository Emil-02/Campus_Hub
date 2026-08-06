import 'package:equatable/equatable.dart';

import '../../domain/entities/task_entity.dart';

enum TaskListStatus { initial, loading, loaded, failure }

/// TASK-02 filters shown as chips above the list.
enum TaskListFilter {
  all('Semua'),
  active('Aktif'),
  completed('Selesai'),
  overdue('Terlambat');

  const TaskListFilter(this.label);

  final String label;
}

/// Immutable state for the task list and its mutations.
class TaskState extends Equatable {
  const TaskState._({
    required this.status,
    this.tasks = const [],
    this.filter = TaskListFilter.all,
    this.errorMessage,
    this.isMutating = false,
  });

  const TaskState.initial() : this._(status: TaskListStatus.initial);

  const TaskState.loading({TaskListFilter filter = TaskListFilter.all})
    : this._(status: TaskListStatus.loading, filter: filter);

  const TaskState.loaded(
    List<TaskEntity> tasks, {
    TaskListFilter filter = TaskListFilter.all,
    bool isMutating = false,
  }) : this._(
         status: TaskListStatus.loaded,
         tasks: tasks,
         filter: filter,
         isMutating: isMutating,
       );

  const TaskState.failure(
    String message, {
    List<TaskEntity> tasks = const [],
    TaskListFilter filter = TaskListFilter.all,
  }) : this._(
         status: TaskListStatus.failure,
         errorMessage: message,
         tasks: tasks,
         filter: filter,
       );

  final TaskListStatus status;
  final List<TaskEntity> tasks;
  final TaskListFilter filter;
  final String? errorMessage;

  /// True while a create/update/delete request is in flight.
  final bool isMutating;

  /// Tasks matching the active filter.
  List<TaskEntity> get visibleTasks {
    switch (filter) {
      case TaskListFilter.all:
        return tasks;
      case TaskListFilter.active:
        return tasks.where((task) => !task.isCompleted).toList(growable: false);
      case TaskListFilter.completed:
        return tasks.where((task) => task.isCompleted).toList(growable: false);
      case TaskListFilter.overdue:
        return tasks.where((task) => task.isOverdue).toList(growable: false);
    }
  }

  @override
  List<Object?> get props => [status, tasks, filter, errorMessage, isMutating];
}
