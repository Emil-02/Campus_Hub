import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ai/ai_providers.dart';
import '../../data/datasources/smart_capture_remote_data_source.dart';
import '../../data/repositories/smart_capture_repository_impl.dart';
import '../../domain/repositories/smart_capture_repository.dart';
import 'smart_capture_controller.dart';
import 'smart_capture_state.dart';

export '../../../../services/service_providers.dart'
    show notificationServiceProvider;

/// Provides the Gemini-backed smart-capture datasource.
final smartCaptureDataSourceProvider = Provider<SmartCaptureRemoteDataSource>((
  ref,
) {
  return GeminiSmartCaptureDataSource(client: ref.watch(geminiClientProvider));
});

/// Provides the domain smart-capture repository implementation.
final smartCaptureRepositoryProvider = Provider<SmartCaptureRepository>((ref) {
  return SmartCaptureRepositoryImpl(ref.watch(smartCaptureDataSourceProvider));
});

/// Exposes the smart-capture controller state.
final smartCaptureControllerProvider =
    NotifierProvider<SmartCaptureController, SmartCaptureState>(
      SmartCaptureController.new,
    );
