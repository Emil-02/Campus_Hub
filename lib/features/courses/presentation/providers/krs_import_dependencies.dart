import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/supabase_provider.dart';
import '../../data/datasources/krs_scan_remote_data_source.dart';
import '../../data/repositories/krs_scan_repository_impl.dart';
import '../../domain/repositories/krs_scan_repository.dart';
import 'krs_import_controller.dart';
import 'krs_import_state.dart';

/// Provides the Gemini-backed scan datasource.
final krsScanDataSourceProvider = Provider<KrsScanRemoteDataSource>((ref) {
  final config = ref.watch(environmentConfigProvider);
  return GeminiKrsScanDataSource(apiKey: config.geminiApiKey);
});

/// Provides the domain scan repository implementation.
final krsScanRepositoryProvider = Provider<KrsScanRepository>((ref) {
  return KrsScanRepositoryImpl(ref.watch(krsScanDataSourceProvider));
});

/// Exposes the photo-import controller state.
final krsImportControllerProvider =
    NotifierProvider<KrsImportController, KrsImportState>(
      KrsImportController.new,
    );
