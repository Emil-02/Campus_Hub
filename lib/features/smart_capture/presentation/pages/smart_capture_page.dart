import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/supabase_provider.dart';
import '../../../../services/image_service.dart';
import '../../domain/entities/captured_item_entity.dart';
import '../providers/smart_capture_dependencies.dart';
import '../providers/smart_capture_state.dart';

/// Concludes tasks/events from pasted chat text or a photo (AI).
final class SmartCapturePage extends ConsumerStatefulWidget {
  const SmartCapturePage({super.key});

  @override
  ConsumerState<SmartCapturePage> createState() => _SmartCapturePageState();
}

final class _SmartCapturePageState extends ConsumerState<SmartCapturePage> {
  final _imageService = ImageService();
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(smartCaptureControllerProvider.notifier).reset();
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _analyzeText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      return;
    }
    FocusScope.of(context).unfocus();
    await ref.read(smartCaptureControllerProvider.notifier).analyzeText(text);
  }

  Future<void> _analyzePhoto({required bool fromCamera}) async {
    final file = await _imageService.pickKrsPhoto(fromCamera: fromCamera);
    if (file == null || !mounted) {
      return;
    }
    await ref.read(smartCaptureControllerProvider.notifier).analyzeImage(file);
  }

  Future<void> _saveSelected() async {
    final controller = ref.read(smartCaptureControllerProvider.notifier);
    final rowsBefore = ref.read(smartCaptureControllerProvider).rows;
    final eventDates = [
      for (final row in rowsBefore)
        if (row.selected && row.kind == CapturedItemKind.event)
          row.date ?? DateTime.now(),
    ];
    final success = await controller.saveSelected();
    if (!mounted) {
      return;
    }
    if (success) {
      final state = ref.read(smartCaptureControllerProvider);
      final dateFormat = DateFormat('d MMM', 'id_ID');
      final eventDatesLabel = eventDates.map(dateFormat.format).join(', ');
      final parts = <String>[
        if (state.savedTasks > 0) '${state.savedTasks} tugas',
        if (state.savedEvents > 0)
          '${state.savedEvents} event di kalender ($eventDatesLabel)',
      ];
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Berhasil menyimpan ${parts.join(' dan ')}.'),
            duration: const Duration(seconds: 6),
          ),
        );
      context.pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(smartCaptureControllerProvider);
    final geminiConfigured = ref
        .watch(environmentConfigProvider)
        .isGeminiConfigured;

    return Scaffold(
      appBar: AppBar(title: const Text('Tangkap Cerdas')),
      body: SafeArea(
        child: switch (state.status) {
          SmartCaptureStatus.analyzing => const _ProgressBody(
            message: 'AI sedang menyimpulkan…',
          ),
          SmartCaptureStatus.saving => const _ProgressBody(
            message: 'Menyimpan…',
          ),
          SmartCaptureStatus.review => _ReviewBody(
            state: state,
            onSave: _saveSelected,
            onRetake: () =>
                ref.read(smartCaptureControllerProvider.notifier).reset(),
          ),
          SmartCaptureStatus.failure => _FailureBody(
            message: state.errorMessage ?? 'Terjadi kesalahan.',
            onRetry: () =>
                ref.read(smartCaptureControllerProvider.notifier).reset(),
          ),
          SmartCaptureStatus.idle => _InputBody(
            geminiConfigured: geminiConfigured,
            textController: _textController,
            onAnalyzeText: _analyzeText,
            onCamera: () => _analyzePhoto(fromCamera: true),
            onGallery: () => _analyzePhoto(fromCamera: false),
          ),
        },
      ),
    );
  }
}

final class _InputBody extends StatelessWidget {
  const _InputBody({
    required this.geminiConfigured,
    required this.textController,
    required this.onAnalyzeText,
    required this.onCamera,
    required this.onGallery,
  });

  final bool geminiConfigured;
  final TextEditingController textController;
  final VoidCallback onAnalyzeText;
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!geminiConfigured) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
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
          ),
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Tempel chat dosen (WA/LINE) atau pengumuman tugas, '
            'AI akan menyimpulkan tugas dan event untuk Anda.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('smart-capture-text'),
            controller: textController,
            minLines: 6,
            maxLines: 12,
            textInputAction: TextInputAction.newline,
            decoration: const InputDecoration(
              hintText:
                  'Contoh: "Assalamualaikum, tugas IMK buat laporan '
                  'analisis UI aplikasi, dikumpul Jumat depan jam 23.59 '
                  'lewat LMS ya."',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const ValueKey('smart-capture-analyze'),
            onPressed: onAnalyzeText,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Simpulkan dengan AI'),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('atau dari foto', style: theme.textTheme.bodySmall),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCamera,
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Kamera'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onGallery,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Galeri'),
                ),
              ),
            ],
          ),
        ],
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

final class _ReviewBody extends ConsumerWidget {
  const _ReviewBody({
    required this.state,
    required this.onSave,
    required this.onRetake,
  });

  final SmartCaptureState state;
  final VoidCallback onSave;
  final VoidCallback onRetake;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Text(
            'AI menyimpulkan ${state.rows.length} item. '
            'Periksa dan koreksi sebelum menyimpan.',
            style: theme.textTheme.bodyMedium,
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.rows.length,
            itemBuilder: (context, index) =>
                _CapturedRowCard(index: index, state: state),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(
              children: [
                TextButton(onPressed: onRetake, child: const Text('Ulangi')),
                const Spacer(),
                FilledButton.icon(
                  key: const ValueKey('smart-capture-save'),
                  onPressed: state.selectedCount == 0 ? null : onSave,
                  icon: const Icon(Icons.download_done),
                  label: Text('Simpan ${state.selectedCount} item'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

final class _CapturedRowCard extends ConsumerWidget {
  const _CapturedRowCard({required this.index, required this.state});

  final int index;
  final SmartCaptureState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final controller = ref.read(smartCaptureControllerProvider.notifier);
    final row = state.rows[index];
    final isTask = row.kind == CapturedItemKind.task;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isPast = row.date != null && row.date!.isBefore(today);
    final dateLabel = row.date == null
        ? (isTask ? 'Tanpa deadline' : 'Pilih tanggal')
        : DateFormat('EEE, d MMM yyyy', 'id_ID').format(row.date!);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: row.selected,
                  onChanged: (_) => controller.toggleRow(index),
                ),
                Expanded(
                  child: SegmentedButton<CapturedItemKind>(
                    segments: const [
                      ButtonSegment(
                        value: CapturedItemKind.task,
                        icon: Icon(Icons.task_alt, size: 16),
                        label: Text('Tugas'),
                      ),
                      ButtonSegment(
                        value: CapturedItemKind.event,
                        icon: Icon(Icons.event, size: 16),
                        label: Text('Event'),
                      ),
                    ],
                    selected: {row.kind},
                    onSelectionChanged: (selection) =>
                        controller.setRowKind(index, selection.first),
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: TextFormField(
                key: ValueKey('smart-capture-title-$index-${row.kind}'),
                initialValue: row.title,
                decoration: const InputDecoration(
                  labelText: 'Judul',
                  isDense: true,
                ),
                onChanged: (value) => controller.setRowTitle(index, value),
              ),
            ),
            if (row.description != null)
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 8),
                child: Text(
                  row.description!,
                  style: theme.textTheme.bodySmall,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    avatar: Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: isPast ? theme.colorScheme.error : null,
                    ),
                    label: Text(
                      isPast ? '$dateLabel (lewat)' : dateLabel,
                      style: isPast
                          ? TextStyle(color: theme.colorScheme.error)
                          : null,
                    ),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: row.date ?? DateTime.now(),
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 366),
                        ),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        controller.setRowDate(index, picked);
                      }
                    },
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.schedule, size: 16),
                    label: Text(row.time ?? 'Jam'),
                    onPressed: () async {
                      final parts = row.time?.split(':');
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: parts == null
                            ? const TimeOfDay(hour: 23, minute: 59)
                            : TimeOfDay(
                                hour: int.parse(parts[0]),
                                minute: int.parse(parts[1]),
                              ),
                      );
                      if (picked != null) {
                        final hh = picked.hour.toString().padLeft(2, '0');
                        final mm = picked.minute.toString().padLeft(2, '0');
                        controller.setRowTime(index, '$hh:$mm');
                      }
                    },
                  ),
                  if (isTask && state.courses.isNotEmpty)
                    _CourseChip(index: index, state: state),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _CourseChip extends ConsumerWidget {
  const _CourseChip({required this.index, required this.state});

  final int index;
  final SmartCaptureState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(smartCaptureControllerProvider.notifier);
    final row = state.rows[index];
    final selected = state.courses
        .where((course) => course.id == row.courseId)
        .firstOrNull;

    return ActionChip(
      avatar: const Icon(Icons.menu_book_outlined, size: 16),
      label: Text(selected?.name ?? 'Mata kuliah'),
      onPressed: () async {
        final courseId = await showModalBottomSheet<String?>(
          context: context,
          builder: (sheetContext) => SafeArea(
            child: ListView(
              shrinkWrap: true,
              children: [
                ListTile(
                  title: const Text('— Tanpa mata kuliah —'),
                  onTap: () => Navigator.of(sheetContext).pop(''),
                ),
                for (final course in state.courses)
                  ListTile(
                    title: Text(course.name),
                    selected: course.id == row.courseId,
                    onTap: () => Navigator.of(sheetContext).pop(course.id),
                  ),
              ],
            ),
          ),
        );
        if (courseId != null) {
          controller.setRowCourse(index, courseId.isEmpty ? null : courseId);
        }
      },
    );
  }
}
