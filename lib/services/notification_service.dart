import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Schedules and cancels local notifications (T-044).
class NotificationService {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  static const _scheduleChannel = AndroidNotificationDetails(
    'campusmate_schedule',
    'Reminder Jadwal',
    channelDescription: 'Pengingat sebelum kuliah dimulai',
    importance: Importance.high,
    priority: Priority.high,
  );

  /// Initializes timezone data, the plugin, and Android permissions.
  Future<bool> initialize() async {
    if (_initialized) {
      return true;
    }
    try {
      tz_data.initializeTimeZones();

      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      );
      await _plugin.initialize(settings: settings);

      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await android?.requestNotificationsPermission();

      _initialized = true;
      return true;
    } catch (error) {
      debugPrint('Notification initialization failed: $error');
      return false;
    }
  }

  /// Schedules a weekly recurring reminder before a class starts.
  ///
  /// [dayOfWeek] uses 1 = Monday ... 7 = Sunday. [startTime] is `HH:mm`.
  Future<void> scheduleWeeklyClassReminder({
    required String scheduleId,
    required int dayOfWeek,
    required String startTime,
    required String courseName,
    String? room,
    int minutesBefore = 30,
  }) async {
    if (!await initialize()) {
      return;
    }
    try {
      final parts = startTime.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      // Device-local wall clock math, converted to an absolute instant, so
      // reminders stay correct even though tz.local defaults to UTC.
      final classStart = _nextInstanceOfWeekday(dayOfWeek, hour, minute);
      var reminderAt = classStart.subtract(Duration(minutes: minutesBefore));
      if (reminderAt.isBefore(DateTime.now())) {
        reminderAt = reminderAt.add(const Duration(days: 7));
      }

      final roomInfo = room == null || room.trim().isEmpty
          ? ''
          : ' di ruang ${room.trim()}';
      await _plugin.zonedSchedule(
        id: notificationIdForSchedule(scheduleId),
        title: 'Kuliah $courseName akan segera dimulai!',
        body: 'Mulai pukul $startTime$roomInfo. Jangan terlambat!',
        scheduledDate: tz.TZDateTime.from(reminderAt, tz.local),
        notificationDetails: const NotificationDetails(
          android: _scheduleChannel,
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    } catch (error) {
      debugPrint('Failed to schedule class reminder: $error');
    }
  }

  /// Cancels the reminder that belongs to [scheduleId].
  Future<void> cancelScheduleReminder(String scheduleId) async {
    if (!await initialize()) {
      return;
    }
    try {
      await _plugin.cancel(id: notificationIdForSchedule(scheduleId));
    } catch (error) {
      debugPrint('Failed to cancel class reminder: $error');
    }
  }

  /// Stable, reproducible 31-bit id so reminders can be cancelled later.
  @visibleForTesting
  static int notificationIdForSchedule(String scheduleId) {
    return 0x40000000 | (scheduleId.hashCode & 0x3FFFFFFF);
  }

  DateTime _nextInstanceOfWeekday(int dayOfWeek, int hour, int minute) {
    final now = DateTime.now();
    var scheduled = DateTime(now.year, now.month, now.day, hour, minute);
    while (scheduled.weekday != dayOfWeek || scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
