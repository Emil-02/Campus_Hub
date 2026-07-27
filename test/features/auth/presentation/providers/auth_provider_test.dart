import 'package:campusmate/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:campusmate/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:campusmate/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:campusmate/features/auth/domain/repositories/auth_repository.dart';
import 'package:campusmate/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

class MockAuthLocalDataSource extends Mock implements AuthLocalDataSource {}

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  test(
    'authRepositoryProvider composes overridden datasource dependencies',
    () {
      final remoteDataSource = MockAuthRemoteDataSource();
      final localDataSource = MockAuthLocalDataSource();
      final container = ProviderContainer(
        overrides: [
          authRemoteDataSourceProvider.overrideWithValue(remoteDataSource),
          authLocalDataSourceProvider.overrideWithValue(localDataSource),
        ],
      );
      addTearDown(container.dispose);

      final repository = container.read(authRepositoryProvider);

      expect(repository, isA<AuthRepositoryImpl>());
      expect(repository, isA<AuthRepository>());
    },
  );

  test('secure storage provider can be overridden without a device', () {
    final storage = MockFlutterSecureStorage();
    final container = ProviderContainer(
      overrides: [flutterSecureStorageProvider.overrideWithValue(storage)],
    );
    addTearDown(container.dispose);

    expect(container.read(flutterSecureStorageProvider), same(storage));
  });
}
