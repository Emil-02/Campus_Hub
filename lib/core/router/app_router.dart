import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/auth_bootstrap_page.dart';
import '../../features/auth/presentation/pages/auth_placeholder_page.dart';
import '../../features/auth/presentation/pages/authenticated_home_page.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/providers/auth_state.dart';
import 'route_paths.dart';

/// Notifies GoRouter when the Riverpod authentication state changes.
final class RouterRefreshNotifier extends ChangeNotifier {
  RouterRefreshNotifier(Ref ref) {
    ref.listen<AuthState>(authControllerProvider, (_, _) {
      if (!_disposed) {
        notifyListeners();
      }
    });
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// Provides the stable refresh object used by the application router.
final routerRefreshProvider = Provider<RouterRefreshNotifier>((ref) {
  final notifier = RouterRefreshNotifier(ref);
  ref.onDispose(notifier.dispose);
  return notifier;
});

/// Provides the application GoRouter instance.
final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: RoutePaths.root,
    refreshListenable: ref.watch(routerRefreshProvider),
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      return redirectForAuthState(authState, state.uri.path);
    },
    routes: [
      GoRoute(
        path: RoutePaths.root,
        builder: (context, state) => const AuthBootstrapPage(),
      ),
      GoRoute(
        path: RoutePaths.login,
        builder: (context, state) => const AuthPlaceholderPage(title: 'Login'),
      ),
      GoRoute(
        path: RoutePaths.register,
        builder: (context, state) =>
            const AuthPlaceholderPage(title: 'Register'),
      ),
      GoRoute(
        path: RoutePaths.forgotPassword,
        builder: (context, state) =>
            const AuthPlaceholderPage(title: 'Lupa Password'),
      ),
      GoRoute(
        path: RoutePaths.home,
        builder: (context, state) => const AuthenticatedHomePage(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

/// Returns the redirect target for an authentication state and current path.
String? redirectForAuthState(AuthState authState, String location) {
  final isRoot = location == RoutePaths.root;
  final hasUser = authState.user != null;
  final isPublicAuthRoute = <String>{
    RoutePaths.login,
    RoutePaths.register,
    RoutePaths.forgotPassword,
  }.contains(location);

  switch (authState.status) {
    case AuthStatus.initial:
      return isRoot ? null : RoutePaths.root;
    case AuthStatus.loading:
      if (hasUser) {
        return isRoot || isPublicAuthRoute ? RoutePaths.home : null;
      }
      return isRoot ? null : RoutePaths.root;
    case AuthStatus.unauthenticated:
      if (isRoot) {
        return RoutePaths.login;
      }
      if (location == RoutePaths.home) {
        return RoutePaths.login;
      }
      return isPublicAuthRoute ? null : RoutePaths.login;
    case AuthStatus.authenticated:
      if (isRoot || isPublicAuthRoute) {
        return RoutePaths.home;
      }
      return null;
    case AuthStatus.failure:
      if (hasUser) {
        return isRoot || isPublicAuthRoute ? RoutePaths.home : null;
      }
      return location == RoutePaths.home ? RoutePaths.login : null;
  }
}
