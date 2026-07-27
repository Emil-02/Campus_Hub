import 'dart:async';

import 'package:campusmate/features/auth/domain/entities/user_entity.dart';
import 'package:campusmate/features/auth/domain/repositories/auth_repository.dart';
import 'package:campusmate/features/auth/presentation/pages/authenticated_home_page.dart';
import 'package:campusmate/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;
  late StreamController<UserEntity?> authStateController;
  late ProviderContainer container;

  const user = UserEntity(
    id: 'user-1',
    email: 'student@campusmate.dev',
    fullName: 'Campus Student',
    emailVerified: false,
  );

  setUp(() {
    repository = MockAuthRepository();
    authStateController = StreamController<UserEntity?>.broadcast();
    when(
      () => repository.watchAuthState(),
    ).thenAnswer((_) => authStateController.stream);
    when(() => repository.getCurrentUser()).thenAnswer((_) async => user);
    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
  });

  tearDown(() async {
    container.dispose();
    await authStateController.close();
  });

  Future<void> pumpSubject(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: AuthenticatedHomePage()),
      ),
    );
    await container.read(authControllerProvider.notifier).initialize();
    await tester.pump();
  }

  testWidgets('shows identity and verification status', (tester) async {
    await pumpSubject(tester);

    expect(find.text('Halo, Campus Student'), findsOneWidget);
    expect(find.text(user.email), findsOneWidget);
    expect(find.text('Belum terverifikasi'), findsOneWidget);
    expect(find.text('Kirim Ulang Verifikasi'), findsOneWidget);
  });

  testWidgets('falls back to email and hides resend for verified users', (
    tester,
  ) async {
    final verifiedUser = UserEntity(
      id: user.id,
      email: user.email,
      fullName: null,
      avatarUrl: user.avatarUrl,
      emailVerified: true,
      createdAt: user.createdAt,
    );
    when(
      () => repository.getCurrentUser(),
    ).thenAnswer((_) async => verifiedUser);
    await pumpSubject(tester);

    expect(find.text('Halo, ${verifiedUser.email}'), findsOneWidget);
    expect(find.text('Terverifikasi'), findsOneWidget);
    expect(find.text('Kirim Ulang Verifikasi'), findsNothing);
  });

  testWidgets('disables actions while an operation is loading', (tester) async {
    final resendCompleter = Completer<void>();
    when(
      () => repository.resendVerificationEmail(),
    ).thenAnswer((_) => resendCompleter.future);
    await pumpSubject(tester);

    await tester.tap(find.text('Kirim Ulang Verifikasi'));
    await tester.pump();

    final resendButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Kirim Ulang Verifikasi'),
    );
    final logoutButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Logout'),
    );
    expect(resendButton.onPressed, isNull);
    expect(logoutButton.onPressed, isNull);
    verify(() => repository.resendVerificationEmail()).called(1);

    resendCompleter.complete();
    await tester.pump();
  });

  testWidgets('logout delegates to the auth controller', (tester) async {
    when(() => repository.signOut()).thenAnswer((_) async {});
    await pumpSubject(tester);

    await tester.tap(find.text('Logout'));
    await tester.pump();

    verify(() => repository.signOut()).called(1);
  });
}
