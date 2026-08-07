import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _themeModeKey = 'theme_mode';

/// Provides the persisted theme mode and its toggle (T-156).
final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

/// Loads and persists the light/dark preference.
final class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _restore();
    return ThemeMode.system;
  }

  Future<void> _restore() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final stored = preferences.getString(_themeModeKey);
      final restored = switch (stored) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
      if (restored != state) {
        state = restored;
      }
    } catch (error) {
      debugPrint('Theme restore failed: $error');
    }
  }

  /// Applies and persists [mode].
  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_themeModeKey, switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      });
    } catch (error) {
      debugPrint('Theme persist failed: $error');
    }
  }

  /// Switch-friendly toggle between light and dark.
  Future<void> setDarkEnabled(bool enabled) {
    return setMode(enabled ? ThemeMode.dark : ThemeMode.light);
  }
}
