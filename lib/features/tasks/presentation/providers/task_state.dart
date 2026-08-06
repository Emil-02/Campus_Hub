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

/// TASK-09 sort options.
enum TaskSortOption {
  deadline('Deadline terdekat'),
  priority('Prioritas tertinggi'),
  created('Terbaru dibuat'),
  name('Nama A-Z');

  const TaskSortOption(this.label);

  final String label;
}

/// Immutable state for the task list and its mutations.
class TaskState extends Equatable {
  const TaskState._({
    required this.status,
    this.tasks = const [],
    this.filter = TaskListFilter.all,
    this.sort = TaskSortOption.deadline,
    this.courseIdFilter,
    this.priorityFilter,
    this.errorMessage,
    this.isMutating = false,
  });

  const TaskState.initial() : this._(status: TaskListStatus.initial);

  const TaskState.loading({TaskListFilter filter = TaskListFilter.all})
    : this._(status: TaskListStatus.loading, filter: filter);

  const TaskState.loaded(
    List<TaskEntity> tasks, {
    TaskListFilter filter = TaskListFilter.all,
    TaskSortOption sort = TaskSortOption.deadline,
    String? courseIdFilter,
    TaskPriority? priorityFilter,
    bool isMutating = false,
  }) : this._(
         status: TaskListStatus.loaded,
         tasks: tasks,
         filter: filter,
         sort: sort,
         courseIdFilter: courseIdFilter,
         priorityFilter: priorityFilter,
         isMutating: isMutating,
       );

  const TaskState.failure(
    String message, {
    List<TaskEntity> tasks = const [],
    TaskListFilter filter = TaskListFilter.all,
    TaskSortOption sort = TaskSortOption.deadline,
    String? courseIdFilter,
    TaskPriority? priorityFilter,
  }) : this._(
         status: TaskListStatus.failure,
         errorMessage: message,
         tasks: tasks,
         filter: filter,
         sort: sort,
         courseIdFilter: courseIdFilter,
         priorityFilter: priorityFilter,
       );

  final TaskListStatus status;
  final List<TaskEntity> tasks;
  final TaskListFilter filter;
  final TaskSortOption sort;

  /// Only show tasks of this course when set (TASK-09 combine filters).
  final String? courseIdFilter;
  final TaskPriority? priorityFilter;
  final String? errorMessage;

  /// True while a create/update/delete request is in flight.
  final bool isMutating;

  /// True when a course/priority narrowing is active.
  bool get hasExtraFilters => courseIdFilter != null || priorityFilter != null;

  /// Copy that keeps status/tasks but adjusts view options.
  TaskState copyWithView({
    TaskListFilter? filter,
    TaskSortOption? sort,
    Object? courseIdFilter = _sentinel,
    Object? priorityFilter = _sentinel,
  }) {
    return TaskState._(
      status: status,
      tasks: tasks,
      filter: filter ?? this.filter,
      sort: sort ?? this.sort,
      courseIdFilter: courseIdFilter == _sentinel
          ? this.courseIdFilter
          : courseIdFilter as String?,
      priorityFilter: priorityFilter == _sentinel
          ? this.priorityFilter
          : priorityFilter as TaskPriority?,
      errorMessage: errorMessage,
      isMutating: isMutating,
    );
  }

  static const _sentinel = Object();

  /// Tasks matching the active filters, ordered by [sort].
  List<TaskEntity> get visibleTasks {
    Iterable<TaskEntity> result = tasks;
    switch (filter) {
      case TaskListFilter.all:
        break;
      case TaskListFilter.active:
        result = result.where((task) => !task.isCompleted);
      case TaskListFilter.completed:
        result = result.where((task) => task.isCompleted);
      case TaskListFilter.overdue:
        result = result.where((task) => task.isOverdue);
    }
    if (courseIdFilter != null) {
      result = result.where((task) => task.courseId == courseIdFilter);
    }
    if (priorityFilter != null) {
      result = result.where((task) => task.priority == priorityFilter);
    }

    final sorted = result.toList();
    switch (sort) {
      case TaskSortOption.deadline:
        sorted.sort(_byDeadline);
      case TaskSortOption.priority:
        sorted.sort((a, b) {
          final byPriority = b.priority.index.compareTo(a.priority.index);
          return byPriority != 0 ? byPriority : _byDeadline(a, b);
        });
      case TaskSortOption.created:
        sorted.sort((a, b) {
          final aCreated = a.createdAt;
          final bCreated = b.createdAt;
          if (aCreated == null && bCreated == null) {
            return 0;
          }
          if (aCreated == null) {
            return 1;
          }
          if (bCreated == null) {
            return -1;
          }
          return bCreated.compareTo(aCreated);
        });
      case TaskSortOption.name:
        sorted.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
    }
    return List.unmodifiable(sorted);
  }

  static int _byDeadline(TaskEntity a, TaskEntity b) {
    final aDeadline = a.deadline;
    final bDeadline = b.deadline;
    if (aDeadline == null && bDeadline == null) {
      return 0;
    }
    if (aDeadline == null) {
      return 1;
    }
    if (bDeadline == null) {
      return -1;
    }
    return aDeadline.compareTo(bDeadline);
  }

  @override
  List<Object?> get props => [
    status,
    tasks,
    filter,
    sort,
    courseIdFilter,
    priorityFilter,
    errorMessage,
    isMutating,
  ];
}
