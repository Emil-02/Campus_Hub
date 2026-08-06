import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/supabase_provider.dart';
import '../../../../services/notification_service.dart';
import '../../data/datasources/schedule_remote_data_source.dart';
import '../../data/repositories/schedule_repository_impl.dart';
import '../../domain/repositories/schedule_repository.dart';

/// Provides the local notification service for schedule reminders.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// Provides the remote schedule datasource from the existing client.
final scheduleRemoteDataSourceProvider = Provider<ScheduleRemoteDataSource>((
  ref,
) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) {
    throw StateError(
      'Supabase is not initialized; schedule data is unavailable.',
    );
  }
  return ScheduleRemoteDataSourceImpl(client);
});

/// Provides the domain schedule repository implementation.
final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  return ScheduleRepositoryImpl(ref.watch(scheduleRemoteDataSourceProvider));
});
