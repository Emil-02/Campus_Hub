import 'package:campusmate/features/calendar/domain/entities/calendar_event_entity.dart';
import 'package:campusmate/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:campusmate/features/calendar/presentation/providers/calendar_provider.dart';
import 'package:campusmate/features/calendar/presentation/providers/calendar_state.dart';
import 'package:campusmate/features/tasks/domain/entities/task_entity.dart';
import 'package:campusmate/features/tasks/domain/repositories/task_repository.dart';
import 'package:campusmate/features/tasks/presentation/providers/task_dependencies.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCalendarRepository extends Mock implements CalendarRepository {}

class MockTaskRepository extends Mock implements TaskRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(CalendarEventType.personal);
    registerFallbackValue(DateTime(2026));
  });

  late MockCalendarRepository calendarRepository;
  late MockTaskRepository taskRepository;
  late ProviderContainer container;

  final event = CalendarEventEntity(
    id: 'event-1',
    title: 'UTS Struktur Data',
    eventDate: DateTime(2026, 8, 20),
    eventType: CalendarEventType.exam,
  );
  final deadlineTask = TaskEntity(
    id: 'task-1',
    title: 'Laporan praktikum',
    deadline: DateTime(2026, 8, 20, 16, 59),
  );
  final outsideTask = TaskEntity(
    id: 'task-2',
    title: 'Tugas bulan depan',
    deadline: DateTime(2026, 9, 2),
  );

  setUp(() {
    calendarRepository = MockCalendarRepository();
    taskRepository = MockTaskRepository();
    container = ProviderContainer(
      overrides: [
        calendarRepositoryProvider.overrideWithValue(calendarRepository),
        taskRepositoryProvider.overrideWithValue(taskRepository),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('loadMonth merges events with same-month task deadlines', () async {
    when(
      () => calendarRepository.getEventsInRange(
        start: any(named: 'start'),
        end: any(named: 'end'),
      ),
    ).thenAnswer((_) async => [event]);
    when(
      () => taskRepository.getTasks(),
    ).thenAnswer((_) async => [deadlineTask, outsideTask]);

    await container
        .read(calendarControllerProvider.notifier)
        .loadMonth(DateTime(2026, 8, 15));

    final state = container.read(calendarControllerProvider);
    expect(state.status, CalendarStatus.loaded);
    expect(state.events, [event]);
    expect(state.deadlineTasks, [deadlineTask]);
  });

  test('markerCount combines events and deadlines per day', () async {
    when(
      () => calendarRepository.getEventsInRange(
        start: any(named: 'start'),
        end: any(named: 'end'),
      ),
    ).thenAnswer((_) async => [event]);
    when(
      () => taskRepository.getTasks(),
    ).thenAnswer((_) async => [deadlineTask]);

    await container
        .read(calendarControllerProvider.notifier)
        .loadMonth(DateTime(2026, 8));

    final state = container.read(calendarControllerProvider);
    expect(state.markerCount(DateTime(2026, 8, 20)), 2);
    expect(state.markerCount(DateTime(2026, 8, 21)), 0);
    expect(state.eventsOn(DateTime(2026, 8, 20)), [event]);
    expect(state.tasksOn(DateTime(2026, 8, 20)), [deadlineTask]);
  });

  test('loadMonth surfaces a safe failure message', () async {
    when(
      () => calendarRepository.getEventsInRange(
        start: any(named: 'start'),
        end: any(named: 'end'),
      ),
    ).thenThrow(StateError('no session'));

    await container
        .read(calendarControllerProvider.notifier)
        .loadMonth(DateTime(2026, 8));

    final state = container.read(calendarControllerProvider);
    expect(state.status, CalendarStatus.failure);
    expect(state.errorMessage, 'Sesi tidak valid. Silakan login ulang.');
  });

  test('addEvent reloads the month of the new event', () async {
    when(
      () => calendarRepository.createEvent(
        title: any(named: 'title'),
        description: any(named: 'description'),
        eventDate: any(named: 'eventDate'),
        eventTime: any(named: 'eventTime'),
        eventType: any(named: 'eventType'),
        isAllDay: any(named: 'isAllDay'),
      ),
    ).thenAnswer((_) async => event);
    when(
      () => calendarRepository.getEventsInRange(
        start: any(named: 'start'),
        end: any(named: 'end'),
      ),
    ).thenAnswer((_) async => [event]);
    when(() => taskRepository.getTasks()).thenAnswer((_) async => const []);

    final saved = await container
        .read(calendarControllerProvider.notifier)
        .addEvent(
          title: 'UTS Struktur Data',
          eventDate: DateTime(2026, 8, 20),
          eventType: CalendarEventType.exam,
        );

    expect(saved, isTrue);
    expect(container.read(calendarControllerProvider).events, [event]);
    verify(
      () => calendarRepository.createEvent(
        title: 'UTS Struktur Data',
        description: null,
        eventDate: DateTime(2026, 8, 20),
        eventTime: null,
        eventType: CalendarEventType.exam,
        isAllDay: true,
      ),
    ).called(1);
  });

  test('deleteEvent reloads the focused month', () async {
    when(
      () => calendarRepository.getEventsInRange(
        start: any(named: 'start'),
        end: any(named: 'end'),
      ),
    ).thenAnswer((_) async => const []);
    when(() => taskRepository.getTasks()).thenAnswer((_) async => const []);
    when(
      () => calendarRepository.deleteEvent('event-1'),
    ).thenAnswer((_) async {});

    final deleted = await container
        .read(calendarControllerProvider.notifier)
        .deleteEvent('event-1');

    expect(deleted, isTrue);
    expect(container.read(calendarControllerProvider).events, isEmpty);
  });
}
