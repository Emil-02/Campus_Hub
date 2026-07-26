import '../entities/user_entity.dart';

/// Defines the domain contract for authentication operations.
abstract interface class AuthRepository {
  /// Registers a user with the provided account details.
  Future<UserEntity> signUp({
    required String email,
    required String password,
    required String fullName,
  });

  /// Signs a user in with an email address and password.
  Future<UserEntity> signInWithEmail({
    required String email,
    required String password,
  });

  /// Signs a user in with Google.
  Future<UserEntity> signInWithGoogle();

  /// Signs the current user out.
  Future<void> signOut();

  /// Starts a password reset for the provided email address.
  Future<void> resetPassword({required String email});

  /// Resends the current user's verification email.
  Future<void> resendVerificationEmail();

  /// Returns the currently signed-in user, if one exists.
  Future<UserEntity?> getCurrentUser();

  /// Emits the current user whenever authentication state changes.
  Stream<UserEntity?> watchAuthState();
}
