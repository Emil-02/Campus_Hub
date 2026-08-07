// T-159: integration-style test of the full task flow
// create → checklist → filter → complete → delete → undo,
// driven through TaskController against a stateful in-memory repository.
import 'package:campusmate/features/tasks/domain/entities/task_entity.dart';
import 'package:campusmate/features/tasks/domain/repositories/task_repository.dart';
import 'package:campusmate/features/tasks/presentation/providers/task_provider.dart';
import 'package:campusmate/features/tasks/presentation/providers/task_state.dart';
import 'package:campusmate/services/notification_service.dart';
import 'package:campusmate/services/service_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final class RecordingNotificationService implements NotificationService {
  final scheduledTaskIds = <String>[];
  final cancelledTaskIds = <String>[];

  @override
  Future<bool> initialize() async => true;

  @override
  Future<void> scheduleWeeklyClassReminder({
    required String scheduleId,
    required int dayOfWeek,
    required String startTime,
    required String courseName,
    String? room,
    int minutesBefore = 30,
  }) async {}

  @override
  Future<void> cancelScheduleReminder(String scheduleId) async {}

  @override
  Future<void> scheduleTaskReminders({
    required String taskId,
    required String title,
    String? courseName,
    required DateTime deadline,
  }) async {
    scheduledTaskIds.add(taskId);
  }

  @override
  Future<void> cancelTaskReminders(String taskId) async {
    cancelledTaskIds.add(taskId);
  }
}

/// In-memory task store mimicking DB behavior: soft delete, checklist
/// completion percentage trigger, and status auto-completion.
final class InMemoryTaskRepository implements TaskRepository {
  final _tasks = <String, TaskEntity>{};
  final _deleted = <String, TaskEntity>{};
  var _taskSeq = 0;
  var _checkSeq = 0;

  @override
  Future<List<TaskEntity>> getTasks() async {
    final tasks = _tasks.values.toList()
      ..sort((a, b) {
        final da = a.deadline, db = b.deadline;
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return da.compareTo(db);
      });
    return tasks;
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
    final id = 'task-${++_taskSeq}';
    final checklist = <ChecklistEntity>[
      for (var i = 0; i < checklistTitles.length; i++)
        ChecklistEntity(
          id: 'check-${++_checkSeq}',
          taskId: id,
          title: checklistTitles[i],
          isCompleted: false,
          sortOrder: i,
        ),
    ];
    final task = TaskEntity(
      id: id,
      title: title,
      description: description,
      deadline: deadline,
      priority: priority,
      courseId: courseId,
      checklist: checklist,
      createdAt: DateTime.now(),
    );
    _tasks[id] = task;
    return task;
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
    final old = _tasks[id]!;
    final updated = TaskEntity(
      id: id,
      title: title,
      description: description,
      deadline: deadline,
      priority: priority,
      courseId: courseId,
      status: old.status,
      completionPercentage: old.completionPercentage,
      checklist: old.checklist,
      createdAt: old.createdAt,
    );
    _tasks[id] = updated;
    return updated;
  }

  @override
  Future<TaskEntity> setTaskCompleted({
    required String id,
    required bool completed,
  }) async {
    final old = _tasks[id]!;
    final updated = TaskEntity(
      id: id,
      title: old.title,
      description: old.description,
      deadline: old.deadline,
      priority: old.priority,
      courseId: old.courseId,
      status: completed ? TaskStatus.completed : TaskStatus.todo,
      completionPercentage: completed ? 100 : _percentOf(old.checklist),
      completedAt: completed ? DateTime.now() : null,
      checklist: old.checklist,
      createdAt: old.createdAt,
    );
    _tasks[id] = updated;
    return updated;
  }

  @override
  Future<void> deleteTask(String id) async {
    final removed = _tasks.remove(id);
    if (removed != null) {
      _deleted[id] = removed;
    }
  }

  @override
  Future<void> restoreTask(String id) async {
    final restored = _deleted.remove(id);
    if (restored != null) {
      _tasks[id] = restored;
    }
  }

  @override
  Future<void> addChecklistItem({
    required String taskId,
    required String title,
    required int sortOrder,
  }) async {
    final old = _tasks[taskId]!;
    final checklist = [
      ...old.checklist,
      ChecklistEntity(
        id: 'check-${++_checkSeq}',
        taskId: taskId,
        title: title,
        isCompleted: false,
        sortOrder: sortOrder,
      ),
    ];
    _tasks[taskId] = _withChecklist(old, checklist);
  }

  @override
  Future<void> toggleChecklistItem({
    required String id,
    required bool isCompleted,
  }) async {
    for (final task in _tasks.values) {
      final index = task.checklist.indexWhere((item) => item.id == id);
      if (index == -1) continue;
      final checklist = [...task.checklist];
      final item = checklist[index];
      checklist[index] = ChecklistEntity(
        id: item.id,
        taskId: item.taskId,
        title: item.title,
        isCompleted: isCompleted,
        sortOrder: item.sortOrder,
      );
      _tasks[task.id] = _withChecklist(task, checklist);
      return;
    }
  }

  @override
  Future<void> deleteChecklistItem(String id) async {
    for (final task in _tasks.values) {
      if (!task.checklist.any((item) => item.id == id)) continue;
      final checklist = task.checklist.where((item) => item.id != id).toList();
      _tasks[task.id] = _withChecklist(task, checklist);
      return;
    }
  }

  int _percentOf(List<ChecklistEntity> checklist) {
    if (checklist.isEmpty) return 0;
    final done = checklist.where((item) => item.isCompleted).length;
    return (done * 100 / checklist.length).round();
  }

  /// Mirrors the DB trigger: percentage and status follow the checklist.
  TaskEntity _withChecklist(TaskEntity task, List<ChecklistEntity> checklist) {
    final percent = _percentOf(checklist);
    return TaskEntity(
      id: task.id,
      title: task.title,
      description: task.description,
      deadline: task.deadline,
      priority: task.priority,
      courseId: task.courseId,
      status: checklist.isNotEmpty && percent == 100
          ? TaskStatus.completed
          : TaskStatus.todo,
      completionPercentage: percent,
      checklist: checklist,
      createdAt: task.createdAt,
    );
  }
}

void main() {
  late InMemoryTaskRepository repository;
  late RecordingNotificationService notifications;
  late ProviderContainer container;

  setUp(() {
    repository = InMemoryTaskRepository();
    notifications = RecordingNotificationService();
    container = ProviderContainer(
      overrides: [
        taskRepositoryProvider.overrideWithValue(repository),
        notificationServiceProvider.overrideWithValue(notifications),
      ],
    );
  });

  tearDown(() => container.dispose());

  test(
    'full flow: create → checklist → filter → complete → delete → undo',
    () async {
      final controller = container.read(taskControllerProvider.notifier);
      final deadline = DateTime.now().add(const Duration(days: 3));

      await controller.loadTasks();
      expect(container.read(taskControllerProvider).tasks, isEmpty);

      // Create a task with a two-item checklist.
      final created = await controller.createTask(
        title: 'Laporan praktikum basis data',
        deadline: deadline,
        priority: TaskPriority.high,
        checklistTitles: const ['Bab 1', 'Bab 2'],
      );
      expect(created, isTrue);
      var state = container.read(taskControllerProvider);
      expect(state.tasks, hasLength(1));
      final task = state.tasks.single;
      expect(task.checklist, hasLength(2));
      expect(task.completionPercentage, 0);
      // Deadline reminders (H-3/H-1) are registered on create.
      expect(notifications.scheduledTaskIds, contains(task.id));

      // Tick the first checklist item → 50%.
      await controller.toggleChecklistItem(
        id: task.checklist.first.id,
        isCompleted: true,
      );
      state = container.read(taskControllerProvider);
      expect(state.tasks.single.completionPercentage, 50);
      expect(state.tasks.single.isCompleted, isFalse);

      // Tick the second → auto-completed by the checklist trigger.
      await controller.toggleChecklistItem(
        id: task.checklist.last.id,
        isCompleted: true,
      );
      state = container.read(taskControllerProvider);
      expect(state.tasks.single.completionPercentage, 100);
      expect(state.tasks.single.isCompleted, isTrue);

      // Filter: completed list shows it, active list does not.
      controller.setFilter(TaskListFilter.completed);
      expect(container.read(taskControllerProvider).visibleTasks, hasLength(1));
      controller.setFilter(TaskListFilter.active);
      expect(container.read(taskControllerProvider).visibleTasks, isEmpty);
      controller.setFilter(TaskListFilter.all);

      // Un-complete manually, then complete manually (TASK-07).
      await controller.setTaskCompleted(id: task.id, completed: false);
      expect(
        container.read(taskControllerProvider).tasks.single.isCompleted,
        isFalse,
      );
      await controller.setTaskCompleted(id: task.id, completed: true);
      expect(
        container.read(taskControllerProvider).tasks.single.isCompleted,
        isTrue,
      );

      // Delete (soft) cancels reminders and empties the list.
      final deleted = await controller.deleteTask(task.id);
      expect(deleted, isTrue);
      expect(container.read(taskControllerProvider).tasks, isEmpty);
      expect(notifications.cancelledTaskIds, contains(task.id));

      // Undo restores the same task.
      final restored = await controller.restoreTask(task.id);
      expect(restored, isTrue);
      state = container.read(taskControllerProvider);
      expect(state.tasks.single.id, task.id);
      expect(state.tasks.single.title, 'Laporan praktikum basis data');
    },
  );

  test(
    'editing a task keeps list consistent and reschedules reminders',
    () async {
      final controller = container.read(taskControllerProvider.notifier);
      await controller.loadTasks();
      await controller.createTask(
        title: 'Kuis modul 3',
        deadline: DateTime.now().add(const Duration(days: 5)),
        priority: TaskPriority.medium,
      );
      final task = container.read(taskControllerProvider).tasks.single;
      notifications.scheduledTaskIds.clear();

      final updated = await controller.updateTask(
        id: task.id,
        title: 'Kuis modul 3 (revisi)',
        deadline: DateTime.now().add(const Duration(days: 1)),
        priority: TaskPriority.urgent,
      );

      expect(updated, isTrue);
      final state = container.read(taskControllerProvider);
      expect(state.tasks.single.title, 'Kuis modul 3 (revisi)');
      expect(state.tasks.single.priority, TaskPriority.urgent);
      expect(notifications.scheduledTaskIds, contains(task.id));
    },
  );
}
