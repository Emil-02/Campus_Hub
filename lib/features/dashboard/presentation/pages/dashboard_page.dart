import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/route_paths.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../calendar/domain/entities/calendar_event_entity.dart';
import '../../../courses/presentation/widgets/course_color_picker.dart';
import '../../../schedules/domain/entities/schedule_entity.dart';
import '../../../tasks/domain/entities/task_entity.dart';
import '../../../tasks/presentation/widgets/task_widgets.dart';
import '../providers/dashboard_provider.dart';
import '../providers/dashboard_state.dart';

/// Daily summary dashboard (DASH-01..DASH-07, design system §20).
final class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

final class _DashboardPageState extends ConsumerState<DashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(dashboardControllerProvider.notifier).loadDashboard();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardControllerProvider);
    final user = ref.watch(authUserProvider);
    final displayName =
        user == null || user.fullName == null || user.fullName!.trim().isEmpty
        ? (user?.email ?? '')
        : user.fullName!;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () =>
              ref.read(dashboardControllerProvider.notifier).loadDashboard(),
          child: switch (state.status) {
            DashboardStatus.initial || DashboardStatus.loading => const Center(
              child: CircularProgressIndicator(),
            ),
            _ => ListView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 48),
              children: [
                _GreetingHeader(displayName: displayName),
                if (state.status == DashboardStatus.failure) ...[
                  const SizedBox(height: 16),
                  _ErrorBanner(
                    message:
                        state.errorMessage ?? 'Terjadi kesalahan. Coba lagi.',
                  ),
                ],
                const SizedBox(height: 24),
                const _QuickActions(),
                const SizedBox(height: 24),
                _SectionHeader(
                  title: 'Jadwal Hari Ini',
                  onSeeAll: () => context.push(RoutePaths.schedules),
                ),
                const SizedBox(height: 8),
                if (state.todaySchedules.isEmpty)
                  const _EmptyHint(
                    icon: Icons.event_available_outlined,
                    message: 'Tidak ada kuliah hari ini. Nikmati harimu!',
                  )
                else
                  for (final schedule in state.todaySchedules) ...[
                    _TodayScheduleCard(schedule: schedule),
                    const SizedBox(height: 8),
                  ],
                const SizedBox(height: 16),
                _SectionHeader(
                  title: 'Deadline Terdekat',
                  onSeeAll: () => context.push(RoutePaths.tasks),
                ),
                const SizedBox(height: 8),
                if (state.upcomingTasks.isEmpty)
                  const _EmptyHint(
                    icon: Icons.task_alt_outlined,
                    message: 'Tidak ada deadline dalam waktu dekat.',
                  )
                else
                  for (final task in state.upcomingTasks) ...[
                    _DeadlineCard(task: task),
                    const SizedBox(height: 8),
                  ],
                const SizedBox(height: 16),
                _SectionHeader(
                  title: 'Event Mendatang',
                  onSeeAll: () => context.push(RoutePaths.calendar),
                ),
                const SizedBox(height: 8),
                if (state.upcomingEvents.isEmpty)
                  const _EmptyHint(
                    icon: Icons.event_note_outlined,
                    message: 'Tidak ada event dalam waktu dekat.',
                  )
                else
                  for (final event in state.upcomingEvents) ...[
                    _UpcomingEventCard(event: event),
                    const SizedBox(height: 8),
                  ],
                const SizedBox(height: 16),
                Text(
                  'Progress Tugas',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                _ProgressCard(state: state),
              ],
            ),
          },
        ),
      ),
    );
  }
}

final class _GreetingHeader extends ConsumerWidget {
  const _GreetingHeader({required this.displayName});

  final String displayName;

  static const _days = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];
  static const _months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 11) {
      return 'Selamat Pagi';
    }
    if (hour < 15) {
      return 'Selamat Siang';
    }
    if (hour < 18) {
      return 'Selamat Sore';
    }
    return 'Selamat Malam';
  }

  String get _todayLabel {
    final now = DateTime.now();
    return '${_days[now.weekday - 1]}, ${now.day} ${_months[now.month - 1]} ${now.year}';
  }

  String get _initials {
    final parts = displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return '?';
    }
    final first = parts.first.characters.first;
    if (parts.length == 1) {
      return first.toUpperCase();
    }
    return (first + parts[1].characters.first).toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_greeting, $displayName 👋',
                style: theme.textTheme.headlineSmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                _todayLabel,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        InkWell(
          key: const ValueKey('dashboard-avatar'),
          customBorder: const CircleBorder(),
          onTap: () => context.push(RoutePaths.profile),
          child: CircleAvatar(
            radius: 24,
            backgroundColor: colorScheme.primary,
            child: Text(
              _initials,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

final class _QuickActions extends ConsumerWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = [
      (
        'dashboard-action-capture',
        Icons.auto_awesome,
        'Tangkap',
        RoutePaths.smartCapture,
      ),
      (
        'dashboard-action-tasks',
        Icons.task_alt_outlined,
        'Tugas',
        RoutePaths.tasks,
      ),
      (
        'dashboard-action-schedules',
        Icons.calendar_month_outlined,
        'Jadwal',
        RoutePaths.schedules,
      ),
      (
        'dashboard-action-notes',
        Icons.sticky_note_2_outlined,
        'Catatan',
        RoutePaths.notes,
      ),
      (
        'dashboard-action-calendar',
        Icons.event_outlined,
        'Kalender',
        RoutePaths.calendar,
      ),
      (
        'dashboard-action-courses',
        Icons.menu_book_outlined,
        'Mata Kuliah',
        RoutePaths.courses,
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (key, icon, label, route) in actions) ...[
            _QuickActionButton(
              key: ValueKey(key),
              icon: icon,
              label: label,
              onTap: () async {
                final saved = await context.push<bool>(route);
                // Smart capture may add tasks/events shown on this page.
                if (saved == true && context.mounted) {
                  await ref
                      .read(dashboardControllerProvider.notifier)
                      .loadDashboard();
                }
              },
            ),
            const SizedBox(width: 16),
          ],
        ],
      ),
    );
  }
}

final class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Material(
          color: colorScheme.secondaryContainer,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Icon(icon, color: colorScheme.onSecondaryContainer),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}

final class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onSeeAll});

  final String title;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        TextButton(onPressed: onSeeAll, child: const Text('Lihat semua')),
      ],
    );
  }
}

final class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: colorScheme.outline),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// DASH-01: one class today, highlighted while it is ongoing.
final class _TodayScheduleCard extends StatelessWidget {
  const _TodayScheduleCard({required this.schedule});

  final ScheduleEntity schedule;

  bool get _isOngoing {
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    return _toMinutes(schedule.startTime) <= currentMinutes &&
        currentMinutes < _toMinutes(schedule.endTime);
  }

  static int _toMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = courseColorFromHex(schedule.course?.color ?? '#4A90D9');
    final ongoing = _isOngoing;

    return Card(
      color: ongoing ? colorScheme.primaryContainer : null,
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Container(width: 6, height: 72, color: accent),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    schedule.course?.name ?? 'Mata kuliah',
                    style: theme.textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      '${schedule.startTime}–${schedule.endTime}',
                      if (schedule.room != null) schedule.room!,
                      if (schedule.course?.lecturer != null)
                        schedule.course!.lecturer!,
                    ].join(' • '),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          if (ongoing)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Berlangsung',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// DASH-02: one upcoming deadline with urgency colors.
final class _DeadlineCard extends StatelessWidget {
  const _DeadlineCard({required this.task});

  final TaskEntity task;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        onTap: () => context.push(RoutePaths.tasks),
        title: Text(
          task.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: DeadlineIndicator(
            deadline: task.deadline!,
            isCompleted: task.isCompleted,
          ),
        ),
        trailing: task.course == null
            ? null
            : Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: courseColorFromHex(
                    task.course!.color,
                  ).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  task.course!.name,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: courseColorFromHex(task.course!.color),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
      ),
    );
  }
}

/// DASH: one upcoming calendar event with a date box and type label.
final class _UpcomingEventCard extends StatelessWidget {
  const _UpcomingEventCard({required this.event});

  final CalendarEventEntity event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = courseColorFromHex(event.color);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isToday = event.eventDate == today;
    final timeLabel = event.isAllDay || event.eventTime == null
        ? 'Sepanjang hari'
        : 'Pukul ${event.eventTime}';

    return Card(
      child: ListTile(
        onTap: () => context.push(RoutePaths.calendar),
        leading: Container(
          width: 48,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${event.eventDate.day}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                DateFormat('MMM', 'id_ID').format(event.eventDate),
                style: theme.textTheme.labelSmall?.copyWith(color: accent),
              ),
            ],
          ),
        ),
        title: Text(
          event.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium,
        ),
        subtitle: Text(
          isToday ? 'Hari ini • $timeLabel' : timeLabel,
          style: theme.textTheme.bodySmall,
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            event.eventType.label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: accent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/// DASH-03/DASH-04: completion ring plus stat chips.
final class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.state});

  final DashboardState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final stats = state.stats;
    final percent = (stats.completionRate * 100).round();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 84,
              height: 84,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: stats.completionRate,
                    strokeWidth: 8,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                  ),
                  Center(
                    child: Text(
                      '$percent%',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StatRow(
                    label: 'Tugas aktif',
                    value: stats.totalActive,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 4),
                  _StatRow(
                    label: 'Selesai minggu ini',
                    value: stats.completedThisWeek,
                    color: const Color(0xFF2E7D32),
                  ),
                  const SizedBox(height: 4),
                  _StatRow(
                    label: 'Terlambat',
                    value: stats.overdue,
                    color: colorScheme.error,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
        Text(
          '$value',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

final class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: colorScheme.onErrorContainer),
      ),
    );
  }
}
