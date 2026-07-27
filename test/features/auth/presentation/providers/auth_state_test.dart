import 'package:campusmate/features/auth/domain/entities/user_entity.dart';
import 'package:campusmate/features/auth/presentation/providers/auth_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const user = UserEntity(
    id: 'user-id',
    email: 'student@campusmate.dev',
    emailVerified: true,
  );

  test('identical authenticated states are equal', () {
    expect(
      const AuthState.authenticated(user),
      const AuthState.authenticated(user),
    );
  });

  test('status, user, and error message affect equality', () {
    expect(const AuthState.initial(), isNot(const AuthState.loading()));
    expect(
      const AuthState.authenticated(user),
      isNot(
        const AuthState.authenticated(
          UserEntity(
            id: 'other-user-id',
            email: 'student@campusmate.dev',
            emailVerified: true,
          ),
        ),
      ),
    );
    expect(
      const AuthState.failure('first error'),
      isNot(const AuthState.failure('second error')),
    );
  });

  test('state constructors expose the expected values', () {
    expect(const AuthState.initial().status, AuthStatus.initial);
    expect(const AuthState.loading().status, AuthStatus.loading);
    expect(
      const AuthState.authenticated(user).status,
      AuthStatus.authenticated,
    );
    expect(const AuthState.authenticated(user).user, user);
    expect(
      const AuthState.unauthenticated().status,
      AuthStatus.unauthenticated,
    );
    expect(const AuthState.failure('error').status, AuthStatus.failure);
    expect(const AuthState.failure('error').errorMessage, 'error');
  });
}
