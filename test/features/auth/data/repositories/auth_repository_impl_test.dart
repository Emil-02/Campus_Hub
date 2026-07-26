import 'dart:async';

import 'package:campusmate/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:campusmate/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:campusmate/features/auth/data/models/user_model.dart';
import 'package:campusmate/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:campusmate/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

class MockAuthLocalDataSource extends Mock implements AuthLocalDataSource {}

void main() {
  late MockAuthRemoteDataSource remoteDataSource;
  late MockAuthLocalDataSource localDataSource;
  late AuthRepositoryImpl repository;

  setUp(() {
    remoteDataSource = MockAuthRemoteDataSource();
    localDataSource = MockAuthLocalDataSource();
    repository = AuthRepositoryImpl(
      remoteDataSource: remoteDataSource,
      localDataSource: localDataSource,
    );
  });

  test('constructor creates an AuthRepository from injected data sources', () {
    expect(repository, isA<AuthRepository>());
  });

  test('signUp delegates to remote and maps UserModel to UserEntity', () async {
    final model = _model();
    when(
      () => remoteDataSource.signUp(
        email: 'student@campusmate.dev',
        password: 'secure-password',
        fullName: 'Campus Mate',
      ),
    ).thenAnswer((_) async => model);

    final result = await repository.signUp(
      email: 'student@campusmate.dev',
      password: 'secure-password',
      fullName: 'Campus Mate',
    );

    expect(result, model.toEntity());
    verify(
      () => remoteDataSource.signUp(
        email: 'student@campusmate.dev',
        password: 'secure-password',
        fullName: 'Campus Mate',
      ),
    ).called(1);
    verifyZeroInteractions(localDataSource);
  });

  test('signInWithEmail saves session tokens and returns entity', () async {
    final model = _model();
    when(
      () => remoteDataSource.signInWithEmail(
        email: 'student@campusmate.dev',
        password: 'secure-password',
      ),
    ).thenAnswer((_) async => model);
    _stubSessionTokens(remoteDataSource);
    when(
      () => localDataSource.saveTokens(
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
      ),
    ).thenAnswer((_) async {});

    final result = await repository.signInWithEmail(
      email: 'student@campusmate.dev',
      password: 'secure-password',
    );

    expect(result, model.toEntity());
    verify(
      () => remoteDataSource.signInWithEmail(
        email: 'student@campusmate.dev',
        password: 'secure-password',
      ),
    ).called(1);
    verify(
      () => localDataSource.saveTokens(
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
      ),
    ).called(1);
  });

  test('signInWithEmail rejects a missing session token', () async {
    when(
      () => remoteDataSource.signInWithEmail(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => _model());
    when(() => remoteDataSource.getAccessToken()).thenAnswer((_) async => null);
    when(
      () => remoteDataSource.getRefreshToken(),
    ).thenAnswer((_) async => 'refresh-token');

    await expectLater(
      repository.signInWithEmail(
        email: 'student@campusmate.dev',
        password: 'secure-password',
      ),
      throwsA(isA<StateError>()),
    );
    verifyZeroInteractions(localDataSource);
  });

  test(
    'signInWithGoogle ignores null before a fresh user and saves tokens',
    () async {
      final model = _model();
      when(() => remoteDataSource.signInWithGoogle()).thenAnswer((_) async {});
      when(() => remoteDataSource.watchSignInState()).thenAnswer(
        (_) => Stream<UserModel?>.fromIterable(<UserModel?>[null, model]),
      );
      var accessTokenReadCount = 0;
      when(() => remoteDataSource.getAccessToken()).thenAnswer((_) async {
        accessTokenReadCount++;
        return accessTokenReadCount == 1 ? 'previous-token' : 'access-token';
      });
      when(
        () => remoteDataSource.getRefreshToken(),
      ).thenAnswer((_) async => 'refresh-token');
      when(
        () => remoteDataSource.getCurrentUser(),
      ).thenAnswer((_) async => model);
      when(
        () => localDataSource.saveTokens(
          accessToken: 'access-token',
          refreshToken: 'refresh-token',
        ),
      ).thenAnswer((_) async {});

      final result = await repository.signInWithGoogle();

      expect(result, model.toEntity());
      verify(() => remoteDataSource.signInWithGoogle()).called(1);
      verify(
        () => localDataSource.saveTokens(
          accessToken: 'access-token',
          refreshToken: 'refresh-token',
        ),
      ).called(1);
      verify(() => remoteDataSource.getAccessToken()).called(3);
    },
  );

  test('signInWithGoogle ignores a replay from the previous session', () async {
    final staleModel = _model(id: 'stale-user-id');
    final freshModel = _model(id: 'fresh-user-id');
    when(() => remoteDataSource.signInWithGoogle()).thenAnswer((_) async {});
    when(() => remoteDataSource.watchSignInState()).thenAnswer(
      (_) =>
          Stream<UserModel?>.fromIterable(<UserModel?>[staleModel, freshModel]),
    );
    final accessTokens = <String>[
      'previous-token',
      'previous-token',
      'fresh-token',
      'fresh-token',
    ];
    when(
      () => remoteDataSource.getAccessToken(),
    ).thenAnswer((_) async => accessTokens.removeAt(0));
    when(
      () => remoteDataSource.getRefreshToken(),
    ).thenAnswer((_) async => 'fresh-refresh-token');
    when(
      () => remoteDataSource.getCurrentUser(),
    ).thenAnswer((_) async => freshModel);
    when(
      () => localDataSource.saveTokens(
        accessToken: 'fresh-token',
        refreshToken: 'fresh-refresh-token',
      ),
    ).thenAnswer((_) async {});

    final result = await repository.signInWithGoogle();

    expect(result, freshModel.toEntity());
    verify(() => remoteDataSource.getCurrentUser()).called(1);
    verify(
      () => localDataSource.saveTokens(
        accessToken: 'fresh-token',
        refreshToken: 'fresh-refresh-token',
      ),
    ).called(1);
  });

  test('signInWithGoogle times out and cancels its subscription', () async {
    var subscriptionCancelled = false;
    final authStateController = StreamController<UserModel?>(
      onCancel: () {
        subscriptionCancelled = true;
      },
    );
    repository = AuthRepositoryImpl(
      remoteDataSource: remoteDataSource,
      localDataSource: localDataSource,
      googleSignInTimeout: const Duration(milliseconds: 10),
    );
    when(
      () => remoteDataSource.getAccessToken(),
    ).thenAnswer((_) async => 'previous-token');
    when(() => remoteDataSource.signInWithGoogle()).thenAnswer((_) async {});
    when(
      () => remoteDataSource.watchSignInState(),
    ).thenAnswer((_) => authStateController.stream);

    await expectLater(
      repository.signInWithGoogle(),
      throwsA(
        isA<TimeoutException>().having(
          (error) => error.message,
          'message',
          contains('Google sign-in did not complete'),
        ),
      ),
    );

    expect(subscriptionCancelled, isTrue);
    verifyZeroInteractions(localDataSource);
    await authStateController.close();
  });

  test('signOut signs out remotely and deletes local tokens', () async {
    when(() => remoteDataSource.signOut()).thenAnswer((_) async {});
    when(() => localDataSource.deleteTokens()).thenAnswer((_) async {});

    await repository.signOut();

    verifyInOrder([
      () => remoteDataSource.signOut(),
      () => localDataSource.deleteTokens(),
    ]);
  });

  group('getCurrentUser', () {
    test('maps a remote UserModel to UserEntity', () async {
      final model = _model();
      when(
        () => remoteDataSource.getCurrentUser(),
      ).thenAnswer((_) async => model);

      final result = await repository.getCurrentUser();

      expect(result, model.toEntity());
      verify(() => remoteDataSource.getCurrentUser()).called(1);
    });

    test('returns null when remote has no current user', () async {
      when(
        () => remoteDataSource.getCurrentUser(),
      ).thenAnswer((_) async => null);

      final result = await repository.getCurrentUser();

      expect(result, isNull);
    });
  });

  test('watchAuthState maps models and null values to domain entities', () {
    final model = _model();
    when(() => remoteDataSource.watchAuthState()).thenAnswer(
      (_) => Stream<UserModel?>.fromIterable(<UserModel?>[model, null]),
    );

    expectLater(
      repository.watchAuthState(),
      emitsInOrder(<Object?>[model.toEntity(), null, emitsDone]),
    );
  });

  test('resetPassword delegates only to remote data source', () async {
    when(
      () => remoteDataSource.resetPassword(email: 'student@campusmate.dev'),
    ).thenAnswer((_) async {});

    await repository.resetPassword(email: 'student@campusmate.dev');

    verify(
      () => remoteDataSource.resetPassword(email: 'student@campusmate.dev'),
    ).called(1);
    verifyZeroInteractions(localDataSource);
  });

  test(
    'resendVerificationEmail delegates only to remote data source',
    () async {
      when(
        () => remoteDataSource.resendVerificationEmail(),
      ).thenAnswer((_) async {});

      await repository.resendVerificationEmail();

      verify(() => remoteDataSource.resendVerificationEmail()).called(1);
      verifyZeroInteractions(localDataSource);
    },
  );
}

void _stubSessionTokens(MockAuthRemoteDataSource remoteDataSource) {
  when(
    () => remoteDataSource.getAccessToken(),
  ).thenAnswer((_) async => 'access-token');
  when(
    () => remoteDataSource.getRefreshToken(),
  ).thenAnswer((_) async => 'refresh-token');
}

UserModel _model({String id = 'user-id'}) {
  return UserModel(
    id: id,
    email: 'student@campusmate.dev',
    fullName: 'Campus Mate',
    avatarUrl: 'https://example.com/avatar.png',
    emailVerified: true,
    createdAt: DateTime.parse('2026-07-27T10:00:00.000Z'),
  );
}
