import 'package:flutter/material.dart';

import '../../domain/entities/course_entity.dart';
import 'course_color_picker.dart';

/// Result submitted from the course form sheet.
final class CourseFormResult {
  const CourseFormResult({
    required this.name,
    this.code,
    this.credits,
    this.lecturer,
    required this.color,
  });

  final String name;
  final String? code;
  final int? credits;
  final String? lecturer;
  final String color;
}

/// Opens the add/edit course form. Returns null when cancelled.
Future<CourseFormResult?> showCourseFormSheet(
  BuildContext context, {
  CourseEntity? initial,
}) {
  return showModalBottomSheet<CourseFormResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _CourseFormSheet(initial: initial),
  );
}

final class _CourseFormSheet extends StatefulWidget {
  const _CourseFormSheet({this.initial});

  final CourseEntity? initial;

  @override
  State<_CourseFormSheet> createState() => _CourseFormSheetState();
}

final class _CourseFormSheetState extends State<_CourseFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _creditsController;
  late final TextEditingController _lecturerController;
  late String _selectedColor;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _nameController = TextEditingController(text: initial?.name ?? '');
    _codeController = TextEditingController(text: initial?.code ?? '');
    _creditsController = TextEditingController(
      text: initial?.credits?.toString() ?? '',
    );
    _lecturerController = TextEditingController(text: initial?.lecturer ?? '');
    _selectedColor = initial?.color ?? courseColorPalette.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _creditsController.dispose();
    _lecturerController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final code = _codeController.text.trim();
    final lecturer = _lecturerController.text.trim();
    final creditsText = _creditsController.text.trim();
    Navigator.of(context).pop(
      CourseFormResult(
        name: _nameController.text.trim(),
        code: code.isEmpty ? null : code,
        credits: creditsText.isEmpty ? null : int.parse(creditsText),
        lecturer: lecturer.isEmpty ? null : lecturer,
        color: _selectedColor,
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
                isEditing ? 'Edit Mata Kuliah' : 'Tambah Mata Kuliah',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const ValueKey('course-name'),
                controller: _nameController,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                maxLength: 200,
                decoration: const InputDecoration(
                  labelText: 'Nama mata kuliah *',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama mata kuliah wajib diisi.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      key: const ValueKey('course-code'),
                      controller: _codeController,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 20,
                      decoration: const InputDecoration(
                        labelText: 'Kode',
                        hintText: 'IF1234',
                        border: OutlineInputBorder(),
                        counterText: '',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 96,
                    child: TextFormField(
                      key: const ValueKey('course-credits'),
                      controller: _creditsController,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'SKS',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty) {
                          return null;
                        }
                        final credits = int.tryParse(text);
                        if (credits == null || credits < 1 || credits > 6) {
                          return '1-6';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const ValueKey('course-lecturer'),
                controller: _lecturerController,
                textInputAction: TextInputAction.done,
                textCapitalization: TextCapitalization.words,
                maxLength: 200,
                decoration: const InputDecoration(
                  labelText: 'Dosen',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 16),
              Text('Warna', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              CourseColorPicker(
                selectedColor: _selectedColor,
                onColorSelected: (color) {
                  setState(() {
                    _selectedColor = color;
                  });
                },
              ),
              const SizedBox(height: 24),
              FilledButton(
                key: const ValueKey('course-submit'),
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
