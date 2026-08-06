import 'package:flutter/material.dart';

import '../../domain/entities/schedule_entity.dart';
import 'schedule_form_sheet.dart';

/// Warns about overlapping schedules; resolves true to save anyway.
Future<bool> showConflictWarningDialog(
  BuildContext context,
  List<ScheduleConflictEntity> conflicts,
) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: Icon(
        Icons.warning_amber_rounded,
        color: Theme.of(context).colorScheme.error,
      ),
      title: const Text('Jadwal bentrok'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Jam ini bertabrakan dengan:'),
          const SizedBox(height: 12),
          for (final conflict in conflicts)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• ${conflict.courseName} '
                '(${conflict.startTime}–${conflict.endTime})',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          const SizedBox(height: 8),
          const Text('Tetap simpan jadwal ini?'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
        FilledButton(
          key: const ValueKey('conflict-save-anyway'),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Tetap Simpan'),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Card for one schedule entry inside a day group (design system §21).
final class ScheduleCard extends StatelessWidget {
  const ScheduleCard({
    super.key,
    required this.schedule,
    required this.accentColor,
    required this.onTap,
    required this.onDelete,
  });

  final ScheduleEntity schedule;
  final Color accentColor;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      key: ValueKey('schedule-item-${schedule.id}'),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 6, color: accentColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            schedule.startTime,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            schedule.endTime,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              schedule.course?.name ?? 'Mata kuliah',
                              style: theme.textTheme.titleMedium,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (schedule.room != null ||
                                schedule.course?.lecturer != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  if (schedule.room != null) ...[
                                    Icon(
                                      Icons.place_outlined,
                                      size: 14,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      schedule.room!,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                    const SizedBox(width: 12),
                                  ],
                                  if (schedule.course?.lecturer != null)
                                    Expanded(
                                      child: Text(
                                        schedule.course!.lecturer!,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        key: ValueKey('schedule-delete-${schedule.id}'),
                        tooltip: 'Hapus',
                        visualDensity: VisualDensity.compact,
                        onPressed: onDelete,
                        icon: Icon(
                          Icons.delete_outline,
                          color: colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Section header for one day of the week.
final class DayHeader extends StatelessWidget {
  const DayHeader({super.key, required this.dayOfWeek, required this.isToday});

  final int dayOfWeek;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        children: [
          Text(
            dayNames[dayOfWeek] ?? '?',
            style: theme.textTheme.titleMedium?.copyWith(
              color: isToday ? colorScheme.primary : colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (isToday) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Hari ini',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
