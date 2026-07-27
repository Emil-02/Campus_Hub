import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/user_entity.dart';
import 'auth_controller.dart';
import 'auth_state.dart';

export 'auth_dependencies.dart';

/// Provides the authentication controller and its current state.
final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

/// Provides the currently authenticated user, if available.
final authUserProvider = Provider<UserEntity?>((ref) {
  return ref.watch(authControllerProvider).user;
});
