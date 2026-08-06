import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'profile_controller.dart';
import 'profile_state.dart';

export 'profile_dependencies.dart';

/// Provides the profile controller and its current state.
final profileControllerProvider =
    NotifierProvider<ProfileController, ProfileState>(ProfileController.new);
