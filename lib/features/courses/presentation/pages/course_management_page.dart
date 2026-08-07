import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../domain/entities/course_entity.dart';
import '../providers/course_provider.dart';
import '../providers/course_state.dart';
import '../widgets/course_color_picker.dart';
import '../widgets/course_form_sheet.dart';

/// CRUD page for the user's courses.
final class CourseManagementPage extends ConsumerStatefulWidget {
  const CourseManagementPage({super.key});

  @override
  ConsumerState<CourseManagementPage> createState() =>
      _CourseManagementPageState();
}

final class _CourseManagementPageState
    extends ConsumerState<CourseManagementPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(courseControllerProvider.notifier).loadCourses();
      }
    });
  }

  Future<void> _addCourse() async {
    final result = await showCourseFormSheet(context);
    if (result == null || !mounted) {
      return;
    }
    final saved = await ref
        .read(courseControllerProvider.notifier)
        .createCourse(
          name: result.name,
          code: result.code,
          credits: result.credits,
          lecturer: result.lecturer,
          color: result.color,
        );
    _showResultSnackBar(saved, 'Mata kuliah ditambahkan.');
  }

  Future<void> _importFromPhoto() async {
    final imported = await context.push<bool>(RoutePaths.courseImport);
    if (imported == true && mounted) {
      await ref.read(courseControllerProvider.notifier).loadCourses();
    }
  }

  Future<void> _editCourse(CourseEntity course) async {
    final result = await showCourseFormSheet(context, initial: course);
    if (result == null || !mounted) {
      return;
    }
    final saved = await ref
        .read(courseControllerProvider.notifier)
        .updateCourse(
          id: course.id,
          name: result.name,
          code: result.code,
          credits: result.credits,
          lecturer: result.lecturer,
          color: result.color,
        );
    _showResultSnackBar(saved, 'Perubahan disimpan.');
  }

  Future<void> _deleteCourse(CourseEntity course) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus mata kuliah?'),
        content: Text(
          '"${course.name}" beserta jadwal terkait akan dihapus permanen.',
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
        .read(courseControllerProvider.notifier)
        .deleteCourse(course.id);
    _showResultSnackBar(deleted, 'Mata kuliah dihapus.');
  }

  void _showResultSnackBar(bool success, String successMessage) {
    if (!mounted) {
      return;
    }
    final message = success
        ? successMessage
        : ref.read(courseControllerProvider).errorMessage ??
              'Terjadi kesalahan. Coba lagi.';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(courseControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mata Kuliah'),
        actions: [
          IconButton(
            key: const ValueKey('course-scan-action'),
            tooltip: 'Impor dari foto KRS',
            icon: const Icon(Icons.document_scanner_outlined),
            onPressed: state.isMutating ? null : _importFromPhoto,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('course-add-fab'),
        onPressed: state.isMutating ? null : _addCourse,
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
      body: _CourseBody(
        state: state,
        onRetry: () =>
            ref.read(courseControllerProvider.notifier).loadCourses(),
        onEdit: _editCourse,
        onDelete: _deleteCourse,
      ),
    );
  }
}

final class _CourseBody extends StatelessWidget {
  const _CourseBody({
    required this.state,
    required this.onRetry,
    required this.onEdit,
    required this.onDelete,
  });

  final CourseState state;
  final VoidCallback onRetry;
  final ValueChanged<CourseEntity> onEdit;
  final ValueChanged<CourseEntity> onDelete;

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case CourseStatus.initial:
      case CourseStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case CourseStatus.failure:
        if (state.courses.isEmpty) {
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
                    onPressed: onRetry,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ),
          );
        }
        return _CourseList(
          courses: state.courses,
          onEdit: onEdit,
          onDelete: onDelete,
        );
      case CourseStatus.loaded:
        if (state.courses.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.menu_book_outlined,
                    size: 56,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Belum ada mata kuliah.\nTekan "Tambah" untuk membuat yang pertama.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        return _CourseList(
          courses: state.courses,
          onEdit: onEdit,
          onDelete: onDelete,
        );
    }
  }
}

final class _CourseList extends StatelessWidget {
  const _CourseList({
    required this.courses,
    required this.onEdit,
    required this.onDelete,
  });

  final List<CourseEntity> courses;
  final ValueChanged<CourseEntity> onEdit;
  final ValueChanged<CourseEntity> onDelete;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: courses.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _CourseCard(
        course: courses[index],
        onEdit: onEdit,
        onDelete: onDelete,
      ),
    );
  }
}

final class _CourseCard extends StatelessWidget {
  const _CourseCard({
    required this.course,
    required this.onEdit,
    required this.onDelete,
  });

  final CourseEntity course;
  final ValueChanged<CourseEntity> onEdit;
  final ValueChanged<CourseEntity> onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = courseColorFromHex(course.color);
    final detailParts = <String>[
      if (course.code != null) course.code!,
      if (course.credits != null) '${course.credits} SKS',
    ];

    return Card(
      key: ValueKey('course-item-${course.id}'),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onEdit(course),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Accent strip keyed to the course color (design system §15).
              Container(width: 6, color: accent),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              course.name,
                              style: theme.textTheme.titleMedium,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            key: ValueKey('course-delete-${course.id}'),
                            tooltip: 'Hapus',
                            visualDensity: VisualDensity.compact,
                            onPressed: () => onDelete(course),
                            icon: Icon(
                              Icons.delete_outline,
                              color: colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                      if (detailParts.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            for (final part in detailParts) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: accent.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  part,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: accent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                          ],
                        ),
                      ],
                      if (course.lecturer != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 16,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                course.lecturer!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
