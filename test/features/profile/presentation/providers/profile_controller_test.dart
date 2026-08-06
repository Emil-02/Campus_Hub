import 'dart:io';

import 'package:campusmate/features/profile/domain/entities/profile_entity.dart';
import 'package:campusmate/features/profile/domain/repositories/profile_repository.dart';
import 'package:campusmate/features/profile/presentation/providers/profile_provider.dart';
import 'package:campusmate/features/profile/presentation/providers/profile_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late MockProfileRepository repository;
  late ProviderContainer container;

  const profile = ProfileEntity(
    id: 'profile-1',
    fullName: 'Emil Rahmat',
    university: 'Universitas Contoh',
    studyProgram: 'Teknik Informatika',
    degreeLevel: 'S1',
    semester: 5,
  );

  setUp(() {
    repository = MockProfileRepository();
    container = ProviderContainer(
      overrides: [profileRepositoryProvider.overrideWithValue(repository)],
    );
  });

  tearDown(() => container.dispose());

  test('loadProfile exposes the loaded profile', () async {
    when(() => repository.getProfile()).thenAnswer((_) async => profile);

    await container.read(profileControllerProvider.notifier).loadProfile();

    expect(
      container.read(profileControllerProvider),
      const ProfileState.loaded(profile),
    );
  });

  test('loadProfile surfaces a safe failure message', () async {
    when(() => repository.getProfile()).thenThrow(StateError('no session'));

    await container.read(profileControllerProvider.notifier).loadProfile();

    final state = container.read(profileControllerProvider);
    expect(state.status, ProfileStatus.failure);
    expect(state.errorMessage, 'Sesi tidak valid. Silakan login ulang.');
  });

  test('updateProfile stores the new profile and returns true', () async {
    when(() => repository.getProfile()).thenAnswer((_) async => profile);
    await container.read(profileControllerProvider.notifier).loadProfile();

    const updated = ProfileEntity(
      id: 'profile-1',
      fullName: 'Emil R.',
      semester: 6,
    );
    when(
      () => repository.updateProfile(
        fullName: any(named: 'fullName'),
        university: any(named: 'university'),
        studyProgram: any(named: 'studyProgram'),
        degreeLevel: any(named: 'degreeLevel'),
        semester: any(named: 'semester'),
      ),
    ).thenAnswer((_) async => updated);

    final saved = await container
        .read(profileControllerProvider.notifier)
        .updateProfile(fullName: 'Emil R.', semester: 6);

    expect(saved, isTrue);
    expect(
      container.read(profileControllerProvider),
      const ProfileState.loaded(updated),
    );
  });

  test('updateProfile keeps the previous profile on failure', () async {
    when(() => repository.getProfile()).thenAnswer((_) async => profile);
    await container.read(profileControllerProvider.notifier).loadProfile();

    when(
      () => repository.updateProfile(
        fullName: any(named: 'fullName'),
        university: any(named: 'university'),
        studyProgram: any(named: 'studyProgram'),
        degreeLevel: any(named: 'degreeLevel'),
        semester: any(named: 'semester'),
      ),
    ).thenThrow(const FormatException('bad data'));

    final saved = await container
        .read(profileControllerProvider.notifier)
        .updateProfile(fullName: 'X');

    final state = container.read(profileControllerProvider);
    expect(saved, isFalse);
    expect(state.status, ProfileStatus.failure);
    expect(state.profile, profile);
    expect(state.errorMessage, 'Data profil tidak valid.');
  });

  test('uploadAvatar stores the refreshed profile', () async {
    const withAvatar = ProfileEntity(
      id: 'profile-1',
      fullName: 'Emil Rahmat',
      avatarUrl: 'https://cdn.example.com/a.png',
    );
    when(
      () => repository.uploadAvatar(any()),
    ).thenAnswer((_) async => withAvatar);

    final saved = await container
        .read(profileControllerProvider.notifier)
        .uploadAvatar(File('avatar.png'));

    expect(saved, isTrue);
    expect(
      container.read(profileControllerProvider),
      const ProfileState.loaded(withAvatar),
    );
  });

  test('changePassword returns null on success', () async {
    when(
      () => repository.changePassword(
        currentPassword: any(named: 'currentPassword'),
        newPassword: any(named: 'newPassword'),
      ),
    ).thenAnswer((_) async {});

    final error = await container
        .read(profileControllerProvider.notifier)
        .changePassword(currentPassword: 'Lama123!', newPassword: 'Baru1234');

    expect(error, isNull);
  });

  test('changePassword maps a wrong old password to a clear message', () async {
    when(
      () => repository.changePassword(
        currentPassword: any(named: 'currentPassword'),
        newPassword: any(named: 'newPassword'),
      ),
    ).thenThrow(
      const AuthException(
        'Invalid login credentials',
        code: 'invalid_credentials',
      ),
    );

    final error = await container
        .read(profileControllerProvider.notifier)
        .changePassword(currentPassword: 'salah', newPassword: 'Baru1234');

    expect(error, 'Password lama salah.');
  });

  setUpAll(() {
    registerFallbackValue(File('fallback.png'));
  });
}
