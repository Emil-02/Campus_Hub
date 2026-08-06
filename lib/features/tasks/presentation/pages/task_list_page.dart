import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/task_entity.dart';
import '../providers/task_provider.dart';
import '../providers/task_state.dart';
import '../widgets/task_widgets.dart';
import 'task_form_page.dart';

/// Task list with filter chips, completion toggle, and checklist detail.
final class TaskListPage extends ConsumerStatefulWidget {
  const TaskListPage({super.key});

  @override
  ConsumerState<TaskListPage> createState() => _TaskListPageState();
}

final class _TaskListPageState extends ConsumerState<TaskListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(taskControllerProvider.notifier).loadTasks();
      }
    });
  }

  Future<void> _addTask() async {
    final result = await Navigator.of(context).push<TaskFormResult>(
      MaterialPageRoute(builder: (_) => const TaskFormPage()),
    );
    if (result == null || !mounted) {
      return;
    }
    final saved = await ref
        .read(taskControllerProvider.notifier)
        .createTask(
          title: result.title,
          description: result.description,
          deadline: result.deadline,
          priority: result.priority,
          courseId: result.courseId,
          checklistTitles: result.checklistTitles,
        );
    _showResultSnackBar(saved, 'Tugas ditambahkan.');
  }

  Future<void> _editTask(TaskEntity task) async {
    final result = await Navigator.of(context).push<TaskFormResult>(
      MaterialPageRoute(builder: (_) => TaskFormPage(initial: task)),
    );
    if (result == null || !mounted) {
      return;
    }
    final saved = await ref
        .read(taskControllerProvider.notifier)
        .updateTask(
          id: task.id,
          title: result.title,
          description: result.description,
          deadline: result.deadline,
          priority: result.priority,
          courseId: result.courseId,
        );
    _showResultSnackBar(saved, 'Perubahan disimpan.');
  }

  Future<void> _deleteTask(TaskEntity task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus tugas?'),
        content: Text('"${task.title}" akan dihapus.'),
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
        .read(taskControllerProvider.notifier)
        .deleteTask(task.id);
    _showResultSnackBar(deleted, 'Tugas dihapus.');
  }

  Future<void> _toggleCompleted(TaskEntity task, bool completed) async {
    final saved = await ref
        .read(taskControllerProvider.notifier)
        .setTaskCompleted(id: task.id, completed: completed);
    if (!saved) {
      _showResultSnackBar(false, '');
    }
  }

  void _openDetail(TaskEntity task) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _TaskDetailSheet(
        taskId: task.id,
        onEdit: _editTask,
        onDelete: _deleteTask,
      ),
    );
  }

  void _showResultSnackBar(bool success, String successMessage) {
    if (!mounted) {
      return;
    }
    final message = success
        ? successMessage
        : ref.read(taskControllerProvider).errorMessage ??
              'Terjadi kesalahan. Coba lagi.';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(taskControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tugas')),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('task-add-fab'),
        onPressed: state.isMutating ? null : _addTask,
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final filter in TaskListFilter.values) ...[
                    FilterChip(
                      key: ValueKey('task-filter-${filter.name}'),
                      label: Text(filter.label),
                      selected: state.filter == filter,
                      onSelected: (_) => ref
                          .read(taskControllerProvider.notifier)
                          .setFilter(filter),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          ),
          Expanded(child: _TaskBody(state: state, page: this)),
        ],
      ),
    );
  }
}

final class _TaskBody extends StatelessWidget {
  const _TaskBody({required this.state, required this.page});

  final TaskState state;
  final _TaskListPageState page;

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case TaskListStatus.initial:
      case TaskListStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case TaskListStatus.failure:
        if (state.tasks.isEmpty) {
          return Center(
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
                    onPressed: () => page.ref
                        .read(taskControllerProvider.notifier)
                        .loadTasks(),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ),
          );
        }
        return _TaskListView(state: state, page: page);
      case TaskListStatus.loaded:
        final visible = state.visibleTasks;
        if (visible.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.task_alt_outlined,
                    size: 56,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.filter == TaskListFilter.all
                        ? 'Belum ada tugas.\nTekan "Tambah" untuk membuat yang pertama.'
                        : 'Tidak ada tugas pada filter "${state.filter.label}".',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        return _TaskListView(state: state, page: page);
    }
  }
}

final class _TaskListView extends StatelessWidget {
  const _TaskListView({required this.state, required this.page});

  final TaskState state;
  final _TaskListPageState page;

  @override
  Widget build(BuildContext context) {
    final tasks = state.visibleTasks;
    return RefreshIndicator(
      onRefresh: () =>
          page.ref.read(taskControllerProvider.notifier).loadTasks(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        itemCount: tasks.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final task = tasks[index];
          return TaskCard(
            task: task,
            onToggleCompleted: (completed) =>
                page._toggleCompleted(task, completed),
            onTap: () => page._openDetail(task),
          );
        },
      ),
    );
  }
}

/// Bottom sheet showing full task info with a live checklist.
final class _TaskDetailSheet extends ConsumerStatefulWidget {
  const _TaskDetailSheet({
    required this.taskId,
    required this.onEdit,
    required this.onDelete,
  });

  final String taskId;
  final ValueChanged<TaskEntity> onEdit;
  final ValueChanged<TaskEntity> onDelete;

  @override
  ConsumerState<_TaskDetailSheet> createState() => _TaskDetailSheetState();
}

final class _TaskDetailSheetState extends ConsumerState<_TaskDetailSheet> {
  final _newItemController = TextEditingController();

  @override
  void dispose() {
    _newItemController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(taskControllerProvider);
    final task = state.tasks
        .where((task) => task.id == widget.taskId)
        .firstOrNull;

    if (task == null) {
      return const SizedBox(height: 120);
    }

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) => ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(task.title, style: theme.textTheme.titleLarge),
              ),
              IconButton(
                key: const ValueKey('task-detail-edit'),
                tooltip: 'Edit',
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onEdit(task);
                },
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                key: const ValueKey('task-detail-delete'),
                tooltip: 'Hapus',
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onDelete(task);
                },
                icon: Icon(
                  Icons.delete_outline,
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              PriorityBadge(priority: task.priority),
              if (task.course != null)
                Text(
                  task.course!.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          if (task.deadline != null) ...[
            const SizedBox(height: 8),
            DeadlineIndicator(
              deadline: task.deadline!,
              isCompleted: task.isCompleted,
            ),
          ],
          if (task.description != null) ...[
            const SizedBox(height: 16),
            Text(task.description!, style: theme.textTheme.bodyLarge),
          ],
          const SizedBox(height: 24),
          Text(
            'Checklist (${task.checklist.where((item) => item.isCompleted).length}/${task.checklist.length})',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          for (final item in task.checklist)
            CheckboxListTile(
              key: ValueKey('checklist-${item.id}'),
              value: item.isCompleted,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                item.title,
                style: item.isCompleted
                    ? theme.textTheme.bodyLarge?.copyWith(
                        decoration: TextDecoration.lineThrough,
                        color: theme.colorScheme.onSurfaceVariant,
                      )
                    : theme.textTheme.bodyLarge,
              ),
              secondary: IconButton(
                tooltip: 'Hapus item',
                onPressed: () => ref
                    .read(taskControllerProvider.notifier)
                    .deleteChecklistItem(item.id),
                icon: const Icon(Icons.close, size: 18),
              ),
              onChanged: (value) => ref
                  .read(taskControllerProvider.notifier)
                  .toggleChecklistItem(
                    id: item.id,
                    isCompleted: value ?? false,
                  ),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const ValueKey('task-detail-new-item'),
                  controller: _newItemController,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _addItem(task.id),
                  decoration: const InputDecoration(
                    hintText: 'Tambah sub-tugas…',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                key: const ValueKey('task-detail-add-item'),
                onPressed: () => _addItem(task.id),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _addItem(String taskId) async {
    final title = _newItemController.text.trim();
    if (title.isEmpty) {
      return;
    }
    _newItemController.clear();
    await ref
        .read(taskControllerProvider.notifier)
        .addChecklistItem(taskId: taskId, title: title);
  }
}
