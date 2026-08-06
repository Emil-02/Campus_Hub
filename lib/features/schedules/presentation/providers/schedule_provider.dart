import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'schedule_controller.dart';
import 'schedule_state.dart';

export 'schedule_dependencies.dart';

/// Provides the schedule controller and its current state.
final scheduleControllerProvider =
    NotifierProvider<ScheduleController, ScheduleState>(ScheduleController.new);
