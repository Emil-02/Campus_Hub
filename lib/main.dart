import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/config/environment_config.dart';
import 'core/network/supabase_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables. Do not crash if .env is missing or invalid at this stage.
  try {
    await dotenv.load(fileName: ".env");
  } catch (error) {
    debugPrint('Warning: .env file not found or invalid.');
    debugPrint(error.toString());
  }

  final environmentConfig = EnvironmentConfig.fromDotEnv();
  final startupStatus = await SupabaseService.initialize(environmentConfig);

  runApp(ProviderScope(child: CampusMateApp(startupStatus: startupStatus)));
}
