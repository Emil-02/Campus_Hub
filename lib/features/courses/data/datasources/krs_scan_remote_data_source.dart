import 'dart:convert';
import 'dart:io';

import '../../../../core/ai/gemini_client.dart';
import '../../domain/entities/imported_course_entity.dart';
import '../models/imported_course_model.dart';

/// Raised when the KRS photo cannot be turned into course rows.
final class KrsScanException implements Exception {
  const KrsScanException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Contract for the vision backend that reads KRS photos.
abstract interface class KrsScanRemoteDataSource {
  Future<List<ImportedCourseEntity>> scanImage(File image);
}

/// Reads KRS photos with the Gemini generateContent API.
final class GeminiKrsScanDataSource implements KrsScanRemoteDataSource {
  GeminiKrsScanDataSource({required GeminiClient client}) : _client = client;

  final GeminiClient _client;

  static const _prompt = '''
Kamu membaca foto tabel KRS/jadwal kuliah mahasiswa Indonesia.
Ekstrak SEMUA baris mata kuliah menjadi JSON array murni tanpa teks lain.
Skema tiap elemen:
{
  "kode": string atau null,
  "nama": string,
  "sks": integer atau null,
  "dosen": string atau null,
  "pertemuan": [
    {"hari": integer, "jam_mulai": "HH:MM", "jam_selesai": "HH:MM", "ruangan": string atau null}
  ]
}
Aturan:
- "nama" wajib ada; lewati baris yang namanya tidak terbaca.
- "dosen": gabungkan semua nama dosen dipisah ", " tanpa nomor urut.
- "hari": 1=Senin, 2=Selasa, 3=Rabu, 4=Kamis, 5=Jumat, 6=Sabtu, 7=Minggu.
- Jam memakai format 24 jam "HH:MM", contoh "07:30".
- "pertemuan" berupa array kosong jika kolom hari/jam kosong.
- Jangan mengarang data yang tidak ada di foto.
''';

  @override
  Future<List<ImportedCourseEntity>> scanImage(File image) async {
    final String text;
    try {
      text = await _client.generateJson(
        prompt: _prompt,
        imageBytes: await image.readAsBytes(),
      );
    } on GeminiException catch (error) {
      throw KrsScanException(error.message);
    }
    return _parseCourses(text);
  }

  List<ImportedCourseEntity> _parseCourses(String text) {
    final Object? decoded;
    try {
      decoded = jsonDecode(GeminiClient.stripCodeFence(text));
    } on FormatException {
      throw const KrsScanException(
        'Tabel tidak terbaca dari foto. Coba foto yang lebih jelas dan lurus.',
      );
    }

    final rows = switch (decoded) {
      final List<dynamic> list => list,
      final Map<String, dynamic> map =>
        map.values.whereType<List<dynamic>>().firstOrNull ?? const [],
      _ => const <dynamic>[],
    };
    final courses = <ImportedCourseEntity>[
      for (final row in rows)
        if (row is Map<String, dynamic>) ?ImportedCourseModel.fromJson(row),
    ];
    if (courses.isEmpty) {
      throw const KrsScanException(
        'Tidak ada mata kuliah yang terdeteksi di foto. '
        'Pastikan tabel KRS terlihat jelas.',
      );
    }
    return courses;
  }
}
