import 'package:campusmate/features/tasks/domain/entities/task_entity.dart';
import 'package:campusmate/features/tasks/domain/repositories/task_repository.dart';
import 'package:campusmate/features/tasks/presentation/providers/task_provider.dart';
import 'package:campusmate/features/tasks/presentation/providers/task_state.dart';
import 'package:campusmate/services/notification_service.dart';
import 'package:campusmate/services/service_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTaskRepository extends Mock implements TaskRepository {}

final class FakeTaskNotificationService implements NotificationService {
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

void main() {
  setUpAll(() {
    registerFallbackValue(TaskPriority.medium);
  });

  late MockTaskRepository repository;
  late FakeTaskNotificationService notifications;
  late ProviderContainer container;

  final activeTask = TaskEntity(
    id: 'task-1',
    title: 'Laporan praktikum',
    priority: TaskPriority.high,
    deadline: DateTime.now().add(const Duration(days: 2)),
  );
  const completedTask = TaskEntity(
    id: 'task-2',
    title: 'Kuis modul 1',
    status: TaskStatus.completed,
    completionPercentage: 100,
  );
  final overdueTask = TaskEntity(
    id: 'task-3',
    title: 'Esai etika',
    deadline: DateTime.now().subtract(const Duration(days: 1)),
  );

  setUp(() {
    repository = MockTaskRepository();
    notifications = FakeTaskNotificationService();
    container = ProviderContainer(
      overrides: [
        taskRepositoryProvider.overrideWithValue(repository),
        notificationServiceProvider.overrideWithValue(notifications),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('loadTasks exposes the loaded list', () async {
    when(
      () => repository.getTasks(),
    ).thenAnswer((_) async => [activeTask, completedTask]);

    await container.read(taskControllerProvider.notifier).loadTasks();

    expect(
      container.read(taskControllerProvider),
      TaskState.loaded([activeTask, completedTask]),
    );
  });

  test('loadTasks surfaces a safe failure message', () async {
    when(() => repository.getTasks()).thenThrow(StateError('no session'));

    await container.read(taskControllerProvider.notifier).loadTasks();

    final state = container.read(taskControllerProvider);
    expect(state.status, TaskListStatus.failure);
    expect(state.errorMessage, 'Sesi tidak valid. Silakan login ulang.');
  });

  test('visibleTasks respects the selected filter', () async {
    when(
      () => repository.getTasks(),
    ).thenAnswer((_) async => [activeTask, completedTask, overdueTask]);
    await container.read(taskControllerProvider.notifier).loadTasks();
    final controller = container.read(taskControllerProvider.notifier);

    controller.setFilter(TaskListFilter.active);
    // Default sort = deadline: the overdue task's date comes first.
    expect(container.read(taskControllerProvider).visibleTasks, [
      overdueTask,
      activeTask,
    ]);

    controller.setFilter(TaskListFilter.completed);
    expect(container.read(taskControllerProvider).visibleTasks, [
      completedTask,
    ]);

    controller.setFilter(TaskListFilter.overdue);
    expect(container.read(taskControllerProvider).visibleTasks, [overdueTask]);
  });

  test('sort by name and priority reorders the visible list', () async {
    when(
      () => repository.getTasks(),
    ).thenAnswer((_) async => [activeTask, completedTask, overdueTask]);
    await container.read(taskControllerProvider.notifier).loadTasks();
    final controller = container.read(taskControllerProvider.notifier);

    controller.setSort(TaskSortOption.name);
    expect(
      container.read(taskControllerProvider).visibleTasks.first.title,
      'Esai etika',
    );

    controller.setSort(TaskSortOption.priority);
    // activeTask is the only high-priority entry.
    expect(
      container.read(taskControllerProvider).visibleTasks.first,
      activeTask,
    );
  });

  test('course and priority filters narrow the visible list', () async {
    const courseTask = TaskEntity(
      id: 'task-4',
      courseId: 'course-1',
      title: 'Tugas MK',
      priority: TaskPriority.urgent,
    );
    when(
      () => repository.getTasks(),
    ).thenAnswer((_) async => [activeTask, courseTask]);
    await container.read(taskControllerProvider.notifier).loadTasks();
    final controller = container.read(taskControllerProvider.notifier);

    controller.setCourseFilter('course-1');
    expect(container.read(taskControllerProvider).visibleTasks, [courseTask]);
    expect(container.read(taskControllerProvider).hasExtraFilters, isTrue);

    controller.setCourseFilter(null);
    controller.setPriorityFilter(TaskPriority.high);
    expect(container.read(taskControllerProvider).visibleTasks, [activeTask]);

    controller.setPriorityFilter(null);
    expect(container.read(taskControllerProvider).hasExtraFilters, isFalse);
  });

  test('createTask forwards checklist titles and reloads', () async {
    when(
      () => repository.createTask(
        title: any(named: 'title'),
        description: any(named: 'description'),
        deadline: any(named: 'deadline'),
        priority: any(named: 'priority'),
        courseId: any(named: 'courseId'),
        checklistTitles: any(named: 'checklistTitles'),
      ),
    ).thenAnswer((_) async => activeTask);
    when(() => repository.getTasks()).thenAnswer((_) async => [activeTask]);

    final saved = await container
        .read(taskControllerProvider.notifier)
        .createTask(
          title: 'Laporan praktikum',
          priority: TaskPriority.high,
          checklistTitles: const ['Bab 1', 'Bab 2'],
        );

    expect(saved, isTrue);
    verify(
      () => repository.createTask(
        title: 'Laporan praktikum',
        description: null,
        deadline: null,
        priority: TaskPriority.high,
        courseId: null,
        checklistTitles: const ['Bab 1', 'Bab 2'],
      ),
    ).called(1);
    expect(
      container.read(taskControllerProvider),
      TaskState.loaded([activeTask]),
    );
  });

  test('createTask keeps previous tasks on failure', () async {
    when(() => repository.getTasks()).thenAnswer((_) async => [activeTask]);
    await container.read(taskControllerProvider.notifier).loadTasks();

    when(
      () => repository.createTask(
        title: any(named: 'title'),
        description: any(named: 'description'),
        deadline: any(named: 'deadline'),
        priority: any(named: 'priority'),
        courseId: any(named: 'courseId'),
        checklistTitles: any(named: 'checklistTitles'),
      ),
    ).thenThrow(const FormatException('bad data'));

    final saved = await container
        .read(taskControllerProvider.notifier)
        .createTask(title: 'X', priority: TaskPriority.low);

    final state = container.read(taskControllerProvider);
    expect(saved, isFalse);
    expect(state.status, TaskListStatus.failure);
    expect(state.tasks, [activeTask]);
    expect(state.errorMessage, 'Data tugas tidak valid.');
  });

  test('setTaskCompleted swaps the task in place without reloading', () async {
    when(() => repository.getTasks()).thenAnswer((_) async => [activeTask]);
    await container.read(taskControllerProvider.notifier).loadTasks();

    final completed = TaskEntity(
      id: activeTask.id,
      title: activeTask.title,
      priority: activeTask.priority,
      deadline: activeTask.deadline,
      status: TaskStatus.completed,
      completionPercentage: 100,
    );
    when(
      () => repository.setTaskCompleted(id: 'task-1', completed: true),
    ).thenAnswer((_) async => completed);

    final saved = await container
        .read(taskControllerProvider.notifier)
        .setTaskCompleted(id: 'task-1', completed: true);

    expect(saved, isTrue);
    // The list still holds the swapped entity, proving no refetch happened
    // (a refetch would restore the stubbed [activeTask]).
    expect(container.read(taskControllerProvider).tasks, [completed]);
  });

  test(
    'toggleChecklistItem reloads so trigger results become visible',
    () async {
      when(
        () => repository.toggleChecklistItem(
          id: any(named: 'id'),
          isCompleted: any(named: 'isCompleted'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => repository.getTasks(),
      ).thenAnswer((_) async => [completedTask]);

      final saved = await container
          .read(taskControllerProvider.notifier)
          .toggleChecklistItem(id: 'check-1', isCompleted: true);

      expect(saved, isTrue);
      expect(container.read(taskControllerProvider).tasks, [completedTask]);
    },
  );

  test('deleteTask reloads the list and returns true', () async {
    when(() => repository.deleteTask('task-1')).thenAnswer((_) async {});
    when(() => repository.getTasks()).thenAnswer((_) async => const []);

    final deleted = await container
        .read(taskControllerProvider.notifier)
        .deleteTask('task-1');

    expect(deleted, isTrue);
    expect(container.read(taskControllerProvider).tasks, isEmpty);
    expect(notifications.cancelledTaskIds, contains('task-1'));
  });

  test('createTask schedules reminders for tasks with a deadline', () async {
    when(
      () => repository.createTask(
        title: any(named: 'title'),
        description: any(named: 'description'),
        deadline: any(named: 'deadline'),
        priority: any(named: 'priority'),
        courseId: any(named: 'courseId'),
        checklistTitles: any(named: 'checklistTitles'),
      ),
    ).thenAnswer((_) async => activeTask);
    when(() => repository.getTasks()).thenAnswer((_) async => [activeTask]);

    await container
        .read(taskControllerProvider.notifier)
        .createTask(title: 'Laporan praktikum', priority: TaskPriority.high);

    expect(notifications.scheduledTaskIds, ['task-1']);
  });

  test('completing a task cancels its reminders', () async {
    when(() => repository.getTasks()).thenAnswer((_) async => [activeTask]);
    await container.read(taskControllerProvider.notifier).loadTasks();

    final completed = TaskEntity(
      id: activeTask.id,
      title: activeTask.title,
      status: TaskStatus.completed,
      deadline: activeTask.deadline,
    );
    when(
      () => repository.setTaskCompleted(id: 'task-1', completed: true),
    ).thenAnswer((_) async => completed);

    await container
        .read(taskControllerProvider.notifier)
        .setTaskCompleted(id: 'task-1', completed: true);

    expect(notifications.cancelledTaskIds, contains('task-1'));
    expect(notifications.scheduledTaskIds, isEmpty);
  });

  test('restoreTask reloads and reschedules reminders', () async {
    when(() => repository.restoreTask('task-1')).thenAnswer((_) async {});
    when(() => repository.getTasks()).thenAnswer((_) async => [activeTask]);

    final restored = await container
        .read(taskControllerProvider.notifier)
        .restoreTask('task-1');

    expect(restored, isTrue);
    expect(container.read(taskControllerProvider).tasks, [activeTask]);
    expect(notifications.scheduledTaskIds, ['task-1']);
  });

  test('addChecklistItem appends with the next sort order', () async {
    const withChecklist = TaskEntity(
      id: 'task-1',
      title: 'Laporan praktikum',
      checklist: [
        ChecklistEntity(
          id: 'check-1',
          taskId: 'task-1',
          title: 'Bab 1',
          isCompleted: false,
          sortOrder: 0,
        ),
      ],
    );
    when(() => repository.getTasks()).thenAnswer((_) async => [withChecklist]);
    await container.read(taskControllerProvider.notifier).loadTasks();

    when(
      () => repository.addChecklistItem(
        taskId: any(named: 'taskId'),
        title: any(named: 'title'),
        sortOrder: any(named: 'sortOrder'),
      ),
    ).thenAnswer((_) async {});

    await container
        .read(taskControllerProvider.notifier)
        .addChecklistItem(taskId: 'task-1', title: 'Bab 2');

    verify(
      () => repository.addChecklistItem(
        taskId: 'task-1',
        title: 'Bab 2',
        sortOrder: 1,
      ),
    ).called(1);
  });
}
