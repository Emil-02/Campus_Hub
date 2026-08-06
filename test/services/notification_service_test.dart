import 'package:campusmate/services/notification_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('schedule and task ids never collide across namespaces', () {
    const id = 'same-source-id';
    final scheduleId = NotificationService.notificationIdForSchedule(id);
    final taskH3 = NotificationService.notificationIdForTask(id, daysBefore: 3);
    final taskH1 = NotificationService.notificationIdForTask(id, daysBefore: 1);

    expect({scheduleId, taskH3, taskH1}, hasLength(3));
  });

  test('ids are stable for the same input', () {
    expect(
      NotificationService.notificationIdForTask('task-1', daysBefore: 3),
      NotificationService.notificationIdForTask('task-1', daysBefore: 3),
    );
  });

  test('ids stay within the 32-bit positive range', () {
    for (final id in [
      NotificationService.notificationIdForSchedule('schedule-xyz'),
      NotificationService.notificationIdForTask('task-xyz', daysBefore: 3),
      NotificationService.notificationIdForTask('task-xyz', daysBefore: 1),
    ]) {
      expect(id, greaterThan(0));
      expect(id, lessThanOrEqualTo(0x7FFFFFFF));
    }
  });
}
