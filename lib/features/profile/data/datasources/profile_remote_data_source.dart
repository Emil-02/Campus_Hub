import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile_model.dart';

/// Remote operations for the `profiles` table, avatar storage, and password.
abstract interface class ProfileRemoteDataSource {
  Future<ProfileModel> getProfile();

  Future<ProfileModel> updateProfile({
    required String fullName,
    String? university,
    String? studyProgram,
    String? degreeLevel,
    int? semester,
  });

  Future<ProfileModel> uploadAvatar(File file);

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}

/// Implements profile operations using the injected Supabase client.
final class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  const ProfileRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  String get _userId {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('A signed-in user is required for profile operations.');
    }
    return userId;
  }

  @override
  Future<ProfileModel> getProfile() async {
    final userId = _userId;
    final row = await _client
        .from('profiles')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    if (row != null) {
      return ProfileModel.fromJson(row);
    }

    // Self-heal for accounts created before the profiles migration.
    final created = await _client
        .from('profiles')
        .insert({'user_id': userId, 'full_name': _metadataFullName()})
        .select()
        .single();
    return ProfileModel.fromJson(created);
  }

  @override
  Future<ProfileModel> updateProfile({
    required String fullName,
    String? university,
    String? studyProgram,
    String? degreeLevel,
    int? semester,
  }) async {
    final row = await _client
        .from('profiles')
        .update({
          'full_name': fullName,
          'university': university,
          'study_program': studyProgram,
          'degree_level': degreeLevel,
          'semester': semester,
        })
        .eq('user_id', _userId)
        .select()
        .single();
    return ProfileModel.fromJson(row);
  }

  @override
  Future<ProfileModel> uploadAvatar(File file) async {
    final userId = _userId;
    final name = file.path.split(Platform.pathSeparator).last;
    final dotIndex = name.lastIndexOf('.');
    final extension = dotIndex == -1
        ? ''
        : name.substring(dotIndex).toLowerCase();
    final objectPath =
        '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}$extension';

    await _client.storage
        .from('avatars')
        .upload(objectPath, file, fileOptions: const FileOptions(upsert: true));
    final publicUrl = _client.storage.from('avatars').getPublicUrl(objectPath);

    final row = await _client
        .from('profiles')
        .update({'avatar_url': publicUrl})
        .eq('user_id', userId)
        .select()
        .single();
    return ProfileModel.fromJson(row);
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final email = _client.auth.currentUser?.email;
    if (email == null) {
      throw StateError('A signed-in user is required to change the password.');
    }

    // Supabase does not verify the old password; re-authenticate first.
    await _client.auth.signInWithPassword(
      email: email,
      password: currentPassword,
    );
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  String _metadataFullName() {
    final metadata = _client.auth.currentUser?.userMetadata;
    final value = metadata?['full_name'];
    return value is String ? value : '';
  }
}
