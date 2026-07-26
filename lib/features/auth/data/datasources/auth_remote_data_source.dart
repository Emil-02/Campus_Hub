import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_model.dart';

/// Defines remote authentication operations for the data layer.
abstract interface class AuthRemoteDataSource {
  /// Registers a user with the provided account details.
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String fullName,
  });

  /// Signs a user in with an email address and password.
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  });

  /// Starts a Google sign-in flow.
  Future<void> signInWithGoogle();

  /// Signs the current user out.
  Future<void> signOut();

  /// Sends password reset instructions to an email address.
  Future<void> resetPassword({required String email});

  /// Resends the verification email for the current user.
  Future<void> resendVerificationEmail();

  /// Returns the current user, if one exists.
  Future<UserModel?> getCurrentUser();

  /// Emits the current user whenever authentication state changes.
  Stream<UserModel?> watchAuthState();
}

/// Implements remote authentication operations using an injected client.
final class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  const AuthRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: <String, dynamic>{'full_name': fullName},
    );
    final user = response.user;
    if (user == null) {
      throw StateError('Sign-up completed without returning a user.');
    }

    return _mapUser(user);
  }

  @override
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    final user = response.user;
    if (user == null) {
      throw StateError('Email sign-in completed without returning a user.');
    }

    return _mapUser(user);
  }

  @override
  Future<void> signInWithGoogle() async {
    final started = await _client.auth.signInWithOAuth(OAuthProvider.google);
    if (!started) {
      throw StateError('Google sign-in could not be started.');
    }
  }

  @override
  Future<void> signOut() {
    return _client.auth.signOut();
  }

  @override
  Future<void> resetPassword({required String email}) {
    return _client.auth.resetPasswordForEmail(email);
  }

  @override
  Future<void> resendVerificationEmail() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError(
        'A current user is required to resend a verification email.',
      );
    }

    final email = _requiredEmail(user);
    await _client.auth.resend(email: email, type: OtpType.signup);
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final user = _client.auth.currentUser;
    return user == null ? null : _mapUser(user);
  }

  @override
  Stream<UserModel?> watchAuthState() {
    return _client.auth.onAuthStateChange.map((state) {
      final user = state.session?.user;
      return user == null ? null : _mapUser(user);
    });
  }

  UserModel _mapUser(User user) {
    final createdAt = DateTime.tryParse(user.createdAt);
    if (createdAt == null) {
      throw const FormatException(
        'Supabase user createdAt must be a valid ISO-8601 value.',
      );
    }

    return UserModel(
      id: user.id,
      email: _requiredEmail(user),
      fullName: _metadataString(user.userMetadata, 'full_name'),
      avatarUrl: _metadataString(user.userMetadata, 'avatar_url'),
      emailVerified: user.emailConfirmedAt != null,
      createdAt: createdAt,
    );
  }

  String _requiredEmail(User user) {
    final email = user.email;
    if (email == null || email.trim().isEmpty) {
      throw const FormatException(
        'Supabase user email must be a non-empty String.',
      );
    }
    return email;
  }

  String? _metadataString(Map<String, dynamic>? metadata, String key) {
    final value = metadata?[key];
    if (value == null) {
      return null;
    }
    if (value is! String) {
      throw FormatException(
        'Supabase user metadata "$key" must be a String or null.',
      );
    }
    return value;
  }
}
