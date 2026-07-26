import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Defines local persistence operations for authentication tokens.
abstract interface class AuthLocalDataSource {
  /// Stores the access and refresh tokens securely.
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  });

  /// Returns the stored access token, if one exists.
  Future<String?> getAccessToken();

  /// Returns the stored refresh token, if one exists.
  Future<String?> getRefreshToken();

  /// Deletes the stored authentication tokens.
  Future<void> deleteTokens();
}

/// Stores authentication tokens using injected secure storage.
final class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  const AuthLocalDataSourceImpl(this._storage);

  static const _accessTokenKey = 'auth_access_token';
  static const _refreshTokenKey = 'auth_refresh_token';

  final FlutterSecureStorage _storage;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    if (accessToken.trim().isEmpty) {
      throw ArgumentError('Access token must not be empty.', 'accessToken');
    }
    if (refreshToken.trim().isEmpty) {
      throw ArgumentError('Refresh token must not be empty.', 'refreshToken');
    }

    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  @override
  Future<String?> getAccessToken() {
    return _storage.read(key: _accessTokenKey);
  }

  @override
  Future<String?> getRefreshToken() {
    return _storage.read(key: _refreshTokenKey);
  }

  @override
  Future<void> deleteTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}
