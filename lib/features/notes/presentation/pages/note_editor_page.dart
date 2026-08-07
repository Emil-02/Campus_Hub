import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../courses/domain/entities/course_entity.dart';
import '../../../courses/presentation/providers/course_provider.dart';
import '../../domain/entities/note_entity.dart';
import '../providers/note_provider.dart';

/// Rich-text editor for creating or editing a note (T-128).
final class NoteEditorPage extends ConsumerStatefulWidget {
  const NoteEditorPage({super.key, this.initial});

  final NoteEntity? initial;

  @override
  ConsumerState<NoteEditorPage> createState() => _NoteEditorPageState();
}

final class _NoteEditorPageState extends ConsumerState<NoteEditorPage> {
  late final TextEditingController _titleController;
  late final QuillController _quillController;
  String? _courseId;
  String? _noteId;
  bool _isSaving = false;

  bool get _isEditing => _noteId != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _noteId = initial?.id;
    _courseId = initial?.courseId;
    _titleController = TextEditingController(text: initial?.title ?? '');
    _quillController = QuillController(
      document: _documentFromContent(initial?.content),
      selection: const TextSelection.collapsed(offset: 0),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(courseControllerProvider.notifier).loadCourses();
      }
    });
  }

  static Document _documentFromContent(String? content) {
    if (content == null || content.trim().isEmpty) {
      return Document();
    }
    try {
      return Document.fromJson(jsonDecode(content) as List<dynamic>);
    } catch (_) {
      // Content saved by older builds may be plain text.
      return Document()..insert(0, content);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _quillController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showSnackBar('Judul catatan harus diisi.');
      return;
    }
    setState(() {
      _isSaving = true;
    });

    final content = jsonEncode(_quillController.document.toDelta().toJson());
    final contentPlain = _quillController.document.toPlainText().trim();
    final controller = ref.read(noteControllerProvider.notifier);

    bool success;
    if (_isEditing) {
      success = await controller.updateNote(
        id: _noteId!,
        title: title,
        content: content,
        contentPlain: contentPlain,
        courseId: _courseId,
      );
    } else {
      final createdId = await controller.createNote(
        title: title,
        content: content,
        contentPlain: contentPlain,
        courseId: _courseId,
      );
      success = createdId != null;
      _noteId = createdId ?? _noteId;
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _isSaving = false;
    });
    if (success) {
      Navigator.of(context).pop(true);
    } else {
      _showSnackBar(
        ref.read(noteControllerProvider).errorMessage ??
            'Gagal menyimpan catatan.',
      );
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final courses = ref.watch(courseControllerProvider).courses;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Catatan' : 'Catatan Baru'),
        actions: [
          IconButton(
            key: const ValueKey('note-save'),
            tooltip: 'Simpan',
            onPressed: _isSaving ? null : _save,
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextField(
                key: const ValueKey('note-title'),
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                style: theme.textTheme.headlineSmall,
                maxLength: 300,
                decoration: const InputDecoration(
                  hintText: 'Judul catatan',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  counterText: '',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButtonFormField<String?>(
                key: const ValueKey('note-course'),
                initialValue: _courseId,
                decoration: const InputDecoration(
                  labelText: 'Mata kuliah (opsional)',
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('— Tanpa mata kuliah —'),
                  ),
                  for (final CourseEntity course in courses)
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
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: QuillEditor.basic(
                  configurations: QuillEditorConfigurations(
                    controller: _quillController,
                    placeholder: 'Tulis isi catatan di sini…',
                    padding: const EdgeInsets.only(bottom: 16),
                  ),
                ),
              ),
            ),
            QuillToolbar.simple(
              configurations: QuillSimpleToolbarConfigurations(
                controller: _quillController,
                multiRowsDisplay: false,
                showFontFamily: false,
                showFontSize: false,
                showSubscript: false,
                showSuperscript: false,
                showColorButton: false,
                showBackgroundColorButton: false,
                showSearchButton: false,
                showAlignmentButtons: false,
                showIndent: false,
                showDividers: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
