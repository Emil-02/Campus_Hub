import 'dart:async';

import 'package:campusmate/features/auth/domain/entities/user_entity.dart';
import 'package:campusmate/features/auth/domain/repositories/auth_repository.dart';
import 'package:campusmate/features/auth/presentation/pages/auth_bootstrap_page.dart';
import 'package:campusmate/features/auth/presentation/providers/auth_dependencies.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;
  late StreamController<UserEntity?> authStateController;

  setUp(() {
    repository = MockAuthRepository();
    authStateController = StreamController<UserEntity?>.broadcast();
    when(
      () => repository.watchAuthState(),
    ).thenAnswer((_) => authStateController.stream);
  });

  tearDown(() async {
    await authStateController.close();
  });

  Widget subject() {
    return ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
      child: const MaterialApp(home: AuthBootstrapPage()),
    );
  }

  testWidgets('shows loading while bootstrap is in progress', (tester) async {
    final completer = Completer<UserEntity?>();
    when(() => repository.getCurrentUser()).thenAnswer((_) => completer.future);

    await tester.pumpWidget(subject());
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    completer.complete(null);
    await tester.pump();
  });

  testWidgets('initializes only once across rebuilds', (tester) async {
    when(() => repository.getCurrentUser()).thenAnswer((_) async => null);

    await tester.pumpWidget(subject());
    await tester.pump();
    await tester.pumpWidget(subject());
    await tester.pump();

    verify(() => repository.getCurrentUser()).called(1);
    verify(() => repository.watchAuthState()).called(1);
  });

  testWidgets('shows a safe failure and retries bootstrap', (tester) async {
    var attempts = 0;
    when(() => repository.getCurrentUser()).thenAnswer((_) async {
      attempts++;
      if (attempts == 1) {
        throw StateError('private detail');
      }
      return null;
    });

    await tester.pumpWidget(subject());
    await tester.pump();
    await tester.pump();

    expect(
      find.text('Proses autentikasi tidak dapat diselesaikan.'),
      findsOneWidget,
    );
    expect(find.text('private detail'), findsNothing);
    await tester.tap(find.text('Coba Lagi'));
    await tester.pump();
    await tester.pump();

    expect(attempts, 2);
    verify(() => repository.watchAuthState()).called(1);
  });
}
