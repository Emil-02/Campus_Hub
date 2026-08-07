import 'package:campusmate/features/dashboard/data/models/dashboard_stats_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromJson parses the RPC payload', () {
    final model = DashboardStatsModel.fromJson(const {
      'total_active': 4,
      'completed_total': 6,
      'completed_this_week': 2,
      'overdue': 1,
    });

    expect(model.totalActive, 4);
    expect(model.completedTotal, 6);
    expect(model.completedThisWeek, 2);
    expect(model.overdue, 1);
  });

  test('missing fields default to zero', () {
    final model = DashboardStatsModel.fromJson(const {});

    expect(model.totalActive, 0);
    expect(model.completedTotal, 0);
    expect(model.completedThisWeek, 0);
    expect(model.overdue, 0);
  });

  test('completionRate divides completed by total', () {
    final model = DashboardStatsModel.fromJson(const {
      'total_active': 1,
      'completed_total': 3,
    });

    expect(model.totalTasks, 4);
    expect(model.completionRate, 0.75);
  });

  test('completionRate is zero without tasks', () {
    const model = DashboardStatsModel();

    expect(model.completionRate, 0);
  });
}
