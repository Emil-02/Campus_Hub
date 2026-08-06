import 'package:flutter/material.dart';

import '../../../courses/domain/entities/course_entity.dart';
import '../../domain/entities/schedule_entity.dart';

const dayNames = <int, String>{
  1: 'Senin',
  2: 'Selasa',
  3: 'Rabu',
  4: 'Kamis',
  5: 'Jumat',
  6: 'Sabtu',
  7: 'Minggu',
};

/// Result submitted from the schedule form sheet.
final class ScheduleFormResult {
  const ScheduleFormResult({
    required this.courseId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.room,
  });

  final String courseId;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final String? room;
}

/// Opens the add/edit schedule form. Returns null when cancelled.
Future<ScheduleFormResult?> showScheduleFormSheet(
  BuildContext context, {
  required List<CourseEntity> courses,
  ScheduleEntity? initial,
}) {
  return showModalBottomSheet<ScheduleFormResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) =>
        _ScheduleFormSheet(courses: courses, initial: initial),
  );
}

final class _ScheduleFormSheet extends StatefulWidget {
  const _ScheduleFormSheet({required this.courses, this.initial});

  final List<CourseEntity> courses;
  final ScheduleEntity? initial;

  @override
  State<_ScheduleFormSheet> createState() => _ScheduleFormSheetState();
}

final class _ScheduleFormSheetState extends State<_ScheduleFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _roomController;
  String? _courseId;
  int _dayOfWeek = 1;
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 9, minute: 40);

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _roomController = TextEditingController(text: initial?.room ?? '');
    if (initial != null) {
      _courseId = initial.courseId;
      _dayOfWeek = initial.dayOfWeek;
      _startTime = _parse(initial.startTime);
      _endTime = _parse(initial.endTime);
    } else if (widget.courses.length == 1) {
      _courseId = widget.courses.first.id;
    }
  }

  @override
  void dispose() {
    _roomController.dispose();
    super.dispose();
  }

  static TimeOfDay _parse(String time) {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 0,
      minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
    );
  }

  static String _format(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  bool get _isTimeOrderValid {
    final start = _startTime.hour * 60 + _startTime.minute;
    final end = _endTime.hour * 60 + _endTime.minute;
    return start < end;
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked == null) {
      return;
    }
    setState(() {
      if (isStart) {
        _startTime = picked;
      } else {
        _endTime = picked;
      }
    });
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (!_isTimeOrderValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jam selesai harus setelah jam mulai.')),
      );
      return;
    }
    final room = _roomController.text.trim();
    Navigator.of(context).pop(
      ScheduleFormResult(
        courseId: _courseId!,
        dayOfWeek: _dayOfWeek,
        startTime: _format(_startTime),
        endTime: _format(_endTime),
        room: room.isEmpty ? null : room,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initial != null;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEditing ? 'Edit Jadwal' : 'Tambah Jadwal',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                key: const ValueKey('schedule-course'),
                initialValue: _courseId,
                decoration: const InputDecoration(labelText: 'Mata kuliah *'),
                items: [
                  for (final course in widget.courses)
                    DropdownMenuItem(
                      value: course.id,
                      child: Text(course.name, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (value) {
                  setState(() {
                    _courseId = value;
                  });
                },
                validator: (value) =>
                    value == null ? 'Pilih mata kuliah.' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                key: const ValueKey('schedule-day'),
                initialValue: _dayOfWeek,
                decoration: const InputDecoration(labelText: 'Hari *'),
                items: [
                  for (final entry in dayNames.entries)
                    DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _dayOfWeek = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _TimeField(
                      key: const ValueKey('schedule-start'),
                      label: 'Jam mulai',
                      value: _format(_startTime),
                      onTap: () => _pickTime(isStart: true),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _TimeField(
                      key: const ValueKey('schedule-end'),
                      label: 'Jam selesai',
                      value: _format(_endTime),
                      onTap: () => _pickTime(isStart: false),
                    ),
                  ),
                ],
              ),
              if (!_isTimeOrderValid) ...[
                const SizedBox(height: 8),
                Text(
                  'Jam selesai harus setelah jam mulai.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                key: const ValueKey('schedule-room'),
                controller: _roomController,
                textCapitalization: TextCapitalization.characters,
                maxLength: 50,
                decoration: const InputDecoration(
                  labelText: 'Ruangan',
                  hintText: 'R. 3.2',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                key: const ValueKey('schedule-submit'),
                onPressed: _submit,
                child: Text(isEditing ? 'Simpan Perubahan' : 'Tambah'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _TimeField extends StatelessWidget {
  const _TimeField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.access_time, size: 20),
        ),
        child: Text(value),
      ),
    );
  }
}
