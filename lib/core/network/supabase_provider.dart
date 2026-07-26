import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/environment_config.dart';
import 'supabase_service.dart';

final environmentConfigProvider = Provider<EnvironmentConfig>((ref) {
  return EnvironmentConfig.fromDotEnv();
});

final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  return SupabaseService.client;
});
