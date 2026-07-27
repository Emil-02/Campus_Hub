import 'package:campusmate/core/router/app_router.dart';
import 'package:campusmate/core/router/route_paths.dart';
import 'package:campusmate/features/auth/domain/entities/user_entity.dart';
import 'package:campusmate/features/auth/presentation/providers/auth_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const user = UserEntity(
    id: 'user-1',
    email: 'student@campusmate.dev',
    emailVerified: true,
  );

  test('unauthenticated users are redirected away from protected routes', () {
    expect(
      redirectForAuthState(const AuthState.unauthenticated(), RoutePaths.home),
      RoutePaths.login,
    );
    expect(
      redirectForAuthState(const AuthState.unauthenticated(), RoutePaths.login),
      isNull,
    );
  });

  test('authenticated users are redirected to home from public routes', () {
    const state = AuthState.authenticated(user);
    expect(redirectForAuthState(state, RoutePaths.root), RoutePaths.home);
    expect(redirectForAuthState(state, RoutePaths.login), RoutePaths.home);
    expect(redirectForAuthState(state, RoutePaths.home), isNull);
  });

  test('initial and loading states without a user use bootstrap', () {
    for (final state in [
      const AuthState.initial(),
      const AuthState.loading(),
    ]) {
      expect(redirectForAuthState(state, RoutePaths.root), isNull);
      expect(redirectForAuthState(state, RoutePaths.home), RoutePaths.root);
    }
  });

  test('loading with an active user stays in the authenticated area', () {
    const state = AuthState.loading(user: user);

    expect(redirectForAuthState(state, RoutePaths.home), isNull);
    expect(redirectForAuthState(state, RoutePaths.root), RoutePaths.home);
    expect(redirectForAuthState(state, RoutePaths.login), RoutePaths.home);
  });

  test('failure state does not create a redirect loop', () {
    const state = AuthState.failure('bootstrap failed');
    expect(redirectForAuthState(state, RoutePaths.root), isNull);
    expect(redirectForAuthState(state, RoutePaths.login), isNull);
    expect(redirectForAuthState(state, RoutePaths.home), RoutePaths.login);
  });

  test('failure with an active user stays in the authenticated area', () {
    const state = AuthState.failure('operation failed', user: user);

    expect(redirectForAuthState(state, RoutePaths.home), isNull);
    expect(redirectForAuthState(state, RoutePaths.root), RoutePaths.home);
    expect(redirectForAuthState(state, RoutePaths.login), RoutePaths.home);
  });
}
