/// Shared validators for the public authentication forms.
abstract final class AuthFormValidators {
  static final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  /// Validates a required email address after trimming surrounding whitespace.
  static String? email(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Email wajib diisi.';
    }
    if (!_emailPattern.hasMatch(email)) {
      return 'Format email tidak valid.';
    }
    return null;
  }

  /// Validates a required password with the minimum supported length.
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password wajib diisi.';
    }
    if (value.length < 8) {
      return 'Password minimal 8 karakter.';
    }
    return null;
  }

  /// Validates a required full name after trimming surrounding whitespace.
  static String? fullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nama lengkap wajib diisi.';
    }
    return null;
  }

  /// Validates that password confirmation is present and matches.
  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Konfirmasi password wajib diisi.';
    }
    if (value != password) {
      return 'Konfirmasi password tidak sama.';
    }
    return null;
  }
}
