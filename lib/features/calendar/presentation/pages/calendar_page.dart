import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/router/route_paths.dart';
import '../../../courses/presentation/widgets/course_color_picker.dart';
import '../../../tasks/domain/entities/task_entity.dart';
import '../../../tasks/presentation/widgets/task_widgets.dart';
import '../../domain/entities/calendar_event_entity.dart';
import '../providers/calendar_provider.dart';
import '../providers/calendar_state.dart';

/// Monthly calendar with deadline + event markers (CAL-01..CAL-05).
final class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

final class _CalendarPageState extends ConsumerState<CalendarPage> {
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(calendarControllerProvider.notifier).loadMonth(_selectedDay);
      }
    });
  }

  Future<void> _addEvent() async {
    final result = await showDialog<_NewEvent>(
      context: context,
      builder: (_) => _AddEventDialog(initialDate: _selectedDay),
    );
    if (result == null || !mounted) {
      return;
    }
    final saved = await ref
        .read(calendarControllerProvider.notifier)
        .addEvent(
          title: result.title,
          description: result.description,
          eventDate: result.date,
          eventTime: result.time,
          eventType: result.type,
        );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            saved
                ? 'Event ditambahkan.'
                : ref.read(calendarControllerProvider).errorMessage ??
                      'Gagal menyimpan event.',
          ),
        ),
      );
  }

  Future<void> _openSmartCapture() async {
    final saved = await context.push<bool>(RoutePaths.smartCapture);
    if (saved == true && mounted) {
      ref.read(calendarControllerProvider.notifier).loadMonth(_selectedDay);
    }
  }

  Future<void> _deleteEvent(CalendarEventEntity event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus event?'),
        content: Text('"${event.title}" akan dihapus.'),
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
    if (confirmed == true && mounted) {
      await ref.read(calendarControllerProvider.notifier).deleteEvent(event.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = ref.watch(calendarControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalender'),
        actions: [
          IconButton(
            key: const ValueKey('calendar-smart-capture'),
            tooltip: 'Tangkap cerdas dari chat/foto',
            onPressed: _openSmartCapture,
            icon: const Icon(Icons.auto_awesome),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('calendar-add-fab'),
        onPressed: _addEvent,
        icon: const Icon(Icons.add),
        label: const Text('Event'),
      ),
      body: switch (state.status) {
        CalendarStatus.initial || CalendarStatus.loading => const Center(
          child: CircularProgressIndicator(),
        ),
        CalendarStatus.failure when state.events.isEmpty => Center(
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
                      .read(calendarControllerProvider.notifier)
                      .loadMonth(_selectedDay),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
        _ => Column(
          children: [
            Card(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TableCalendar<Object>(
                locale: 'id_ID',
                firstDay: DateTime(2020),
                lastDay: DateTime(2035),
                focusedDay:
                    state.focusedMonth.month == _selectedDay.month &&
                        state.focusedMonth.year == _selectedDay.year
                    ? _selectedDay
                    : state.focusedMonth,
                availableCalendarFormats: const {CalendarFormat.month: 'Bulan'},
                startingDayOfWeek: StartingDayOfWeek.monday,
                selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
                eventLoader: (day) => List.filled(
                  state.markerCount(day).clamp(0, 4),
                  const Object(),
                ),
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: TextStyle(
                    color: colorScheme.onPrimaryContainer,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: BoxDecoration(
                    color: colorScheme.tertiary,
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: const HeaderStyle(titleCentered: true),
                onDaySelected: (selectedDay, _) {
                  setState(() {
                    _selectedDay = selectedDay;
                  });
                },
                onPageChanged: (focusedDay) {
                  ref
                      .read(calendarControllerProvider.notifier)
                      .loadMonth(focusedDay);
                },
              ),
            ),
            Expanded(
              child: _DayDetail(
                day: _selectedDay,
                events: state.eventsOn(_selectedDay),
                tasks: state.tasksOn(_selectedDay),
                onDeleteEvent: _deleteEvent,
              ),
            ),
          ],
        ),
      },
    );
  }
}

/// List of events + deadlines for the selected day (CAL-03).
final class _DayDetail extends StatelessWidget {
  const _DayDetail({
    required this.day,
    required this.events,
    required this.tasks,
    required this.onDeleteEvent,
  });

  final DateTime day;
  final List<CalendarEventEntity> events;
  final List<TaskEntity> tasks;
  final ValueChanged<CalendarEventEntity> onDeleteEvent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (events.isEmpty && tasks.isEmpty) {
      return Center(
        child: Text(
          'Tidak ada event atau deadline\npada ${formatDeadline(day).split(' ').take(3).join(' ')}.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
      children: [
        for (final task in tasks)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(
                task.isCompleted
                    ? Icons.check_circle_outline
                    : Icons.flag_outlined,
                color: task.isOverdue ? colorScheme.error : colorScheme.primary,
              ),
              title: Text(
                task.title,
                style: task.isCompleted
                    ? theme.textTheme.titleMedium?.copyWith(
                        decoration: TextDecoration.lineThrough,
                        color: colorScheme.onSurfaceVariant,
                      )
                    : theme.textTheme.titleMedium,
              ),
              subtitle: Text(
                'Deadline tugas${task.course != null ? ' • ${task.course!.name}' : ''}',
              ),
            ),
          ),
        for (final event in events)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                radius: 14,
                backgroundColor: courseColorFromHex(event.color),
                child: Icon(
                  switch (event.eventType) {
                    CalendarEventType.academic => Icons.school_outlined,
                    CalendarEventType.personal => Icons.person_outline,
                    CalendarEventType.organization => Icons.groups_outlined,
                    CalendarEventType.exam => Icons.edit_note,
                    CalendarEventType.holiday => Icons.beach_access_outlined,
                  },
                  size: 16,
                  color: Colors.white,
                ),
              ),
              title: Text(event.title, style: theme.textTheme.titleMedium),
              subtitle: Text(
                [
                  event.eventType.label,
                  if (event.eventTime != null) event.eventTime!,
                  if (event.description != null) event.description!,
                ].join(' • '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                tooltip: 'Hapus',
                onPressed: () => onDeleteEvent(event),
                icon: Icon(Icons.delete_outline, color: colorScheme.error),
              ),
            ),
          ),
      ],
    );
  }
}

final class _NewEvent {
  const _NewEvent({
    required this.title,
    this.description,
    required this.date,
    this.time,
    required this.type,
  });

  final String title;
  final String? description;
  final DateTime date;
  final String? time;
  final CalendarEventType type;
}

/// Dialog form for a custom event (CAL-05).
final class _AddEventDialog extends StatefulWidget {
  const _AddEventDialog({required this.initialDate});

  final DateTime initialDate;

  @override
  State<_AddEventDialog> createState() => _AddEventDialogState();
}

final class _AddEventDialogState extends State<_AddEventDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  late DateTime _date = widget.initialDate;
  TimeOfDay? _time;
  CalendarEventType _type = CalendarEventType.personal;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null && mounted) {
      setState(() {
        _date = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (mounted) {
      setState(() {
        _time = picked;
      });
    }
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final description = _descriptionController.text.trim();
    Navigator.of(context).pop(
      _NewEvent(
        title: _titleController.text.trim(),
        description: description.isEmpty ? null : description,
        date: _date,
        time: _time == null
            ? null
            : '${_time!.hour.toString().padLeft(2, '0')}:${_time!.minute.toString().padLeft(2, '0')}',
        type: _type,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah Event'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                key: const ValueKey('event-title'),
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                maxLength: 300,
                decoration: const InputDecoration(
                  labelText: 'Judul *',
                  counterText: '',
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Judul event harus diisi.'
                    : null,
              ),
              const SizedBox(height: 12),
              ListTile(
                key: const ValueKey('event-date'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_outlined),
                title: Text('${_date.day}/${_date.month}/${_date.year}'),
                onTap: _pickDate,
              ),
              ListTile(
                key: const ValueKey('event-time'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schedule),
                title: Text(
                  _time == null ? 'Sepanjang hari' : _time!.format(context),
                ),
                trailing: _time == null
                    ? null
                    : IconButton(
                        onPressed: () {
                          setState(() {
                            _time = null;
                          });
                        },
                        icon: const Icon(Icons.close, size: 18),
                      ),
                onTap: _pickTime,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<CalendarEventType>(
                key: const ValueKey('event-type'),
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Tipe'),
                items: [
                  for (final type in CalendarEventType.values)
                    DropdownMenuItem(value: type, child: Text(type.label)),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _type = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const ValueKey('event-description'),
                controller: _descriptionController,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 3,
                maxLength: 2000,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi (opsional)',
                  counterText: '',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          key: const ValueKey('event-submit'),
          onPressed: _submit,
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
