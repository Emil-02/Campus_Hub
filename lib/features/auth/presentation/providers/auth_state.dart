import 'package:equatable/equatable.dart';

import '../../domain/entities/user_entity.dart';

/// Describes the current authentication state of the application.
enum AuthStatus { initial, loading, authenticated, unauthenticated, failure }

/// Immutable authentication state exposed to presentation consumers.
final class AuthState extends Equatable {
  const AuthState.initial()
    : status = AuthStatus.initial,
      user = null,
      errorMessage = null;

  const AuthState.loading({this.user})
    : status = AuthStatus.loading,
      errorMessage = null;

  const AuthState.authenticated(UserEntity this.user)
    : status = AuthStatus.authenticated,
      errorMessage = null;

  const AuthState.unauthenticated()
    : status = AuthStatus.unauthenticated,
      user = null,
      errorMessage = null;

  const AuthState.failure(this.errorMessage, {this.user})
    : status = AuthStatus.failure;

  final AuthStatus status;
  final UserEntity? user;
  final String? errorMessage;

  @override
  List<Object?> get props => [status, user, errorMessage];
}
