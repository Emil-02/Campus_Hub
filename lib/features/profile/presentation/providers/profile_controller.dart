import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthException, PostgrestException, StorageException;

import '../../domain/repositories/profile_repository.dart';
import 'profile_dependencies.dart';
import 'profile_state.dart';

/// Coordinates profile operations and exposes their state.
final class ProfileController extends Notifier<ProfileState> {
  ProfileRepository get _repository => ref.read(profileRepositoryProvider);

  @override
  ProfileState build() => const ProfileState.initial();

  /// Loads the current user's profile.
  Future<void> loadProfile() async {
    state = const ProfileState.loading();
    try {
      final profile = await _repository.getProfile();
      state = ProfileState.loaded(profile);
    } catch (error) {
      state = ProfileState.failure(_safeErrorMessage(error));
    }
  }

  /// Saves profile fields. Returns true when stored successfully.
  Future<bool> updateProfile({
    required String fullName,
    String? university,
    String? studyProgram,
    String? degreeLevel,
    int? semester,
  }) async {
    final previous = state.profile;
    if (previous != null) {
      state = ProfileState.loaded(previous, isMutating: true);
    }
    try {
      final profile = await _repository.updateProfile(
        fullName: fullName,
        university: university,
        studyProgram: studyProgram,
        degreeLevel: degreeLevel,
        semester: semester,
      );
      state = ProfileState.loaded(profile);
      return true;
    } catch (error) {
      state = ProfileState.failure(_safeErrorMessage(error), profile: previous);
      return false;
    }
  }

  /// Uploads a new avatar. Returns true when stored successfully.
  Future<bool> uploadAvatar(File file) async {
    final previous = state.profile;
    if (previous != null) {
      state = ProfileState.loaded(previous, isMutating: true);
    }
    try {
      final profile = await _repository.uploadAvatar(file);
      state = ProfileState.loaded(profile);
      return true;
    } catch (error) {
      state = ProfileState.failure(_safeErrorMessage(error), profile: previous);
      return false;
    }
  }

  /// Changes the account password. Returns null on success or an
  /// error message on failure; profile state is left untouched.
  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _repository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return null;
    } on AuthException catch (error) {
      debugPrint('Change password auth error: $error');
      final message = error.message.toLowerCase();
      if (error.code == 'invalid_credentials' ||
          message.contains('invalid login credentials')) {
        return 'Password lama salah.';
      }
      if (error.code == 'same_password') {
        return 'Password baru tidak boleh sama dengan password lama.';
      }
      if (error.code == 'weak_password' ||
          message.contains('password should be')) {
        return 'Password baru terlalu lemah (minimal 8 karakter).';
      }
      return 'Gagal mengubah password: ${error.message}';
    } catch (error) {
      return _safeErrorMessage(error);
    }
  }

  String _safeErrorMessage(Object error) {
    debugPrint('Profile error: $error');
    if (error is StorageException) {
      return 'Gagal mengunggah foto. Coba lagi.';
    }
    if (error is PostgrestException) {
      return 'Gagal menyimpan ke server. Coba lagi.';
    }
    if (error is SocketException || error is TimeoutException) {
      return 'Tidak dapat terhubung ke server. Periksa koneksi internet.';
    }
    if (error is StateError) {
      return 'Sesi tidak valid. Silakan login ulang.';
    }
    if (error is FormatException) {
      return 'Data profil tidak valid.';
    }
    return 'Terjadi kesalahan. Coba lagi.';
  }
}
