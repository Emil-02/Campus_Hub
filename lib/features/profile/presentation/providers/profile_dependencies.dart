import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/supabase_provider.dart';
import '../../../../services/image_service.dart';
import '../../data/datasources/profile_remote_data_source.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../domain/repositories/profile_repository.dart';

/// Provides the image picking/compression service.
final imageServiceProvider = Provider<ImageService>((ref) {
  return ImageService();
});

/// Provides the remote profile datasource from the existing client.
final profileRemoteDataSourceProvider = Provider<ProfileRemoteDataSource>((
  ref,
) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) {
    throw StateError(
      'Supabase is not initialized; profile data is unavailable.',
    );
  }
  return ProfileRemoteDataSourceImpl(client);
});

/// Provides the domain profile repository implementation.
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl(ref.watch(profileRemoteDataSourceProvider));
});
