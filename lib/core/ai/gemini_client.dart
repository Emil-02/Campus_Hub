import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// Raised when the Gemini API cannot produce a usable answer.
final class GeminiException implements Exception {
  const GeminiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Thin client for the Gemini generateContent REST API (JSON responses).
final class GeminiClient {
  GeminiClient({
    required String? apiKey,
    http.Client? client,
    String model = 'gemini-flash-latest',
  }) : _apiKey = apiKey,
       _client = client ?? http.Client(),
       _model = model;

  final String? _apiKey;
  final http.Client _client;
  final String _model;

  /// Sends [prompt] (plus an optional image) and returns the response text.
  Future<String> generateJson({
    required String prompt,
    Uint8List? imageBytes,
    String imageMimeType = 'image/jpeg',
  }) async {
    final apiKey = _apiKey;
    if (apiKey == null || apiKey.isEmpty) {
      throw const GeminiException(
        'API key Gemini belum diatur. Tambahkan GEMINI_API_KEY di file .env '
        'lalu build ulang aplikasi.',
      );
    }

    final uri = Uri.https(
      'generativelanguage.googleapis.com',
      '/v1beta/models/$_model:generateContent',
    );
    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt},
            if (imageBytes != null)
              {
                'inline_data': {
                  'mime_type': imageMimeType,
                  'data': base64Encode(imageBytes),
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
      throw const GeminiException(
        'API key Gemini tidak valid. Periksa GEMINI_API_KEY di file .env.',
      );
    }
    if (response.statusCode == 404) {
      throw const GeminiException(
        'Model AI tidak tersedia untuk API key ini. Coba perbarui aplikasi.',
      );
    }
    if (response.statusCode == 429) {
      throw const GeminiException(
        'Kuota Gemini habis sementara. Tunggu sebentar lalu coba lagi.',
      );
    }
    if (response.statusCode != 200) {
      throw GeminiException(
        'Layanan AI bermasalah (kode ${response.statusCode}). Coba lagi.',
      );
    }

    return _extractText(response.body);
  }

  String _extractText(String responseBody) {
    final Object? decoded;
    try {
      decoded = jsonDecode(responseBody);
    } on FormatException {
      throw const GeminiException('Respons AI tidak dapat dibaca. Coba lagi.');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const GeminiException('Respons AI tidak dapat dibaca. Coba lagi.');
    }
    final candidates = decoded['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      throw const GeminiException(
        'AI tidak mengembalikan hasil. Coba lagi dengan input yang lebih jelas.',
      );
    }
    final content = (candidates.first as Map<String, dynamic>)['content'];
    if (content is! Map<String, dynamic>) {
      throw const GeminiException(
        'AI tidak mengembalikan hasil. Coba lagi dengan input yang lebih jelas.',
      );
    }
    final parts = content['parts'];
    if (parts is! List) {
      throw const GeminiException(
        'AI tidak mengembalikan hasil. Coba lagi dengan input yang lebih jelas.',
      );
    }
    final text = parts
        .whereType<Map<String, dynamic>>()
        .map((part) => part['text'])
        .whereType<String>()
        .join();
    if (text.isEmpty) {
      throw const GeminiException(
        'AI tidak mengembalikan hasil. Coba lagi dengan input yang lebih jelas.',
      );
    }
    return text;
  }

  /// Removes a leading/trailing markdown code fence if present.
  static String stripCodeFence(String text) {
    final trimmed = text.trim();
    if (!trimmed.startsWith('```')) {
      return trimmed;
    }
    return trimmed
        .replaceFirst(RegExp(r'^```[a-zA-Z]*\s*'), '')
        .replaceFirst(RegExp(r'```\s*$'), '');
  }
}
