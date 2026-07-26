import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/environment_config.dart';

enum SupabaseStartupStatus {
  developmentMode,
  initialized,
  initializationFailed,
}

class SupabaseService {
  SupabaseService._();

  static SupabaseStartupStatus _status = SupabaseStartupStatus.developmentMode;

  static SupabaseStartupStatus get status => _status;

  static SupabaseClient? get client {
    if (_status != SupabaseStartupStatus.initialized) {
      return null;
    }
    return Supabase.instance.client;
  }

  static Future<SupabaseStartupStatus> initialize(
    EnvironmentConfig config,
  ) async {
    if (!config.isSupabaseConfigured) {
      _status = SupabaseStartupStatus.developmentMode;
      return _status;
    }

    try {
      await Supabase.initialize(
        url: config.supabaseUrl!,
        publishableKey: config.supabaseAnonKey!,
      );
      _status = SupabaseStartupStatus.initialized;
    } catch (error, stackTrace) {
      _status = SupabaseStartupStatus.initializationFailed;
      debugPrint('Supabase initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }

    return _status;
  }
}
