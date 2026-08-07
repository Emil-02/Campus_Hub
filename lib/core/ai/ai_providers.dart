import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/supabase_provider.dart';
import 'gemini_client.dart';

/// App-wide Gemini client configured from the environment.
final geminiClientProvider = Provider<GeminiClient>((ref) {
  final config = ref.watch(environmentConfigProvider);
  return GeminiClient(apiKey: config.geminiApiKey);
});
