// T-158: integration-style test of the full auth flow
// register → login → authenticated session → logout,
// driven through AuthController against a stateful in-memory repository.
import 'dart:async';

import 'package:campusmate/features/auth/domain/entities/user_entity.dart';
import 'package:campusmate/features/auth/domain/repositories/auth_repository.dart';
import 'package:campusmate/features/auth/presentation/providers/auth_provider.dart';
import 'package:campusmate/features/auth/presentation/providers/auth_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

/// In-memory auth backend that keeps registered accounts and a live session.
final class InMemoryAuthRepository implements AuthRepository {
  final _accounts = <String, ({String password, UserEntity user})>{};
  final _authState = StreamController<UserEntity?>.broadcast();
  UserEntity? _currentUser;

  void dispose() => _authState.close();

  @override
  Future<UserEntity> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    if (_accounts.containsKey(email)) {
      throw const AuthException('User already registered');
    }
    final user = UserEntity(
      id: 'user-${_accounts.length + 1}',
      email: email,
      fullName: fullName,
      emailVerified: true,
    );
    _accounts[email] = (password: password, user: user);
    _currentUser = user;
    _authState.add(user);
    return user;
  }

  @override
  Future<UserEntity> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final account = _accounts[email];
    if (account == null || account.password != password) {
      throw const AuthException(
        'Invalid login credentials',
        code: 'invalid_credentials',
      );
    }
    _currentUser = account.user;
    _authState.add(account.user);
    return account.user;
  }

  @override
  Future<UserEntity> signInWithGoogle() =>
      throw UnimplementedError('not used in this flow');

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _authState.add(null);
  }

  @override
  Future<void> resetPassword({required String email}) async {}

  @override
  Future<void> resendVerificationEmail() async {}

  @override
  Future<UserEntity?> getCurrentUser() async => _currentUser;

  @override
  Stream<UserEntity?> watchAuthState() => _authState.stream;
}

void main() {
  late InMemoryAuthRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = InMemoryAuthRepository();
    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
  });

  tearDown(() {
    container.dispose();
    repository.dispose();
  });

  test('full flow: register → logout → login → logout', () async {
    final controller = container.read(authControllerProvider.notifier);

    // Cold start: no session.
    await controller.initialize();
    expect(
      container.read(authControllerProvider),
      const AuthState.unauthenticated(),
    );

    // Register.
    await controller.signUp(
      email: 'budi@student.unismuh.ac.id',
      password: 'RahasiaKuat123',
      fullName: 'Budi Santoso',
    );
    var state = container.read(authControllerProvider);
    expect(state.status, AuthStatus.authenticated);
    expect(state.user?.email, 'budi@student.unismuh.ac.id');
    expect(state.user?.fullName, 'Budi Santoso');

    // Logout ends the session.
    await controller.signOut();
    expect(
      container.read(authControllerProvider),
      const AuthState.unauthenticated(),
    );
    expect(await repository.getCurrentUser(), isNull);

    // Login again with the registered credentials.
    await controller.signInWithEmail(
      email: 'budi@student.unismuh.ac.id',
      password: 'RahasiaKuat123',
    );
    state = container.read(authControllerProvider);
    expect(state.status, AuthStatus.authenticated);
    expect(state.user?.id, 'user-1');

    // Logout once more.
    await controller.signOut();
    expect(
      container.read(authControllerProvider),
      const AuthState.unauthenticated(),
    );
  });

  test(
    'login with wrong password fails and recovers with correct one',
    () async {
      final controller = container.read(authControllerProvider.notifier);
      await controller.initialize();
      await controller.signUp(
        email: 'siti@student.unismuh.ac.id',
        password: 'BenarSekali99',
        fullName: 'Siti Aminah',
      );
      await controller.signOut();

      await controller.signInWithEmail(
        email: 'siti@student.unismuh.ac.id',
        password: 'salah-total',
      );
      final failed = container.read(authControllerProvider);
      expect(failed.status, AuthStatus.failure);
      expect(failed.errorMessage, contains('Email atau password salah'));

      await controller.signInWithEmail(
        email: 'siti@student.unismuh.ac.id',
        password: 'BenarSekali99',
      );
      expect(
        container.read(authControllerProvider).status,
        AuthStatus.authenticated,
      );
    },
  );

  test(
    'restart after login restores the session (persisted bootstrap)',
    () async {
      final controller = container.read(authControllerProvider.notifier);
      await controller.initialize();
      await controller.signUp(
        email: 'andi@student.unismuh.ac.id',
        password: 'PasswordAman1',
        fullName: 'Andi Wijaya',
      );

      // Simulate app restart: a fresh container reusing the same backend.
      final restarted = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(restarted.dispose);

      await restarted.read(authControllerProvider.notifier).initialize();

      final state = restarted.read(authControllerProvider);
      expect(state.status, AuthStatus.authenticated);
      expect(state.user?.email, 'andi@student.unismuh.ac.id');
    },
  );
}
