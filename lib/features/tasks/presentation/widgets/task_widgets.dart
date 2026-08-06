import 'package:flutter/material.dart';

import '../../../courses/presentation/widgets/course_color_picker.dart';
import '../../domain/entities/task_entity.dart';

const _dayNames = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
const _monthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

/// `Sen, 8 Sep 14:30` — short Indonesian deadline label.
String formatDeadline(DateTime deadline) {
  final day = _dayNames[deadline.weekday - 1];
  final month = _monthNames[deadline.month - 1];
  final hour = deadline.hour.toString().padLeft(2, '0');
  final minute = deadline.minute.toString().padLeft(2, '0');
  return '$day, ${deadline.day} $month $hour:$minute';
}

/// Colored chip for the task priority (design system §16).
final class PriorityBadge extends StatelessWidget {
  const PriorityBadge({super.key, required this.priority});

  final TaskPriority priority;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (background, foreground, icon) = switch (priority) {
      TaskPriority.low => (
        colorScheme.secondaryContainer,
        colorScheme.onSecondaryContainer,
        Icons.south,
      ),
      TaskPriority.medium => (
        colorScheme.surfaceContainerHighest,
        colorScheme.onSurfaceVariant,
        Icons.remove,
      ),
      TaskPriority.high => (
        const Color(0xFFFFF3E0),
        const Color(0xFFEF6C00),
        Icons.north,
      ),
      TaskPriority.urgent => (
        colorScheme.errorContainer,
        colorScheme.onErrorContainer,
        Icons.priority_high,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: foreground),
          const SizedBox(width: 2),
          Text(
            priority.label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}

/// Deadline text colored by urgency (DASH-02 rules).
final class DeadlineIndicator extends StatelessWidget {
  const DeadlineIndicator({
    super.key,
    required this.deadline,
    required this.isCompleted,
  });

  final DateTime deadline;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final remaining = deadline.difference(now);

    final Color color;
    final String label;
    if (isCompleted) {
      color = colorScheme.onSurfaceVariant;
      label = formatDeadline(deadline);
    } else if (remaining.isNegative) {
      color = colorScheme.error;
      label = 'Terlambat • ${formatDeadline(deadline)}';
    } else if (remaining.inHours < 24) {
      color = colorScheme.error;
      label = '${remaining.inHours} jam lagi • ${formatDeadline(deadline)}';
    } else if (remaining.inDays < 3) {
      color = const Color(0xFFEF6C00);
      label = '${remaining.inDays} hari lagi • ${formatDeadline(deadline)}';
    } else {
      color = const Color(0xFF2E7D32);
      label = '${remaining.inDays} hari lagi • ${formatDeadline(deadline)}';
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.schedule, size: 14, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

/// Card for one task in the list (design system §15).
final class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.onToggleCompleted,
    required this.onTap,
  });

  final TaskEntity task;
  final ValueChanged<bool> onToggleCompleted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final course = task.course;
    final hasChecklist = task.checklist.isNotEmpty;

    return Card(
      key: ValueKey('task-item-${task.id}'),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 16, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                key: ValueKey('task-check-${task.id}'),
                value: task.isCompleted,
                shape: const CircleBorder(),
                onChanged: (value) => onToggleCompleted(value ?? false),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    Text(
                      task.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: task.isCompleted
                            ? colorScheme.onSurfaceVariant
                            : null,
                        fontWeight:
                            task.priority == TaskPriority.high ||
                                task.priority == TaskPriority.urgent
                            ? FontWeight.w600
                            : null,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        PriorityBadge(priority: task.priority),
                        if (course != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: courseColorFromHex(
                                course.color,
                              ).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              course.name,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: courseColorFromHex(course.color),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (task.deadline != null) ...[
                      const SizedBox(height: 6),
                      DeadlineIndicator(
                        deadline: task.deadline!,
                        isCompleted: task.isCompleted,
                      ),
                    ],
                    if (hasChecklist) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: task.completionPercentage / 100,
                                minHeight: 6,
                                backgroundColor:
                                    colorScheme.surfaceContainerHighest,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${task.completionPercentage}%',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
