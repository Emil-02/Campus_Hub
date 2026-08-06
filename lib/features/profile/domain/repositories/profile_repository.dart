import 'dart:io';

import '../entities/profile_entity.dart';

/// Contract for profile data operations.
abstract interface class ProfileRepository {
  Future<ProfileEntity> getProfile();

  Future<ProfileEntity> updateProfile({
    required String fullName,
    String? university,
    String? studyProgram,
    String? degreeLevel,
    int? semester,
  });

  /// Uploads the avatar file and returns the profile with the new URL.
  Future<ProfileEntity> uploadAvatar(File file);

  /// Re-authenticates with [currentPassword] then sets [newPassword].
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}
