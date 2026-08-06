import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'task_controller.dart';
import 'task_state.dart';

export 'task_dependencies.dart';

/// Provides the task controller and its current state.
final taskControllerProvider = NotifierProvider<TaskController, TaskState>(
  TaskController.new,
);
