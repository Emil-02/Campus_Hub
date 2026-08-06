import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../courses/presentation/providers/course_provider.dart';
import '../../../courses/presentation/providers/course_state.dart';
import '../../../courses/presentation/widgets/course_color_picker.dart';
import '../../domain/entities/schedule_entity.dart';
import '../providers/schedule_provider.dart';
import '../providers/schedule_state.dart';
import '../widgets/schedule_form_sheet.dart';
import '../widgets/schedule_widgets.dart';

/// Weekly schedule grouped per day (design system §21).
final class SchedulePage extends ConsumerStatefulWidget {
  const SchedulePage({super.key});

  @override
  ConsumerState<SchedulePage> createState() => _SchedulePageState();
}

final class _SchedulePageState extends ConsumerState<SchedulePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref.read(scheduleControllerProvider.notifier).loadSchedules();
      ref.read(courseControllerProvider.notifier).loadCourses();
    });
  }

  Future<void> _addSchedule() async {
    final courses = ref.read(courseControllerProvider).courses;
    if (courses.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Tambahkan mata kuliah dulu sebelum membuat jadwal.'),
          ),
        );
      return;
    }

    final result = await showScheduleFormSheet(context, courses: courses);
    if (result == null || !mounted) {
      return;
    }
    await _saveWithConflictCheck(result);
  }

  Future<void> _editSchedule(ScheduleEntity schedule) async {
    final courses = ref.read(courseControllerProvider).courses;
    final result = await showScheduleFormSheet(
      context,
      courses: courses,
      initial: schedule,
    );
    if (result == null || !mounted) {
      return;
    }
    await _saveWithConflictCheck(result, existingId: schedule.id);
  }

  Future<void> _saveWithConflictCheck(
    ScheduleFormResult result, {
    String? existingId,
  }) async {
    final controller = ref.read(scheduleControllerProvider.notifier);

    final conflicts = await controller.checkConflict(
      dayOfWeek: result.dayOfWeek,
      startTime: result.startTime,
      endTime: result.endTime,
      excludeScheduleId: existingId,
    );
    if (!mounted) {
      return;
    }
    if (conflicts.isNotEmpty) {
      final proceed = await showConflictWarningDialog(context, conflicts);
      if (!proceed || !mounted) {
        return;
      }
    }

    final saved = existingId == null
        ? await controller.createSchedule(
            courseId: result.courseId,
            dayOfWeek: result.dayOfWeek,
            startTime: result.startTime,
            endTime: result.endTime,
            room: result.room,
          )
        : await controller.updateSchedule(
            id: existingId,
            courseId: result.courseId,
            dayOfWeek: result.dayOfWeek,
            startTime: result.startTime,
            endTime: result.endTime,
            room: result.room,
          );
    _showResultSnackBar(
      saved,
      existingId == null ? 'Jadwal ditambahkan.' : 'Perubahan disimpan.',
    );
  }

  Future<void> _deleteSchedule(ScheduleEntity schedule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus jadwal?'),
        content: Text(
          '"${schedule.course?.name ?? 'Jadwal'}" pada '
          '${dayNames[schedule.dayOfWeek]} '
          '${schedule.startTime}–${schedule.endTime} akan dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    final deleted = await ref
        .read(scheduleControllerProvider.notifier)
        .deleteSchedule(schedule.id);
    _showResultSnackBar(deleted, 'Jadwal dihapus.');
  }

  void _showResultSnackBar(bool success, String successMessage) {
    if (!mounted) {
      return;
    }
    final message = success
        ? successMessage
        : ref.read(scheduleControllerProvider).errorMessage ??
              'Terjadi kesalahan. Coba lagi.';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scheduleControllerProvider);
    final courseState = ref.watch(courseControllerProvider);
    final isLoadingCourses =
        courseState.status == CourseStatus.initial ||
        courseState.status == CourseStatus.loading;

    return Scaffold(
      appBar: AppBar(title: const Text('Jadwal Kuliah')),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('schedule-add-fab'),
        onPressed: state.isMutating || isLoadingCourses ? null : _addSchedule,
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
      body: switch (state.status) {
        ScheduleStatus.initial || ScheduleStatus.loading => const Center(
          child: CircularProgressIndicator(),
        ),
        ScheduleStatus.failure when state.schedules.isEmpty => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  state.errorMessage ?? 'Terjadi kesalahan. Coba lagi.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref
                      .read(scheduleControllerProvider.notifier)
                      .loadSchedules(),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
        _ when state.schedules.isEmpty => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_month_outlined,
                  size: 56,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Belum ada jadwal.\nTekan "Tambah" untuk membuat yang pertama.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        _ => _WeeklyList(
          state: state,
          onEdit: _editSchedule,
          onDelete: _deleteSchedule,
        ),
      },
    );
  }
}

final class _WeeklyList extends StatelessWidget {
  const _WeeklyList({
    required this.state,
    required this.onEdit,
    required this.onDelete,
  });

  final ScheduleState state;
  final ValueChanged<ScheduleEntity> onEdit;
  final ValueChanged<ScheduleEntity> onDelete;

  @override
  Widget build(BuildContext context) {
    final byDay = state.byDay;
    final today = DateTime.now().weekday;
    final days = byDay.keys.toList()..sort();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      children: [
        for (final day in days) ...[
          DayHeader(dayOfWeek: day, isToday: day == today),
          for (final schedule in byDay[day]!) ...[
            ScheduleCard(
              schedule: schedule,
              accentColor: courseColorFromHex(
                schedule.course?.color ?? courseColorPalette.first,
              ),
              onTap: () => onEdit(schedule),
              onDelete: () => onDelete(schedule),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ],
    );
  }
}
