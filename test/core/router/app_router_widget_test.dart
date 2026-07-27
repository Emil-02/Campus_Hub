import 'dart:async';

import 'package:campusmate/core/router/app_router.dart';
import 'package:campusmate/core/router/route_paths.dart';
import 'package:campusmate/features/auth/domain/entities/user_entity.dart';
import 'package:campusmate/features/auth/domain/repositories/auth_repository.dart';
import 'package:campusmate/features/auth/presentation/pages/authenticated_home_page.dart';
import 'package:campusmate/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:campusmate/features/auth/presentation/pages/login_page.dart';
import 'package:campusmate/features/auth/presentation/pages/register_page.dart';
import 'package:campusmate/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  Future<({ProviderContainer container, GoRouterHarness harness})> harnessFor(
    WidgetTester tester, {
    required UserEntity? currentUser,
  }) async {
    final repository = MockAuthRepository();
    final authStream = StreamController<UserEntity?>.broadcast();
    when(
      () => repository.getCurrentUser(),
    ).thenAnswer((_) async => currentUser);
    when(
      () => repository.watchAuthState(),
    ).thenAnswer((_) => authStream.stream);

    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(() async {
      container.dispose();
      await authStream.close();
    });
    await container.read(authControllerProvider.notifier).initialize();
    final router = container.read(appRouterProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    return (container: container, harness: GoRouterHarness(router.go));
  }

  testWidgets('/login renders the real LoginPage', (tester) async {
    final result = await harnessFor(tester, currentUser: null);

    result.harness.go(RoutePaths.login);
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('/register renders the real RegisterPage', (tester) async {
    final result = await harnessFor(tester, currentUser: null);

    result.harness.go(RoutePaths.register);
    await tester.pumpAndSettle();

    expect(find.byType(RegisterPage), findsOneWidget);
  });

  testWidgets('/forgot-password renders the real ForgotPasswordPage', (
    tester,
  ) async {
    final result = await harnessFor(tester, currentUser: null);

    result.harness.go(RoutePaths.forgotPassword);
    await tester.pumpAndSettle();

    expect(find.byType(ForgotPasswordPage), findsOneWidget);
  });

  testWidgets('authenticated user cannot return to login', (tester) async {
    const user = UserEntity(
      id: 'user-1',
      email: 'student@campusmate.dev',
      emailVerified: true,
    );
    final result = await harnessFor(tester, currentUser: user);

    result.harness.go(RoutePaths.login);
    await tester.pumpAndSettle();

    expect(find.byType(AuthenticatedHomePage), findsOneWidget);
    expect(find.byType(LoginPage), findsNothing);
  });
}

final class GoRouterHarness {
  const GoRouterHarness(this.go);

  final void Function(String location) go;
}
