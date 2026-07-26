import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvironmentConfig {
  const EnvironmentConfig({this.supabaseUrl, this.supabaseAnonKey});

  factory EnvironmentConfig.fromDotEnv() {
    return EnvironmentConfig(
      supabaseUrl: _readValue('SUPABASE_URL'),
      supabaseAnonKey: _readValue('SUPABASE_ANON_KEY'),
    );
  }

  final String? supabaseUrl;
  final String? supabaseAnonKey;

  bool get isSupabaseConfigured =>
      _hasValue(supabaseUrl) && _hasValue(supabaseAnonKey);

  static String? _readValue(String key) {
    final value = dotenv.env[key]?.trim();
    return _hasValue(value) ? value : null;
  }

  static bool _hasValue(String? value) => value != null && value.isNotEmpty;
}
