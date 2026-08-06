import 'dart:io';

import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_data_source.dart';

/// Bridges the profile domain contract to the remote data source.
final class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl(this._remoteDataSource);

  final ProfileRemoteDataSource _remoteDataSource;

  @override
  Future<ProfileEntity> getProfile() async {
    final model = await _remoteDataSource.getProfile();
    return model.toEntity();
  }

  @override
  Future<ProfileEntity> updateProfile({
    required String fullName,
    String? university,
    String? studyProgram,
    String? degreeLevel,
    int? semester,
  }) async {
    final model = await _remoteDataSource.updateProfile(
      fullName: fullName,
      university: university,
      studyProgram: studyProgram,
      degreeLevel: degreeLevel,
      semester: semester,
    );
    return model.toEntity();
  }

  @override
  Future<ProfileEntity> uploadAvatar(File file) async {
    final model = await _remoteDataSource.uploadAvatar(file);
    return model.toEntity();
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return _remoteDataSource.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }
}
