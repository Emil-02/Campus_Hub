import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/supabase_provider.dart';
import '../../data/datasources/course_remote_data_source.dart';
import '../../data/repositories/course_repository_impl.dart';
import '../../domain/repositories/course_repository.dart';

/// Provides the remote course datasource from the existing client.
final courseRemoteDataSourceProvider = Provider<CourseRemoteDataSource>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) {
    throw StateError(
      'Supabase is not initialized; course data is unavailable.',
    );
  }
  return CourseRemoteDataSourceImpl(client);
});

/// Provides the domain course repository implementation.
final courseRepositoryProvider = Provider<CourseRepository>((ref) {
  return CourseRepositoryImpl(ref.watch(courseRemoteDataSourceProvider));
});
