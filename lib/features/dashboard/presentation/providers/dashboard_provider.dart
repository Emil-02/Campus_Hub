import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/network/supabase_provider.dart';
import '../../data/datasources/dashboard_remote_data_source.dart';
import '../../data/repositories/dashboard_repository_impl.dart';
import '../../domain/repositories/dashboard_repository.dart';
import 'dashboard_state.dart';

/// Provides the remote dashboard datasource from the existing client.
final dashboardRemoteDataSourceProvider = Provider<DashboardRemoteDataSource>((
  ref,
) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) {
    throw StateError(
      'Supabase is not initialized; dashboard data is unavailable.',
    );
  }
  return DashboardRemoteDataSourceImpl(client);
});

/// Provides the domain dashboard repository implementation.
final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepositoryImpl(ref.watch(dashboardRemoteDataSourceProvider));
});

/// Provides the dashboard controller and its current state.
final dashboardControllerProvider =
    NotifierProvider<DashboardController, DashboardState>(
      DashboardController.new,
    );

/// Loads today's schedule, nearest deadlines, and task stats (DASH-01..04).
final class DashboardController extends Notifier<DashboardState> {
  DashboardRepository get _repository => ref.read(dashboardRepositoryProvider);

  @override
  DashboardState build() => const DashboardState.initial();

  /// Loads all dashboard sections in parallel (also used by pull-to-refresh).
  Future<void> loadDashboard() async {
    if (state.status == DashboardStatus.initial) {
      state = const DashboardState.loading();
    }
    try {
      final schedulesFuture = _repository.getTodaySchedules();
      final tasksFuture = _repository.getUpcomingDeadlines();
      final eventsFuture = _repository.getUpcomingEvents();
      final statsFuture = _repository.getStatistics();
      state = DashboardState.loaded(
        todaySchedules: await schedulesFuture,
        upcomingTasks: await tasksFuture,
        upcomingEvents: await eventsFuture,
        stats: await statsFuture,
      );
    } catch (error) {
      state = DashboardState.failure(
        _safeErrorMessage(error),
        todaySchedules: state.todaySchedules,
        upcomingTasks: state.upcomingTasks,
        upcomingEvents: state.upcomingEvents,
        stats: state.stats,
      );
    }
  }

  String _safeErrorMessage(Object error) {
    debugPrint('Dashboard error: $error');
    if (error is PostgrestException) {
      return 'Gagal memuat data dari server. Coba lagi.';
    }
    if (error is SocketException || error is TimeoutException) {
      return 'Tidak dapat terhubung ke server. Periksa koneksi internet.';
    }
    if (error is StateError) {
      return 'Sesi tidak valid. Silakan login ulang.';
    }
    if (error is FormatException) {
      return 'Data ringkasan tidak valid.';
    }
    return 'Terjadi kesalahan. Coba lagi.';
  }
}
