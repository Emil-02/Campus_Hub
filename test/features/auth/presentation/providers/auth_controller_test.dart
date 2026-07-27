import 'dart:async';

import 'package:campusmate/features/auth/domain/entities/user_entity.dart';
import 'package:campusmate/features/auth/domain/repositories/auth_repository.dart';
import 'package:campusmate/features/auth/presentation/providers/auth_controller.dart';
import 'package:campusmate/features/auth/presentation/providers/auth_provider.dart';
import 'package:campusmate/features/auth/presentation/providers/auth_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;
  late ProviderContainer container;
  late AuthController controller;
  late StreamController<UserEntity?> authStateController;

  setUp(() {
    repository = MockAuthRepository();
    authStateController = StreamController<UserEntity?>.broadcast();
    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    controller = container.read(authControllerProvider.notifier);
    when(
      () => repository.watchAuthState(),
    ).thenAnswer((_) => authStateController.stream);
  });

  tearDown(() async {
    container.dispose();
    await authStateController.close();
  });

  test('initialize becomes authenticated when a current user exists', () async {
    final user = _user();
    when(() => repository.getCurrentUser()).thenAnswer((_) async => user);

    await controller.initialize();

    expect(
      container.read(authControllerProvider),
      AuthState.authenticated(user),
    );
  });

  test('initialize becomes unauthenticated without a current user', () async {
    when(() => repository.getCurrentUser()).thenAnswer((_) async => null);

    await controller.initialize();

    expect(
      container.read(authControllerProvider),
      const AuthState.unauthenticated(),
    );
  });

  test('initialize reacts to login and logout stream events', () async {
    when(() => repository.getCurrentUser()).thenAnswer((_) async => null);
    await controller.initialize();

    final user = _user();
    authStateController.add(user);
    await Future<void>.delayed(Duration.zero);
    expect(
      container.read(authControllerProvider),
      AuthState.authenticated(user),
    );

    authStateController.add(null);
    await Future<void>.delayed(Duration.zero);
    expect(
      container.read(authControllerProvider),
      const AuthState.unauthenticated(),
    );
  });

  test('initialize creates only one auth-state listener', () async {
    when(() => repository.getCurrentUser()).thenAnswer((_) async => null);

    await Future.wait(<Future<void>>[
      controller.initialize(),
      controller.initialize(),
    ]);

    verify(() => repository.getCurrentUser()).called(1);
    verify(() => repository.watchAuthState()).called(1);
  });

  test(
    'disposing the controller cancels the auth-state subscription',
    () async {
      var cancelled = false;
      await authStateController.close();
      authStateController = StreamController<UserEntity?>.broadcast(
        onCancel: () {
          cancelled = true;
        },
      );
      when(() => repository.getCurrentUser()).thenAnswer((_) async => null);
      when(
        () => repository.watchAuthState(),
      ).thenAnswer((_) => authStateController.stream);
      await controller.initialize();

      container.dispose();
      await Future<void>.delayed(Duration.zero);

      expect(cancelled, isTrue);
    },
  );

  test('signUp transitions from loading to authenticated', () async {
    final user = _user();
    when(
      () => repository.signUp(
        email: 'student@campusmate.dev',
        password: 'password',
        fullName: 'Campus Mate',
      ),
    ).thenAnswer((_) async => user);
    final recorder = recordStates(container);

    await controller.signUp(
      email: 'student@campusmate.dev',
      password: 'password',
      fullName: 'Campus Mate',
    );

    expect(recorder.states.map((state) => state.status), [
      AuthStatus.loading,
      AuthStatus.authenticated,
    ]);
  });

  test('signUp failure becomes a safe failure state', () async {
    when(
      () => repository.signUp(
        email: any(named: 'email'),
        password: any(named: 'password'),
        fullName: any(named: 'fullName'),
      ),
    ).thenThrow(const FormatException('secret-token=should-not-leak'));

    await controller.signUp(
      email: 'student@campusmate.dev',
      password: 'password',
      fullName: 'Campus Mate',
    );

    final state = container.read(authControllerProvider);
    expect(state.status, AuthStatus.failure);
    expect(state.errorMessage, 'Data akun tidak valid.');
    expect(state.errorMessage, isNot(contains('secret-token')));
  });

  test('signInWithEmail transitions from loading to authenticated', () async {
    final user = _user();
    when(
      () => repository.signInWithEmail(
        email: 'student@campusmate.dev',
        password: 'password',
      ),
    ).thenAnswer((_) async => user);
    final recorder = recordStates(container);

    await controller.signInWithEmail(
      email: 'student@campusmate.dev',
      password: 'password',
    );

    expect(recorder.states.map((state) => state.status), [
      AuthStatus.loading,
      AuthStatus.authenticated,
    ]);
  });

  test('signInWithGoogle transitions from loading to authenticated', () async {
    final user = _user();
    when(() => repository.signInWithGoogle()).thenAnswer((_) async => user);
    final recorder = recordStates(container);

    await controller.signInWithGoogle();

    expect(recorder.states.map((state) => state.status), [
      AuthStatus.loading,
      AuthStatus.authenticated,
    ]);
  });

  test('signInWithGoogle timeout becomes a safe failure', () async {
    when(
      () => repository.signInWithGoogle(),
    ).thenThrow(TimeoutException('secret-token=should-not-leak'));

    await controller.signInWithGoogle();

    final state = container.read(authControllerProvider);
    expect(state.status, AuthStatus.failure);
    expect(state.errorMessage, 'Proses autentikasi habis waktu.');
    expect(state.errorMessage, isNot(contains('secret-token')));
  });

  test('signOut transitions from loading to unauthenticated', () async {
    when(() => repository.signOut()).thenAnswer((_) async {});
    final recorder = recordStates(container);

    await controller.signOut();

    expect(recorder.states.map((state) => state.status), [
      AuthStatus.loading,
      AuthStatus.unauthenticated,
    ]);
  });

  test(
    'resetPassword preserves the authenticated user after success',
    () async {
      final user = _user();
      when(() => repository.getCurrentUser()).thenAnswer((_) async => user);
      await controller.initialize();
      when(
        () => repository.resetPassword(email: 'student@campusmate.dev'),
      ).thenAnswer((_) async {});

      await controller.resetPassword(email: 'student@campusmate.dev');

      expect(
        container.read(authControllerProvider),
        AuthState.authenticated(user),
      );
    },
  );

  test(
    'resendVerificationEmail preserves the authenticated user after success',
    () async {
      final user = _user();
      when(() => repository.getCurrentUser()).thenAnswer((_) async => user);
      await controller.initialize();
      when(() => repository.resendVerificationEmail()).thenAnswer((_) async {});

      await controller.resendVerificationEmail();

      expect(
        container.read(authControllerProvider),
        AuthState.authenticated(user),
      );
    },
  );
}

UserEntity _user() {
  return const UserEntity(
    id: 'user-id',
    email: 'student@campusmate.dev',
    fullName: 'Campus Mate',
    emailVerified: true,
  );
}

final class StateRecorder {
  const StateRecorder(this.states);

  final List<AuthState> states;
}

StateRecorder recordStates(ProviderContainer container) {
  final states = <AuthState>[];
  final subscription = container.listen<AuthState>(
    authControllerProvider,
    (_, next) => states.add(next),
  );
  addTearDown(subscription.close);
  return StateRecorder(states);
}
