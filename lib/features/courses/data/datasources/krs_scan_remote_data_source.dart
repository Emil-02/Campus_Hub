import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

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
  GeminiKrsScanDataSource({
    required String? apiKey,
    http.Client? client,
    String model = 'gemini-2.5-flash',
  }) : _apiKey = apiKey,
       _client = client ?? http.Client(),
       _model = model;

  final String? _apiKey;
  final http.Client _client;
  final String _model;

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
    final apiKey = _apiKey;
    if (apiKey == null || apiKey.isEmpty) {
      throw const KrsScanException(
        'API key Gemini belum diatur. Tambahkan GEMINI_API_KEY di file .env '
        'lalu build ulang aplikasi.',
      );
    }

    final bytes = await image.readAsBytes();
    final uri = Uri.https(
      'generativelanguage.googleapis.com',
      '/v1beta/models/$_model:generateContent',
    );
    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': _prompt},
            {
              'inline_data': {
                'mime_type': 'image/jpeg',
                'data': base64Encode(bytes),
              },
            },
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0,
        'response_mime_type': 'application/json',
      },
    });

    final response = await _client
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': apiKey,
          },
          body: body,
        )
        .timeout(const Duration(seconds: 90));

    if (response.statusCode == 400 || response.statusCode == 403) {
      throw const KrsScanException(
        'API key Gemini tidak valid. Periksa GEMINI_API_KEY di file .env.',
      );
    }
    if (response.statusCode == 429) {
      throw const KrsScanException(
        'Kuota Gemini habis sementara. Tunggu sebentar lalu coba lagi.',
      );
    }
    if (response.statusCode != 200) {
      throw KrsScanException(
        'Layanan AI bermasalah (kode ${response.statusCode}). Coba lagi.',
      );
    }

    return _parseCourses(response.body);
  }

  List<ImportedCourseEntity> _parseCourses(String responseBody) {
    final Object? decodedResponse;
    try {
      decodedResponse = jsonDecode(responseBody);
    } on FormatException {
      throw const KrsScanException('Respons AI tidak dapat dibaca. Coba lagi.');
    }
    final text = _extractText(decodedResponse);
    if (text == null) {
      throw const KrsScanException(
        'AI tidak mengembalikan hasil. Coba foto yang lebih jelas.',
      );
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(_stripCodeFence(text));
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

  String? _extractText(Object? response) {
    if (response is! Map<String, dynamic>) {
      return null;
    }
    final candidates = response['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      return null;
    }
    final content = (candidates.first as Map<String, dynamic>)['content'];
    if (content is! Map<String, dynamic>) {
      return null;
    }
    final parts = content['parts'];
    if (parts is! List) {
      return null;
    }
    final text = parts
        .whereType<Map<String, dynamic>>()
        .map((part) => part['text'])
        .whereType<String>()
        .join();
    return text.isEmpty ? null : text;
  }

  String _stripCodeFence(String text) {
    final trimmed = text.trim();
    if (!trimmed.startsWith('```')) {
      return trimmed;
    }
    return trimmed
        .replaceFirst(RegExp(r'^```[a-zA-Z]*\s*'), '')
        .replaceFirst(RegExp(r'```\s*$'), '');
  }
}
