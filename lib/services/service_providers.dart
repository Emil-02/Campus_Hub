import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'notification_service.dart';

/// Provides the app-wide local notification service.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
