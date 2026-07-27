import 'dart:async';

import 'package:campusmate/core/router/route_paths.dart';
import 'package:campusmate/features/auth/domain/entities/user_entity.dart';
import 'package:campusmate/features/auth/domain/repositories/auth_repository.dart';
import 'package:campusmate/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:campusmate/features/auth/presentation/pages/login_page.dart';
import 'package:campusmate/features/auth/presentation/pages/register_page.dart';
import 'package:campusmate/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;

  const user = UserEntity(
    id: 'user-1',
    email: 'student@campusmate.dev',
    emailVerified: true,
  );

  setUp(() {
    repository = MockAuthRepository();
  });

  Widget subject() {
    final router = GoRouter(
      initialLocation: RoutePaths.login,
      routes: [
        GoRoute(path: RoutePaths.login, builder: (_, _) => const LoginPage()),
        GoRoute(
          path: RoutePaths.register,
          builder: (_, _) => const RegisterPage(),
        ),
        GoRoute(
          path: RoutePaths.forgotPassword,
          builder: (_, _) => const ForgotPasswordPage(),
        ),
      ],
    );
    return ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  Future<void> pumpSubject(WidgetTester tester) async {
    await tester.pumpWidget(subject());
    await tester.pump();
  }

  Future<void> enterValidCredentials(WidgetTester tester) async {
    await tester.enterText(
      find.byKey(const ValueKey('login-email')),
      '  student@campusmate.dev  ',
    );
    await tester.enterText(
      find.byKey(const ValueKey('login-password')),
      'password123',
    );
  }

  testWidgets('shows all login controls', (tester) async {
    await pumpSubject(tester);

    expect(find.text('CampusMate'), findsOneWidget);
    expect(find.byKey(const ValueKey('login-email')), findsOneWidget);
    expect(find.byKey(const ValueKey('login-password')), findsOneWidget);
    expect(find.text('Masuk'), findsWidgets);
    expect(find.text('Masuk dengan Google'), findsOneWidget);
    expect(find.text('Daftar'), findsOneWidget);
    expect(find.text('Lupa Password'), findsOneWidget);
  });

  testWidgets('rejects an empty email', (tester) async {
    await pumpSubject(tester);
    await tester.enterText(
      find.byKey(const ValueKey('login-password')),
      'password123',
    );

    await tester.tap(find.byKey(const ValueKey('login-submit')));
    await tester.pump();

    expect(find.text('Email wajib diisi.'), findsOneWidget);
  });

  testWidgets('rejects an invalid email', (tester) async {
    await pumpSubject(tester);
    await tester.enterText(
      find.byKey(const ValueKey('login-email')),
      'invalid-email',
    );
    await tester.enterText(
      find.byKey(const ValueKey('login-password')),
      'password123',
    );

    await tester.tap(find.byKey(const ValueKey('login-submit')));
    await tester.pump();

    expect(find.text('Format email tidak valid.'), findsOneWidget);
  });

  testWidgets('rejects an empty password', (tester) async {
    await pumpSubject(tester);
    await tester.enterText(
      find.byKey(const ValueKey('login-email')),
      'student@campusmate.dev',
    );

    await tester.tap(find.byKey(const ValueKey('login-submit')));
    await tester.pump();

    expect(find.text('Password wajib diisi.'), findsOneWidget);
  });

  testWidgets('rejects a password shorter than eight characters', (
    tester,
  ) async {
    await pumpSubject(tester);
    await tester.enterText(
      find.byKey(const ValueKey('login-email')),
      'student@campusmate.dev',
    );
    await tester.enterText(
      find.byKey(const ValueKey('login-password')),
      'short',
    );

    await tester.tap(find.byKey(const ValueKey('login-submit')));
    await tester.pump();

    expect(find.text('Password minimal 8 karakter.'), findsOneWidget);
  });

  testWidgets('valid form signs in with trimmed email', (tester) async {
    when(
      () => repository.signInWithEmail(
        email: 'student@campusmate.dev',
        password: 'password123',
      ),
    ).thenAnswer((_) async => user);
    await pumpSubject(tester);
    await enterValidCredentials(tester);

    await tester.tap(find.byKey(const ValueKey('login-submit')));
    await tester.pump();

    verify(
      () => repository.signInWithEmail(
        email: 'student@campusmate.dev',
        password: 'password123',
      ),
    ).called(1);
  });

  testWidgets('loading disables email and Google sign-in buttons', (
    tester,
  ) async {
    final completer = Completer<UserEntity>();
    when(
      () => repository.signInWithEmail(
        email: 'student@campusmate.dev',
        password: 'password123',
      ),
    ).thenAnswer((_) => completer.future);
    await pumpSubject(tester);
    await enterValidCredentials(tester);

    await tester.tap(find.byKey(const ValueKey('login-submit')));
    await tester.pump();

    final submit = tester.widget<ElevatedButton>(
      find.byKey(const ValueKey('login-submit')),
    );
    final google = tester.widget<OutlinedButton>(
      find.byKey(const ValueKey('login-google')),
    );
    expect(submit.onPressed, isNull);
    expect(google.onPressed, isNull);

    completer.complete(user);
    await tester.pump();
  });

  testWidgets('shows a safe authentication error', (tester) async {
    when(
      () => repository.signInWithEmail(
        email: 'student@campusmate.dev',
        password: 'password123',
      ),
    ).thenThrow(StateError('private-session-detail'));
    await pumpSubject(tester);
    await enterValidCredentials(tester);

    await tester.tap(find.byKey(const ValueKey('login-submit')));
    await tester.pump();

    expect(
      find.text('Proses autentikasi tidak dapat diselesaikan.'),
      findsOneWidget,
    );
    expect(find.textContaining('private-session-detail'), findsNothing);
  });

  testWidgets('Google button delegates to signInWithGoogle', (tester) async {
    when(() => repository.signInWithGoogle()).thenAnswer((_) async => user);
    await pumpSubject(tester);

    await tester.tap(find.byKey(const ValueKey('login-google')));
    await tester.pump();

    verify(() => repository.signInWithGoogle()).called(1);
  });

  testWidgets('register link opens the register page', (tester) async {
    await pumpSubject(tester);

    await tester.tap(find.text('Daftar'));
    await tester.pumpAndSettle();

    expect(find.byType(RegisterPage), findsOneWidget);
  });

  testWidgets('forgot password link opens its page', (tester) async {
    await pumpSubject(tester);

    await tester.tap(find.text('Lupa Password'));
    await tester.pumpAndSettle();

    expect(find.byType(ForgotPasswordPage), findsOneWidget);
  });

  testWidgets('password visibility can be toggled', (tester) async {
    await pumpSubject(tester);
    TextField passwordField() => tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const ValueKey('login-password')),
        matching: find.byType(TextField),
      ),
    );

    expect(passwordField().obscureText, isTrue);
    await tester.tap(find.byTooltip('Tampilkan password'));
    await tester.pump();
    expect(passwordField().obscureText, isFalse);
  });
}
