import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/profile_provider.dart';

const _degreeLevels = ['D3', 'D4', 'S1'];

/// Form for editing academic profile fields (T-068).
final class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

final class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _universityController;
  late final TextEditingController _studyProgramController;
  late final TextEditingController _semesterController;
  String? _degreeLevel;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileControllerProvider).profile;
    _nameController = TextEditingController(text: profile?.fullName ?? '');
    _universityController = TextEditingController(
      text: profile?.university ?? '',
    );
    _studyProgramController = TextEditingController(
      text: profile?.studyProgram ?? '',
    );
    _semesterController = TextEditingController(
      text: profile?.semester?.toString() ?? '',
    );
    _degreeLevel = profile?.degreeLevel;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _universityController.dispose();
    _studyProgramController.dispose();
    _semesterController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final university = _universityController.text.trim();
    final studyProgram = _studyProgramController.text.trim();
    final semesterText = _semesterController.text.trim();

    final saved = await ref
        .read(profileControllerProvider.notifier)
        .updateProfile(
          fullName: _nameController.text.trim(),
          university: university.isEmpty ? null : university,
          studyProgram: studyProgram.isEmpty ? null : studyProgram,
          degreeLevel: _degreeLevel,
          semester: semesterText.isEmpty ? null : int.parse(semesterText),
        );
    if (!mounted) {
      return;
    }
    if (saved) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Profil disimpan.')));
      context.pop();
    } else {
      final message =
          ref.read(profileControllerProvider).errorMessage ??
          'Gagal menyimpan profil.';
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMutating = ref.watch(
      profileControllerProvider.select((state) => state.isMutating),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profil')),
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
                    key: const ValueKey('edit-profile-name'),
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    maxLength: 100,
                    decoration: const InputDecoration(
                      labelText: 'Nama lengkap *',
                      counterText: '',
                    ),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) {
                        return 'Nama harus diisi.';
                      }
                      if (text.length < 2) {
                        return 'Nama minimal 2 karakter.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const ValueKey('edit-profile-university'),
                    controller: _universityController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    maxLength: 200,
                    decoration: const InputDecoration(
                      labelText: 'Universitas',
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const ValueKey('edit-profile-program'),
                    controller: _studyProgramController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    maxLength: 200,
                    decoration: const InputDecoration(
                      labelText: 'Program studi',
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          key: const ValueKey('edit-profile-degree'),
                          initialValue: _degreeLevel,
                          decoration: const InputDecoration(
                            labelText: 'Jenjang',
                          ),
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('—'),
                            ),
                            for (final level in _degreeLevels)
                              DropdownMenuItem(
                                value: level,
                                child: Text(level),
                              ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _degreeLevel = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 120,
                        child: TextFormField(
                          key: const ValueKey('edit-profile-semester'),
                          controller: _semesterController,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          decoration: const InputDecoration(
                            labelText: 'Semester',
                          ),
                          validator: (value) {
                            final text = value?.trim() ?? '';
                            if (text.isEmpty) {
                              return null;
                            }
                            final semester = int.tryParse(text);
                            if (semester == null ||
                                semester < 1 ||
                                semester > 14) {
                              return '1-14';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    key: const ValueKey('edit-profile-save'),
                    onPressed: isMutating ? null : _save,
                    child: isMutating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Simpan'),
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
