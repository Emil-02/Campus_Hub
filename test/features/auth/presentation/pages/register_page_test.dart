import 'dart:async';

import 'package:campusmate/core/router/route_paths.dart';
import 'package:campusmate/features/auth/domain/entities/user_entity.dart';
import 'package:campusmate/features/auth/domain/repositories/auth_repository.dart';
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
    fullName: 'Campus Student',
    emailVerified: false,
  );

  setUp(() {
    repository = MockAuthRepository();
  });

  Widget subject() {
    final router = GoRouter(
      initialLocation: RoutePaths.register,
      routes: [
        GoRoute(path: RoutePaths.login, builder: (_, _) => const LoginPage()),
        GoRoute(
          path: RoutePaths.register,
          builder: (_, _) => const RegisterPage(),
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

  Future<void> enterValidForm(WidgetTester tester) async {
    await tester.enterText(
      find.byKey(const ValueKey('register-full-name')),
      '  Campus Student  ',
    );
    await tester.enterText(
      find.byKey(const ValueKey('register-email')),
      '  student@campusmate.dev  ',
    );
    await tester.enterText(
      find.byKey(const ValueKey('register-password')),
      'password123',
    );
    await tester.enterText(
      find.byKey(const ValueKey('register-confirm-password')),
      'password123',
    );
  }

  testWidgets('shows all required registration fields', (tester) async {
    await pumpSubject(tester);

    expect(find.byKey(const ValueKey('register-full-name')), findsOneWidget);
    expect(find.byKey(const ValueKey('register-email')), findsOneWidget);
    expect(find.byKey(const ValueKey('register-password')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('register-confirm-password')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('register-submit')), findsOneWidget);
    expect(find.text('Kembali ke Login'), findsOneWidget);
  });

  testWidgets('rejects a whitespace-only full name', (tester) async {
    await pumpSubject(tester);
    await enterValidForm(tester);
    await tester.enterText(
      find.byKey(const ValueKey('register-full-name')),
      '   ',
    );

    await tester.tap(find.byKey(const ValueKey('register-submit')));
    await tester.pump();

    expect(find.text('Nama lengkap wajib diisi.'), findsOneWidget);
  });

  testWidgets('rejects an invalid email', (tester) async {
    await pumpSubject(tester);
    await enterValidForm(tester);
    await tester.enterText(
      find.byKey(const ValueKey('register-email')),
      'invalid',
    );

    await tester.tap(find.byKey(const ValueKey('register-submit')));
    await tester.pump();

    expect(find.text('Format email tidak valid.'), findsOneWidget);
  });

  testWidgets('rejects a short password', (tester) async {
    await pumpSubject(tester);
    await enterValidForm(tester);
    await tester.enterText(
      find.byKey(const ValueKey('register-password')),
      'short',
    );
    await tester.enterText(
      find.byKey(const ValueKey('register-confirm-password')),
      'short',
    );

    await tester.tap(find.byKey(const ValueKey('register-submit')));
    await tester.pump();

    expect(find.text('Password minimal 8 karakter.'), findsOneWidget);
  });

  testWidgets('rejects a mismatched password confirmation', (tester) async {
    await pumpSubject(tester);
    await enterValidForm(tester);
    await tester.enterText(
      find.byKey(const ValueKey('register-confirm-password')),
      'different123',
    );

    await tester.tap(find.byKey(const ValueKey('register-submit')));
    await tester.pump();

    expect(find.text('Konfirmasi password tidak sama.'), findsOneWidget);
  });

  testWidgets('valid form signs up with trimmed values', (tester) async {
    when(
      () => repository.signUp(
        email: 'student@campusmate.dev',
        password: 'password123',
        fullName: 'Campus Student',
      ),
    ).thenAnswer((_) async => user);
    await pumpSubject(tester);
    await enterValidForm(tester);

    await tester.tap(find.byKey(const ValueKey('register-submit')));
    await tester.pump();

    verify(
      () => repository.signUp(
        email: 'student@campusmate.dev',
        password: 'password123',
        fullName: 'Campus Student',
      ),
    ).called(1);
  });

  testWidgets('loading disables the registration button', (tester) async {
    final completer = Completer<UserEntity>();
    when(
      () => repository.signUp(
        email: 'student@campusmate.dev',
        password: 'password123',
        fullName: 'Campus Student',
      ),
    ).thenAnswer((_) => completer.future);
    await pumpSubject(tester);
    await enterValidForm(tester);

    await tester.tap(find.byKey(const ValueKey('register-submit')));
    await tester.pump();

    final button = tester.widget<ElevatedButton>(
      find.byKey(const ValueKey('register-submit')),
    );
    expect(button.onPressed, isNull);

    completer.complete(user);
    await tester.pump();
  });

  testWidgets('shows a safe sign-up error', (tester) async {
    when(
      () => repository.signUp(
        email: 'student@campusmate.dev',
        password: 'password123',
        fullName: 'Campus Student',
      ),
    ).thenThrow(StateError('private-error'));
    await pumpSubject(tester);
    await enterValidForm(tester);

    await tester.tap(find.byKey(const ValueKey('register-submit')));
    await tester.pump();

    expect(
      find.text('Proses autentikasi tidak dapat diselesaikan.'),
      findsOneWidget,
    );
    expect(find.textContaining('private-error'), findsNothing);
  });

  testWidgets('login link opens the login page', (tester) async {
    await pumpSubject(tester);

    await tester.tap(find.text('Kembali ke Login'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('both password fields can toggle visibility', (tester) async {
    await pumpSubject(tester);

    TextField passwordField(String key) => tester.widget<TextField>(
      find.descendant(
        of: find.byKey(ValueKey(key)),
        matching: find.byType(TextField),
      ),
    );

    expect(passwordField('register-password').obscureText, isTrue);
    expect(passwordField('register-confirm-password').obscureText, isTrue);
    await tester.tap(find.byTooltip('Tampilkan password'));
    await tester.tap(find.byTooltip('Tampilkan konfirmasi password'));
    await tester.pump();
    expect(passwordField('register-password').obscureText, isFalse);
    expect(passwordField('register-confirm-password').obscureText, isFalse);
  });
}
