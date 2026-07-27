import 'dart:async';

import 'package:campusmate/core/router/route_paths.dart';
import 'package:campusmate/features/auth/domain/repositories/auth_repository.dart';
import 'package:campusmate/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:campusmate/features/auth/presentation/pages/login_page.dart';
import 'package:campusmate/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;

  setUp(() {
    repository = MockAuthRepository();
  });

  Widget subject() {
    final router = GoRouter(
      initialLocation: RoutePaths.forgotPassword,
      routes: [
        GoRoute(path: RoutePaths.login, builder: (_, _) => const LoginPage()),
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

  Future<void> enterValidEmail(WidgetTester tester) async {
    await tester.enterText(
      find.byKey(const ValueKey('forgot-email')),
      '  student@campusmate.dev  ',
    );
  }

  testWidgets('rejects an empty and invalid email', (tester) async {
    await pumpSubject(tester);

    await tester.tap(find.byKey(const ValueKey('forgot-submit')));
    await tester.pump();
    expect(find.text('Email wajib diisi.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('forgot-email')),
      'invalid',
    );
    await tester.tap(find.byKey(const ValueKey('forgot-submit')));
    await tester.pump();
    expect(find.text('Format email tidak valid.'), findsOneWidget);
  });

  testWidgets('valid email requests reset with a trimmed value', (
    tester,
  ) async {
    when(
      () => repository.resetPassword(email: 'student@campusmate.dev'),
    ).thenAnswer((_) async {});
    await pumpSubject(tester);
    await enterValidEmail(tester);

    await tester.tap(find.byKey(const ValueKey('forgot-submit')));
    await tester.pump();

    verify(
      () => repository.resetPassword(email: 'student@campusmate.dev'),
    ).called(1);
  });

  testWidgets('loading disables the reset button', (tester) async {
    final completer = Completer<void>();
    when(
      () => repository.resetPassword(email: 'student@campusmate.dev'),
    ).thenAnswer((_) => completer.future);
    await pumpSubject(tester);
    await enterValidEmail(tester);

    await tester.tap(find.byKey(const ValueKey('forgot-submit')));
    await tester.pump();

    final button = tester.widget<ElevatedButton>(
      find.byKey(const ValueKey('forgot-submit')),
    );
    expect(button.onPressed, isNull);

    completer.complete();
    await tester.pump();
  });

  testWidgets('failure shows safe error without success feedback', (
    tester,
  ) async {
    when(
      () => repository.resetPassword(email: 'student@campusmate.dev'),
    ).thenThrow(StateError('private-reset-detail'));
    await pumpSubject(tester);
    await enterValidEmail(tester);

    await tester.tap(find.byKey(const ValueKey('forgot-submit')));
    await tester.pump();

    expect(
      find.text('Proses autentikasi tidak dapat diselesaikan.'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('forgot-success')), findsNothing);
    expect(find.textContaining('private-reset-detail'), findsNothing);
  });

  testWidgets('success shows local feedback', (tester) async {
    when(
      () => repository.resetPassword(email: 'student@campusmate.dev'),
    ).thenAnswer((_) async {});
    await pumpSubject(tester);
    await enterValidEmail(tester);

    await tester.tap(find.byKey(const ValueKey('forgot-submit')));
    await tester.pump();

    expect(find.byKey(const ValueKey('forgot-success')), findsOneWidget);
    expect(
      find.text('Tautan reset password telah dikirim. Periksa email Anda.'),
      findsOneWidget,
    );
  });

  testWidgets('editing email clears prior success feedback', (tester) async {
    when(
      () => repository.resetPassword(email: 'student@campusmate.dev'),
    ).thenAnswer((_) async {});
    await pumpSubject(tester);
    await enterValidEmail(tester);
    await tester.tap(find.byKey(const ValueKey('forgot-submit')));
    await tester.pump();
    expect(find.byKey(const ValueKey('forgot-success')), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('forgot-email')),
      'changed@campusmate.dev',
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('forgot-success')), findsNothing);
  });

  testWidgets('login link opens the login page', (tester) async {
    await pumpSubject(tester);

    await tester.tap(find.text('Kembali ke Login'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
  });
}
