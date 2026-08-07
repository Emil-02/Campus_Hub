import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/supabase_provider.dart';
import '../../../../services/image_service.dart';
import '../../domain/entities/imported_course_entity.dart';
import '../providers/krs_import_dependencies.dart';
import '../providers/krs_import_state.dart';

const _dayNames = <int, String>{
  1: 'Senin',
  2: 'Selasa',
  3: 'Rabu',
  4: 'Kamis',
  5: 'Jumat',
  6: 'Sabtu',
  7: 'Minggu',
};

/// Scans a KRS photo and imports the reviewed courses + schedules.
final class KrsImportPage extends ConsumerStatefulWidget {
  const KrsImportPage({super.key});

  @override
  ConsumerState<KrsImportPage> createState() => _KrsImportPageState();
}

final class _KrsImportPageState extends ConsumerState<KrsImportPage> {
  final _imageService = ImageService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(krsImportControllerProvider.notifier).reset();
      }
    });
  }

  Future<void> _pickPhoto({required bool fromCamera}) async {
    final file = await _imageService.pickKrsPhoto(fromCamera: fromCamera);
    if (file == null || !mounted) {
      return;
    }
    await ref.read(krsImportControllerProvider.notifier).scanImage(file);
  }

  Future<void> _importSelected() async {
    final controller = ref.read(krsImportControllerProvider.notifier);
    final success = await controller.importSelected();
    if (!mounted) {
      return;
    }
    if (success) {
      final state = ref.read(krsImportControllerProvider);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Berhasil impor ${state.importedCourses} mata kuliah'
              '${state.importedSchedules > 0 ? ' dan ${state.importedSchedules} jadwal' : ''}.',
            ),
          ),
        );
      context.pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(krsImportControllerProvider);
    final geminiConfigured = ref
        .watch(environmentConfigProvider)
        .isGeminiConfigured;

    return Scaffold(
      appBar: AppBar(title: const Text('Impor dari Foto')),
      body: SafeArea(
        child: switch (state.status) {
          KrsImportStatus.scanning => const _ProgressBody(
            message: 'Membaca foto dengan AI…',
          ),
          KrsImportStatus.importing => const _ProgressBody(
            message: 'Menyimpan mata kuliah…',
          ),
          KrsImportStatus.review => _ReviewBody(
            state: state,
            onToggle: (index) =>
                ref.read(krsImportControllerProvider.notifier).toggleRow(index),
            onImport: _importSelected,
            onRetake: () =>
                ref.read(krsImportControllerProvider.notifier).reset(),
          ),
          KrsImportStatus.failure => _FailureBody(
            message: state.errorMessage ?? 'Terjadi kesalahan.',
            onRetry: () =>
                ref.read(krsImportControllerProvider.notifier).reset(),
          ),
          KrsImportStatus.idle => _PickBody(
            geminiConfigured: geminiConfigured,
            onCamera: () => _pickPhoto(fromCamera: true),
            onGallery: () => _pickPhoto(fromCamera: false),
          ),
        },
      ),
    );
  }
}

final class _PickBody extends StatelessWidget {
  const _PickBody({
    required this.geminiConfigured,
    required this.onCamera,
    required this.onGallery,
  });

  final bool geminiConfigured;
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.document_scanner_outlined,
              size: 72,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Impor mata kuliah dari foto KRS',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Foto tabel KRS/jadwal kuliah Anda, lalu AI akan mengisi '
              'mata kuliah dan jadwal kelas secara otomatis. '
              'Anda bisa meninjau hasilnya sebelum disimpan.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (!geminiConfigured)
              Card(
                color: theme.colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'API key Gemini belum diatur.\n\n'
                    '1. Buka aistudio.google.com → Get API key (gratis).\n'
                    '2. Tambahkan baris GEMINI_API_KEY=kunci_anda di file .env.\n'
                    '3. Build ulang aplikasi.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              )
            else ...[
              FilledButton.icon(
                key: const ValueKey('krs-import-camera'),
                onPressed: onCamera,
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Ambil foto'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: const ValueKey('krs-import-gallery'),
                onPressed: onGallery,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Pilih dari galeri'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

final class _ProgressBody extends StatelessWidget {
  const _ProgressBody({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(message, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}

final class _FailureBody extends StatelessWidget {
  const _FailureBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 56, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Coba lagi')),
          ],
        ),
      ),
    );
  }
}

final class _ReviewBody extends StatelessWidget {
  const _ReviewBody({
    required this.state,
    required this.onToggle,
    required this.onImport,
    required this.onRetake,
  });

  final KrsImportState state;
  final ValueChanged<int> onToggle;
  final VoidCallback onImport;
  final VoidCallback onRetake;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Text(
            'Ditemukan ${state.rows.length} mata kuliah. '
            'Hilangkan centang yang tidak ingin diimpor.',
            style: theme.textTheme.bodyMedium,
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.rows.length,
            itemBuilder: (context, index) {
              final row = state.rows[index];
              return _CourseRowCard(row: row, onChanged: () => onToggle(index));
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(
              children: [
                TextButton(
                  onPressed: onRetake,
                  child: const Text('Pilih foto lain'),
                ),
                const Spacer(),
                FilledButton.icon(
                  key: const ValueKey('krs-import-save'),
                  onPressed: state.selectedCount == 0 ? null : onImport,
                  icon: const Icon(Icons.download_done),
                  label: Text('Impor ${state.selectedCount} mata kuliah'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

final class _CourseRowCard extends StatelessWidget {
  const _CourseRowCard({required this.row, required this.onChanged});

  final KrsImportRow row;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final course = row.course;
    final details = <String>[
      if (course.code != null) course.code!,
      if (course.credits != null) '${course.credits} SKS',
      if (course.lecturer != null) course.lecturer!,
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: CheckboxListTile(
        value: row.selected,
        onChanged: (_) => onChanged(),
        controlAffinity: ListTileControlAffinity.leading,
        title: Row(
          children: [
            Expanded(child: Text(course.name)),
            if (row.isDuplicate)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Chip(
                  label: const Text('Sudah ada'),
                  labelStyle: theme.textTheme.labelSmall,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (details.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(details.join(' • ')),
              ),
            if (course.meetings.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final meeting in course.meetings)
                      Chip(
                        avatar: const Icon(Icons.schedule, size: 16),
                        label: Text(_meetingLabel(meeting)),
                        labelStyle: theme.textTheme.labelSmall,
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _meetingLabel(ImportedMeetingEntity meeting) {
    final day = _dayNames[meeting.dayOfWeek] ?? 'Hari ${meeting.dayOfWeek}';
    final room = meeting.room == null ? '' : ' • ${meeting.room}';
    return '$day ${meeting.startTime}–${meeting.endTime}$room';
  }
}
