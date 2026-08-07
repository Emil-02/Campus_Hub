import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../courses/presentation/providers/course_provider.dart';
import '../../../courses/presentation/widgets/course_color_picker.dart';
import '../../domain/entities/note_entity.dart';
import '../providers/note_provider.dart';
import '../providers/note_state.dart';
import 'note_editor_page.dart';

/// Note list with search, course filter, and link management (T-127).
final class NoteListPage extends ConsumerStatefulWidget {
  const NoteListPage({super.key});

  @override
  ConsumerState<NoteListPage> createState() => _NoteListPageState();
}

final class _NoteListPageState extends ConsumerState<NoteListPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(noteControllerProvider.notifier).loadNotes();
        ref.read(courseControllerProvider.notifier).loadCourses();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openEditor({NoteEntity? note}) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => NoteEditorPage(initial: note)),
    );
  }

  Future<void> _deleteNote(NoteEntity note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus catatan?'),
        content: Text('"${note.title}" akan dihapus.'),
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
        .read(noteControllerProvider.notifier)
        .deleteNote(note.id);
    if (mounted && !deleted) {
      _showSnackBar(
        ref.read(noteControllerProvider).errorMessage ??
            'Gagal menghapus catatan.',
      );
    }
  }

  Future<void> _addLink(NoteEntity note) async {
    final urlController = TextEditingController();
    final titleController = TextEditingController();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Tautan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const ValueKey('note-link-url'),
              controller: urlController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'URL *',
                hintText: 'https://drive.google.com/…',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('note-link-title'),
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Judul tautan (opsional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            key: const ValueKey('note-link-submit'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
    if (submitted != true || !mounted) {
      return;
    }

    final url = urlController.text.trim();
    final uri = Uri.tryParse(url);
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      _showSnackBar('Format URL tidak valid.');
      return;
    }
    final title = titleController.text.trim();
    final saved = await ref
        .read(noteControllerProvider.notifier)
        .addLink(noteId: note.id, url: url, title: title.isEmpty ? null : title);
    if (mounted && !saved) {
      _showSnackBar(
        ref.read(noteControllerProvider).errorMessage ??
            'Gagal menambah tautan.',
      );
    }
  }

  Future<void> _openLink(NoteLinkEntity link) async {
    final uri = Uri.tryParse(link.url);
    if (uri == null) {
      return;
    }
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (mounted && !launched) {
      _showSnackBar('Tidak dapat membuka tautan.');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(noteControllerProvider);
    final courses = ref.watch(courseControllerProvider).courses;

    return Scaffold(
      appBar: AppBar(title: const Text('Catatan')),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('note-add-fab'),
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: const Text('Tulis'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              key: const ValueKey('note-search'),
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (query) =>
                  ref.read(noteControllerProvider.notifier).search(query),
              decoration: InputDecoration(
                hintText: 'Cari catatan…',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                suffixIcon: state.searchQuery.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Bersihkan pencarian',
                        onPressed: () {
                          _searchController.clear();
                          ref.read(noteControllerProvider.notifier).search('');
                        },
                        icon: const Icon(Icons.close),
                      ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    key: const ValueKey('note-filter-all'),
                    label: const Text('Semua'),
                    selected: state.courseIdFilter == null,
                    onSelected: (_) => ref
                        .read(noteControllerProvider.notifier)
                        .setCourseFilter(null),
                  ),
                  const SizedBox(width: 8),
                  for (final course in courses) ...[
                    FilterChip(
                      key: ValueKey('note-filter-${course.id}'),
                      label: Text(course.name),
                      selected: state.courseIdFilter == course.id,
                      onSelected: (_) => ref
                          .read(noteControllerProvider.notifier)
                          .setCourseFilter(course.id),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          ),
          Expanded(child: _buildBody(state)),
        ],
      ),
    );
  }

  Widget _buildBody(NoteState state) {
    switch (state.status) {
      case NoteListStatus.initial:
      case NoteListStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case NoteListStatus.failure:
        if (state.notes.isEmpty) {
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
                    onPressed: () =>
                        ref.read(noteControllerProvider.notifier).loadNotes(),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ),
          );
        }
        return _buildList(state.notes);
      case NoteListStatus.loaded:
        if (state.notes.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.sticky_note_2_outlined,
                    size: 56,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.searchQuery.isEmpty
                        ? 'Belum ada catatan.\nTekan "Tulis" untuk membuat yang pertama.'
                        : 'Tidak ada catatan yang cocok dengan "${state.searchQuery}".',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        return _buildList(state.notes);
    }
  }

  Widget _buildList(List<NoteEntity> notes) {
    return RefreshIndicator(
      onRefresh: () => ref.read(noteControllerProvider.notifier).loadNotes(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        itemCount: notes.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _NoteCard(
          note: notes[index],
          onTap: () => _openEditor(note: notes[index]),
          onDelete: () => _deleteNote(notes[index]),
          onAddLink: () => _addLink(notes[index]),
          onOpenLink: _openLink,
        ),
      ),
    );
  }
}

final class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.note,
    required this.onTap,
    required this.onDelete,
    required this.onAddLink,
    required this.onOpenLink,
  });

  final NoteEntity note;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onAddLink;
  final ValueChanged<NoteLinkEntity> onOpenLink;

  static const _months = [
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final course = note.course;
    final preview = note.contentPlain?.trim() ?? '';
    final updated = note.updatedAt;

    return Card(
      key: ValueKey('note-item-${note.id}'),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      note.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  PopupMenuButton<String>(
                    key: ValueKey('note-menu-${note.id}'),
                    tooltip: 'Menu catatan',
                    onSelected: (value) {
                      if (value == 'link') {
                        onAddLink();
                      } else if (value == 'delete') {
                        onDelete();
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'link',
                        child: Text('Tambah tautan'),
                      ),
                      PopupMenuItem(value: 'delete', child: Text('Hapus')),
                    ],
                  ),
                ],
              ),
              if (preview.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  preview,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
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
                  if (updated != null)
                    Text(
                      'Diubah ${updated.day} ${_months[updated.month - 1]} '
                      '${updated.hour.toString().padLeft(2, '0')}:${updated.minute.toString().padLeft(2, '0')}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
              if (note.links.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final link in note.links)
                      ActionChip(
                        key: ValueKey('note-link-${link.id}'),
                        avatar: Icon(
                          link.linkType == NoteLinkType.googleDrive
                              ? Icons.add_to_drive
                              : Icons.link,
                          size: 16,
                        ),
                        label: Text(
                          link.title ?? Uri.parse(link.url).host,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onPressed: () => onOpenLink(link),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
