import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_dependencies.dart';
import 'auth_state.dart';

/// Coordinates authentication operations and exposes their state.
final class AuthController extends Notifier<AuthState> {
  // The subscription is cancelled from ref.onDispose.
  // ignore: cancel_subscriptions
  StreamSubscription<UserEntity?>? _authStateSubscription;
  bool _initialized = false;
  bool _disposed = false;

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  @override
  AuthState build() {
    ref.onDispose(() {
      _disposed = true;
      final subscription = _authStateSubscription;
      if (subscription != null) {
        unawaited(subscription.cancel());
      }
      _authStateSubscription = null;
    });
    return const AuthState.initial();
  }

  /// Checks the current session once and starts listening for auth changes.
  Future<void> initialize() async {
    if (_initialized || _disposed) {
      return;
    }
    _initialized = true;
    state = const AuthState.loading();

    try {
      final user = await _repository.getCurrentUser();
      if (!_disposed) {
        state = _stateForUser(user);
      }
    } catch (error) {
      if (!_disposed) {
        state = AuthState.failure(_safeErrorMessage(error));
      }
    } finally {
      if (!_disposed) {
        _startAuthStateListener();
      }
    }
  }

  /// Registers a user and updates state with the resulting account.
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    state = const AuthState.loading();
    try {
      final user = await _repository.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );
      if (!_disposed) {
        state = AuthState.authenticated(user);
      }
    } catch (error) {
      _setFailure(error);
    }
  }

  /// Signs in with email and password and updates state with the user.
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AuthState.loading();
    try {
      final user = await _repository.signInWithEmail(
        email: email,
        password: password,
      );
      if (!_disposed) {
        state = AuthState.authenticated(user);
      }
    } catch (error) {
      _setFailure(error);
    }
  }

  /// Starts Google sign-in and updates state after authentication completes.
  Future<void> signInWithGoogle() async {
    state = const AuthState.loading();
    try {
      final user = await _repository.signInWithGoogle();
      if (!_disposed) {
        state = AuthState.authenticated(user);
      }
    } catch (error) {
      _setFailure(error);
    }
  }

  /// Signs out and marks the session as unauthenticated.
  Future<void> signOut() async {
    state = const AuthState.loading();
    try {
      await _repository.signOut();
      if (!_disposed) {
        state = const AuthState.unauthenticated();
      }
    } catch (error) {
      _setFailure(error);
    }
  }

  /// Sends password reset instructions without changing the user session.
  Future<void> resetPassword({required String email}) async {
    final previousState = state;
    state = const AuthState.loading();
    try {
      await _repository.resetPassword(email: email);
      if (!_disposed) {
        state = previousState;
      }
    } catch (error) {
      _setFailure(error);
    }
  }

  /// Resends verification instructions without removing the current user.
  Future<void> resendVerificationEmail() async {
    final previousState = state;
    state = const AuthState.loading();
    try {
      await _repository.resendVerificationEmail();
      if (!_disposed) {
        state = previousState;
      }
    } catch (error) {
      _setFailure(error);
    }
  }

  void _startAuthStateListener() {
    if (_authStateSubscription != null || _disposed) {
      return;
    }

    try {
      _authStateSubscription = _repository.watchAuthState().listen(
        (user) {
          if (!_disposed) {
            state = _stateForUser(user);
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          _setFailure(error);
        },
      );
    } catch (error) {
      _setFailure(error);
    }
  }

  AuthState _stateForUser(UserEntity? user) {
    return user == null
        ? const AuthState.unauthenticated()
        : AuthState.authenticated(user);
  }

  void _setFailure(Object error) {
    if (!_disposed) {
      state = AuthState.failure(_safeErrorMessage(error));
    }
  }

  String _safeErrorMessage(Object error) {
    if (error is TimeoutException) {
      return 'Proses autentikasi habis waktu.';
    }
    if (error is FormatException) {
      return 'Data akun tidak valid.';
    }
    if (error is StateError) {
      return 'Proses autentikasi tidak dapat diselesaikan.';
    }
    return 'Terjadi kesalahan autentikasi.';
  }
}
