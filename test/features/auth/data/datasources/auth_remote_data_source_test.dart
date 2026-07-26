import 'package:campusmate/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:campusmate/features/auth/data/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

void main() {
  late MockSupabaseClient client;
  late MockGoTrueClient auth;
  late AuthRemoteDataSourceImpl dataSource;

  setUp(() {
    client = MockSupabaseClient();
    auth = MockGoTrueClient();
    when(() => client.auth).thenReturn(auth);
    dataSource = AuthRemoteDataSourceImpl(client);
  });

  test('constructor accepts an injected SupabaseClient', () {
    expect(dataSource, isA<AuthRemoteDataSource>());
  });

  group('signUp', () {
    test('forwards credentials and full_name metadata', () async {
      const email = 'student@campusmate.dev';
      const password = 'secure-password';
      const fullName = 'Campus Mate';
      final user = _user();
      when(
        () => auth.signUp(
          email: email,
          password: password,
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => AuthResponse(user: user));

      await dataSource.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );

      final captured = verify(
        () => auth.signUp(
          email: email,
          password: password,
          data: captureAny(named: 'data'),
        ),
      ).captured.single;
      expect(captured, <String, dynamic>{'full_name': fullName});
    });

    test('returns a mapped UserModel', () async {
      final user = _user();
      when(
        () => auth.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => AuthResponse(user: user));

      final result = await dataSource.signUp(
        email: 'student@campusmate.dev',
        password: 'secure-password',
        fullName: 'Campus Mate',
      );

      expect(result, _model());
    });

    test('throws StateError when response has no user', () async {
      when(
        () => auth.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => AuthResponse());

      await expectLater(
        dataSource.signUp(
          email: 'student@campusmate.dev',
          password: 'secure-password',
          fullName: 'Campus Mate',
        ),
        throwsA(isA<StateError>()),
      );
    });
  });

  test('signInWithEmail signs in and returns a mapped UserModel', () async {
    const email = 'student@campusmate.dev';
    const password = 'secure-password';
    final user = _user();
    when(
      () => auth.signInWithPassword(email: email, password: password),
    ).thenAnswer((_) async => AuthResponse(user: user));

    final result = await dataSource.signInWithEmail(
      email: email,
      password: password,
    );

    expect(result, _model());
    verify(
      () => auth.signInWithPassword(email: email, password: password),
    ).called(1);
  });

  test('signOut delegates to auth.signOut', () async {
    when(() => auth.signOut()).thenAnswer((_) async {});

    await dataSource.signOut();

    verify(() => auth.signOut()).called(1);
  });

  test('resetPassword forwards the email address', () async {
    const email = 'student@campusmate.dev';
    when(() => auth.resetPasswordForEmail(email)).thenAnswer((_) async {});

    await dataSource.resetPassword(email: email);

    verify(() => auth.resetPasswordForEmail(email)).called(1);
  });

  group('resendVerificationEmail', () {
    test('resends a signup email for the current user', () async {
      final user = _user();
      when(() => auth.currentUser).thenReturn(user);
      when(
        () => auth.resend(email: user.email, type: OtpType.signup),
      ).thenAnswer((_) async => ResendResponse());

      await dataSource.resendVerificationEmail();

      verify(
        () => auth.resend(email: user.email, type: OtpType.signup),
      ).called(1);
    });

    test('throws StateError when there is no current user', () async {
      when(() => auth.currentUser).thenReturn(null);

      await expectLater(
        dataSource.resendVerificationEmail(),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('getCurrentUser', () {
    test('returns null when there is no current user', () async {
      when(() => auth.currentUser).thenReturn(null);

      final result = await dataSource.getCurrentUser();

      expect(result, isNull);
    });

    test('maps the current user', () async {
      when(() => auth.currentUser).thenReturn(_user());

      final result = await dataSource.getCurrentUser();

      expect(result, _model());
    });

    for (final invalidEmail in <String?>[null, '', '   ']) {
      test('rejects invalid user email: $invalidEmail', () async {
        when(() => auth.currentUser).thenReturn(_user(email: invalidEmail));

        await expectLater(
          dataSource.getCurrentUser(),
          throwsA(isA<FormatException>()),
        );
      });
    }
  });

  test('watchAuthState maps users and missing sessions', () async {
    final user = _user();
    final session = Session(
      accessToken: 'access-token',
      tokenType: 'bearer',
      user: user,
    );
    final authStates = Stream<AuthState>.fromIterable(<AuthState>[
      AuthState(AuthChangeEvent.signedIn, session),
      const AuthState(AuthChangeEvent.signedOut, null),
    ]);
    when(() => auth.onAuthStateChange).thenAnswer((_) => authStates);

    await expectLater(
      dataSource.watchAuthState(),
      emitsInOrder(<Object?>[_model(), null, emitsDone]),
    );
  });
}

User _user({String? email = 'student@campusmate.dev'}) {
  return User(
    id: 'user-id',
    appMetadata: const <String, dynamic>{},
    userMetadata: const <String, dynamic>{
      'full_name': 'Campus Mate',
      'avatar_url': 'https://example.com/avatar.png',
    },
    aud: 'authenticated',
    email: email,
    createdAt: '2026-07-27T10:00:00.000Z',
    emailConfirmedAt: '2026-07-27T10:05:00.000Z',
  );
}

UserModel _model() {
  return UserModel(
    id: 'user-id',
    email: 'student@campusmate.dev',
    fullName: 'Campus Mate',
    avatarUrl: 'https://example.com/avatar.png',
    emailVerified: true,
    createdAt: DateTime.parse('2026-07-27T10:00:00.000Z'),
  );
}
