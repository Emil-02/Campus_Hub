import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';

import '../../../../core/ai/gemini_client.dart';
import '../../domain/entities/captured_item_entity.dart';
import '../models/captured_item_model.dart';

/// Raised when text/photo cannot be concluded into tasks or events.
final class SmartCaptureException implements Exception {
  const SmartCaptureException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Contract for the AI backend that concludes tasks/events.
abstract interface class SmartCaptureRemoteDataSource {
  Future<List<CapturedItemEntity>> analyzeText(
    String text, {
    required List<String> courseNames,
  });

  Future<List<CapturedItemEntity>> analyzeImage(
    File image, {
    required List<String> courseNames,
  });
}

/// Concludes tasks/events from chat text or photos via Gemini.
final class GeminiSmartCaptureDataSource
    implements SmartCaptureRemoteDataSource {
  GeminiSmartCaptureDataSource({required GeminiClient client, DateTime? now})
    : _client = client,
      _now = now;

  final GeminiClient _client;

  /// Injectable clock for deterministic tests.
  final DateTime? _now;

  String _prompt(List<String> courseNames) {
    final now = _now ?? DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);
    final weekday = DateFormat('EEEE', 'id_ID').format(now);
    final courses = courseNames.isEmpty
        ? '(belum ada)'
        : courseNames.map((name) => '"$name"').join(', ');
    return '''
Kamu membantu mahasiswa Indonesia menyimpulkan TUGAS kuliah dan EVENT dari
pesan chat (WhatsApp/LINE) dosen atau teman, atau dari foto pengumuman.
Hari ini adalah $weekday, $today.
Daftar mata kuliah milik pengguna: $courses.

Keluarkan JSON array murni tanpa teks lain. Skema tiap elemen:
{
  "jenis": "task" atau "event",
  "judul": string,
  "deskripsi": string atau null,
  "tanggal": "YYYY-MM-DD" atau null,
  "jam": "HH:MM" atau null,
  "mata_kuliah": string atau null
}
Aturan:
- "task" = ada yang harus dikerjakan/dikumpulkan (tugas, laporan, kuis take-home).
- "event" = kejadian pada waktu tertentu (ujian, seminar, kelas pengganti, rapat).
- "judul" singkat dan jelas, contoh: "Laporan Praktikum Bab 3".
- "deskripsi": detail penting lain dari pesan (format pengumpulan, link, catatan).
- "tanggal": simpulkan tanggal pasti dari kata relatif ("besok", "Jumat depan",
  "minggu depan") dihitung dari hari ini $today. Jika tidak disebut, null.
- "jam": jam deadline/mulai jika disebut (contoh "23:59", "13:00"), selain itu null.
- "mata_kuliah": pilih PERSIS salah satu dari daftar mata kuliah pengguna jika
  pesan cocok dengan salah satunya (singkatan seperti "IMK" boleh dicocokkan),
  selain itu null. Jangan membuat nama baru.
- Satu pesan bisa berisi beberapa tugas/event; keluarkan semuanya.
- Jangan mengarang informasi yang tidak ada di pesan.
''';
  }

  @override
  Future<List<CapturedItemEntity>> analyzeText(
    String text, {
    required List<String> courseNames,
  }) async {
    final String result;
    try {
      result = await _client.generateJson(
        prompt: '${_prompt(courseNames)}\nPesan:\n"""\n$text\n"""',
      );
    } on GeminiException catch (error) {
      throw SmartCaptureException(error.message);
    }
    return _parseItems(result);
  }

  @override
  Future<List<CapturedItemEntity>> analyzeImage(
    File image, {
    required List<String> courseNames,
  }) async {
    final String result;
    try {
      result = await _client.generateJson(
        prompt: _prompt(courseNames),
        imageBytes: await image.readAsBytes(),
      );
    } on GeminiException catch (error) {
      throw SmartCaptureException(error.message);
    }
    return _parseItems(result);
  }

  List<CapturedItemEntity> _parseItems(String text) {
    final Object? decoded;
    try {
      decoded = jsonDecode(GeminiClient.stripCodeFence(text));
    } on FormatException {
      throw const SmartCaptureException(
        'Hasil AI tidak terbaca. Coba lagi dengan pesan yang lebih jelas.',
      );
    }

    final rows = switch (decoded) {
      final List<dynamic> list => list,
      final Map<String, dynamic> map =>
        map.values.whereType<List<dynamic>>().firstOrNull ?? [map],
      _ => const <dynamic>[],
    };
    final items = <CapturedItemEntity>[
      for (final row in rows)
        if (row is Map<String, dynamic>) ?CapturedItemModel.fromJson(row),
    ];
    if (items.isEmpty) {
      throw const SmartCaptureException(
        'Tidak ada tugas atau event yang terdeteksi. '
        'Pastikan pesan berisi informasi tugas/event.',
      );
    }
    return items;
  }
}
