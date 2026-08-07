import 'package:campusmate/features/calendar/domain/entities/calendar_event_entity.dart';
import 'package:campusmate/features/dashboard/domain/entities/dashboard_stats_entity.dart';
import 'package:campusmate/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:campusmate/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:campusmate/features/dashboard/presentation/providers/dashboard_state.dart';
import 'package:campusmate/features/schedules/domain/entities/schedule_entity.dart';
import 'package:campusmate/features/tasks/domain/entities/task_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDashboardRepository extends Mock implements DashboardRepository {}

void main() {
  late MockDashboardRepository repository;
  late ProviderContainer container;

  const schedule = ScheduleEntity(
    id: 'schedule-1',
    courseId: 'course-1',
    dayOfWeek: 4,
    startTime: '08:00',
    endTime: '09:40',
  );
  final task = TaskEntity(
    id: 'task-1',
    title: 'Laporan praktikum',
    deadline: DateTime.now().add(const Duration(days: 1)),
  );
  const stats = DashboardStatsEntity(
    totalActive: 3,
    completedTotal: 5,
    completedThisWeek: 2,
    overdue: 1,
  );
  final event = CalendarEventEntity(
    id: 'event-1',
    title: 'Seminar proposal',
    eventDate: DateTime.now().add(const Duration(days: 2)),
    eventTime: '13:00',
    eventType: CalendarEventType.academic,
  );

  setUp(() {
    repository = MockDashboardRepository();
    container = ProviderContainer(
      overrides: [dashboardRepositoryProvider.overrideWithValue(repository)],
    );
  });

  tearDown(() => container.dispose());

  test('loadDashboard exposes all three sections', () async {
    when(
      () => repository.getTodaySchedules(),
    ).thenAnswer((_) async => [schedule]);
    when(
      () => repository.getUpcomingDeadlines(),
    ).thenAnswer((_) async => [task]);
    when(() => repository.getUpcomingEvents()).thenAnswer((_) async => [event]);
    when(() => repository.getStatistics()).thenAnswer((_) async => stats);

    await container.read(dashboardControllerProvider.notifier).loadDashboard();

    final state = container.read(dashboardControllerProvider);
    expect(state.status, DashboardStatus.loaded);
    expect(state.todaySchedules, [schedule]);
    expect(state.upcomingTasks, [task]);
    expect(state.upcomingEvents, [event]);
    expect(state.stats, stats);
  });

  test('loadDashboard surfaces a safe failure message', () async {
    when(
      () => repository.getTodaySchedules(),
    ).thenThrow(StateError('no session'));
    when(
      () => repository.getUpcomingDeadlines(),
    ).thenAnswer((_) async => const []);
    when(
      () => repository.getUpcomingEvents(),
    ).thenAnswer((_) async => const []);
    when(
      () => repository.getStatistics(),
    ).thenAnswer((_) async => const DashboardStatsEntity());

    await container.read(dashboardControllerProvider.notifier).loadDashboard();

    final state = container.read(dashboardControllerProvider);
    expect(state.status, DashboardStatus.failure);
    expect(state.errorMessage, 'Sesi tidak valid. Silakan login ulang.');
  });

  test('refresh keeps previous data on failure', () async {
    when(
      () => repository.getTodaySchedules(),
    ).thenAnswer((_) async => [schedule]);
    when(
      () => repository.getUpcomingDeadlines(),
    ).thenAnswer((_) async => [task]);
    when(() => repository.getUpcomingEvents()).thenAnswer((_) async => [event]);
    when(() => repository.getStatistics()).thenAnswer((_) async => stats);
    await container.read(dashboardControllerProvider.notifier).loadDashboard();

    when(
      () => repository.getTodaySchedules(),
    ).thenThrow(const FormatException('bad data'));

    await container.read(dashboardControllerProvider.notifier).loadDashboard();

    final state = container.read(dashboardControllerProvider);
    expect(state.status, DashboardStatus.failure);
    expect(state.todaySchedules, [schedule]);
    expect(state.upcomingTasks, [task]);
    expect(state.upcomingEvents, [event]);
    expect(state.stats, stats);
    expect(state.errorMessage, 'Data ringkasan tidak valid.');
  });
}
