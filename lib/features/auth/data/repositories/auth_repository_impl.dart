import 'dart:async';

import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/user_model.dart';

/// Coordinates authentication data sources for the domain repository.
final class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required AuthLocalDataSource localDataSource,
    Duration googleSignInTimeout = const Duration(minutes: 2),
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource,
       _googleSignInTimeout = googleSignInTimeout;

  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;
  final Duration _googleSignInTimeout;

  // TODO(T-031): Translate data-source exceptions into Failure/Either after
  // the core Failure types exist and AuthRepository adopts that contract.

  @override
  Future<UserEntity> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final model = await _remoteDataSource.signUp(
      email: email,
      password: password,
      fullName: fullName,
    );
    return model.toEntity();
  }

  @override
  Future<UserEntity> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final model = await _remoteDataSource.signInWithEmail(
      email: email,
      password: password,
    );
    await _saveCurrentSessionTokens();
    return model.toEntity();
  }

  @override
  Future<UserEntity> signInWithGoogle() async {
    final previousAccessToken = await _remoteDataSource.getAccessToken();
    await _remoteDataSource.signInWithGoogle();
    final model = await _remoteDataSource
        .watchSignInState()
        .asyncMap((user) async {
          if (user == null) {
            return null;
          }

          final accessToken = await _remoteDataSource.getAccessToken();
          if (accessToken == null ||
              accessToken.trim().isEmpty ||
              accessToken == previousAccessToken) {
            return null;
          }

          return _remoteDataSource.getCurrentUser();
        })
        .where((user) => user != null)
        .cast<UserModel>()
        .timeout(
          _googleSignInTimeout,
          onTimeout: (sink) {
            sink.addError(
              TimeoutException(
                'Google sign-in did not complete within the allowed time.',
                _googleSignInTimeout,
              ),
            );
            sink.close();
          },
        )
        .first;
    await _saveCurrentSessionTokens();
    return model.toEntity();
  }

  @override
  Future<void> signOut() async {
    await _remoteDataSource.signOut();
    await _localDataSource.deleteTokens();
  }

  @override
  Future<void> resetPassword({required String email}) {
    return _remoteDataSource.resetPassword(email: email);
  }

  @override
  Future<void> resendVerificationEmail() {
    return _remoteDataSource.resendVerificationEmail();
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    final model = await _remoteDataSource.getCurrentUser();
    return model?.toEntity();
  }

  @override
  Stream<UserEntity?> watchAuthState() {
    return _remoteDataSource.watchAuthState().map((model) => model?.toEntity());
  }

  Future<void> _saveCurrentSessionTokens() async {
    final accessToken = await _remoteDataSource.getAccessToken();
    final refreshToken = await _remoteDataSource.getRefreshToken();
    if (accessToken == null || accessToken.trim().isEmpty) {
      throw StateError(
        'Successful sign-in did not provide a valid access token.',
      );
    }
    if (refreshToken == null || refreshToken.trim().isEmpty) {
      throw StateError(
        'Successful sign-in did not provide a valid refresh token.',
      );
    }

    await _localDataSource.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }
}
