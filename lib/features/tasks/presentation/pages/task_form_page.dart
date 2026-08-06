import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../courses/domain/entities/course_entity.dart';
import '../../../courses/presentation/providers/course_provider.dart';
import '../../domain/entities/task_entity.dart';
import '../widgets/task_widgets.dart';

/// Result submitted from the task form page.
final class TaskFormResult {
  const TaskFormResult({
    required this.title,
    this.description,
    this.deadline,
    required this.priority,
    this.courseId,
    this.checklistTitles = const [],
  });

  final String title;
  final String? description;
  final DateTime? deadline;
  final TaskPriority priority;
  final String? courseId;
  final List<String> checklistTitles;
}

/// Full-screen form for adding or editing a task (T-106/T-108).
final class TaskFormPage extends ConsumerStatefulWidget {
  const TaskFormPage({super.key, this.initial});

  final TaskEntity? initial;

  @override
  ConsumerState<TaskFormPage> createState() => _TaskFormPageState();
}

final class _TaskFormPageState extends ConsumerState<TaskFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  final _checklistController = TextEditingController();
  final List<String> _checklistTitles = [];
  DateTime? _deadline;
  TaskPriority _priority = TaskPriority.medium;
  String? _courseId;

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _titleController = TextEditingController(text: initial?.title ?? '');
    _descriptionController = TextEditingController(
      text: initial?.description ?? '',
    );
    _deadline = initial?.deadline;
    _priority = initial?.priority ?? TaskPriority.medium;
    _courseId = initial?.courseId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(courseControllerProvider.notifier).loadCourses();
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _checklistController.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final initial = _deadline ?? now.add(const Duration(days: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(now) ? now : initial,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (date == null || !mounted) {
      return;
    }
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _deadline = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? 23,
        time?.minute ?? 59,
      );
    });
  }

  void _addChecklistItem() {
    final title = _checklistController.text.trim();
    if (title.isEmpty || _checklistTitles.length >= 50) {
      return;
    }
    setState(() {
      _checklistTitles.add(title);
      _checklistController.clear();
    });
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final description = _descriptionController.text.trim();
    Navigator.of(context).pop(
      TaskFormResult(
        title: _titleController.text.trim(),
        description: description.isEmpty ? null : description,
        deadline: _deadline,
        priority: _priority,
        courseId: _courseId,
        checklistTitles: List.unmodifiable(_checklistTitles),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final courses = ref.watch(courseControllerProvider).courses;

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Tugas' : 'Tambah Tugas')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    key: const ValueKey('task-title'),
                    controller: _titleController,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.next,
                    maxLength: 300,
                    decoration: const InputDecoration(
                      labelText: 'Judul tugas *',
                      counterText: '',
                    ),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'Judul tugas harus diisi.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    key: const ValueKey('task-deadline'),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: theme.colorScheme.outline),
                    ),
                    leading: const Icon(Icons.event_outlined),
                    title: Text(
                      _deadline == null
                          ? 'Deadline (opsional)'
                          : formatDeadline(_deadline!),
                    ),
                    trailing: _deadline == null
                        ? const Icon(Icons.chevron_right)
                        : IconButton(
                            tooltip: 'Hapus deadline',
                            onPressed: () {
                              setState(() {
                                _deadline = null;
                              });
                            },
                            icon: const Icon(Icons.close),
                          ),
                    onTap: _pickDeadline,
                  ),
                  const SizedBox(height: 16),
                  Text('Prioritas', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  SegmentedButton<TaskPriority>(
                    key: const ValueKey('task-priority'),
                    segments: [
                      for (final priority in TaskPriority.values)
                        ButtonSegment(
                          value: priority,
                          label: Text(
                            priority.label,
                            style: theme.textTheme.labelMedium,
                          ),
                        ),
                    ],
                    selected: {_priority},
                    onSelectionChanged: (selection) {
                      setState(() {
                        _priority = selection.first;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String?>(
                    key: const ValueKey('task-course'),
                    initialValue: _courseId,
                    decoration: const InputDecoration(
                      labelText: 'Mata kuliah (opsional)',
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('— Tanpa mata kuliah —'),
                      ),
                      for (final CourseEntity course in courses)
                        DropdownMenuItem(
                          value: course.id,
                          child: Text(
                            course.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _courseId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const ValueKey('task-description'),
                    controller: _descriptionController,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 4,
                    maxLength: 5000,
                    decoration: const InputDecoration(
                      labelText: 'Deskripsi (opsional)',
                      alignLabelWithHint: true,
                      counterText: '',
                    ),
                  ),
                  if (!_isEditing) ...[
                    const SizedBox(height: 16),
                    Text('Checklist', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    for (var i = 0; i < _checklistTitles.length; i++)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.check_box_outline_blank,
                          size: 20,
                        ),
                        title: Text(_checklistTitles[i]),
                        trailing: IconButton(
                          tooltip: 'Hapus item',
                          onPressed: () {
                            setState(() {
                              _checklistTitles.removeAt(i);
                            });
                          },
                          icon: const Icon(Icons.close, size: 18),
                        ),
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            key: const ValueKey('task-checklist-input'),
                            controller: _checklistController,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _addChecklistItem(),
                            decoration: const InputDecoration(
                              hintText: 'Tambah sub-tugas…',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          key: const ValueKey('task-checklist-add'),
                          onPressed: _addChecklistItem,
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 32),
                  FilledButton(
                    key: const ValueKey('task-submit'),
                    onPressed: _submit,
                    child: Text(_isEditing ? 'Simpan Perubahan' : 'Tambah'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
