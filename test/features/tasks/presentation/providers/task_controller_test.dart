import 'package:campusmate/features/tasks/domain/entities/task_entity.dart';
import 'package:campusmate/features/tasks/domain/repositories/task_repository.dart';
import 'package:campusmate/features/tasks/presentation/providers/task_provider.dart';
import 'package:campusmate/features/tasks/presentation/providers/task_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTaskRepository extends Mock implements TaskRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(TaskPriority.medium);
  });

  late MockTaskRepository repository;
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
    container = ProviderContainer(
      overrides: [taskRepositoryProvider.overrideWithValue(repository)],
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
    expect(container.read(taskControllerProvider).visibleTasks, [
      activeTask,
      overdueTask,
    ]);

    controller.setFilter(TaskListFilter.completed);
    expect(container.read(taskControllerProvider).visibleTasks, [
      completedTask,
    ]);

    controller.setFilter(TaskListFilter.overdue);
    expect(container.read(taskControllerProvider).visibleTasks, [overdueTask]);
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
