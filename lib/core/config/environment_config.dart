import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvironmentConfig {
  const EnvironmentConfig({
    this.supabaseUrl,
    this.supabaseAnonKey,
    this.geminiApiKey,
  });

  factory EnvironmentConfig.fromDotEnv() {
    return EnvironmentConfig(
      supabaseUrl: _readValue('SUPABASE_URL'),
      supabaseAnonKey: _readValue('SUPABASE_ANON_KEY'),
      geminiApiKey: _readValue('GEMINI_API_KEY'),
    );
  }

  final String? supabaseUrl;
  final String? supabaseAnonKey;
  final String? geminiApiKey;

  bool get isSupabaseConfigured =>
      _hasValue(supabaseUrl) && _hasValue(supabaseAnonKey);

  bool get isGeminiConfigured => _hasValue(geminiApiKey);

  static String? _readValue(String key) {
    final value = dotenv.env[key]?.trim();
    return _hasValue(value) ? value : null;
  }

  static bool _hasValue(String? value) => value != null && value.isNotEmpty;
}
