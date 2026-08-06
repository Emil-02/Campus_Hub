import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'course_controller.dart';
import 'course_state.dart';

export 'course_dependencies.dart';

/// Provides the course controller and its current state.
final courseControllerProvider =
    NotifierProvider<CourseController, CourseState>(CourseController.new);
