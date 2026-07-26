import 'package:campusmate/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  const accessTokenKey = 'auth_access_token';
  const refreshTokenKey = 'auth_refresh_token';

  late MockFlutterSecureStorage storage;
  late AuthLocalDataSourceImpl dataSource;

  setUp(() {
    storage = MockFlutterSecureStorage();
    dataSource = AuthLocalDataSourceImpl(storage);
  });

  test('saveTokens stores both tokens under the expected keys', () async {
    when(
      () => storage.write(key: accessTokenKey, value: 'access-token'),
    ).thenAnswer((_) async {});
    when(
      () => storage.write(key: refreshTokenKey, value: 'refresh-token'),
    ).thenAnswer((_) async {});

    await dataSource.saveTokens(
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
    );

    verify(
      () => storage.write(key: accessTokenKey, value: 'access-token'),
    ).called(1);
    verify(
      () => storage.write(key: refreshTokenKey, value: 'refresh-token'),
    ).called(1);
  });

  for (final invalidToken in <String>['', '   ']) {
    test('saveTokens rejects an empty access token', () async {
      await expectLater(
        dataSource.saveTokens(
          accessToken: invalidToken,
          refreshToken: 'refresh-token',
        ),
        throwsA(isA<ArgumentError>()),
      );
      verifyZeroInteractions(storage);
    });

    test('saveTokens rejects an empty refresh token', () async {
      await expectLater(
        dataSource.saveTokens(
          accessToken: 'access-token',
          refreshToken: invalidToken,
        ),
        throwsA(isA<ArgumentError>()),
      );
      verifyZeroInteractions(storage);
    });
  }

  test('getAccessToken reads the access token key', () async {
    when(
      () => storage.read(key: accessTokenKey),
    ).thenAnswer((_) async => 'access-token');

    final result = await dataSource.getAccessToken();

    expect(result, 'access-token');
    verify(() => storage.read(key: accessTokenKey)).called(1);
  });

  test('getRefreshToken reads the refresh token key', () async {
    when(
      () => storage.read(key: refreshTokenKey),
    ).thenAnswer((_) async => 'refresh-token');

    final result = await dataSource.getRefreshToken();

    expect(result, 'refresh-token');
    verify(() => storage.read(key: refreshTokenKey)).called(1);
  });

  test('deleteTokens deletes only the two authentication keys', () async {
    when(() => storage.delete(key: accessTokenKey)).thenAnswer((_) async {});
    when(() => storage.delete(key: refreshTokenKey)).thenAnswer((_) async {});

    await dataSource.deleteTokens();

    verify(() => storage.delete(key: accessTokenKey)).called(1);
    verify(() => storage.delete(key: refreshTokenKey)).called(1);
    verifyNever(() => storage.deleteAll());
  });
}
