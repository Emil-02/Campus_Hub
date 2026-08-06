import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Builds application themes from the CampusMate design system
/// (docs/03_DESIGN_SYSTEM.md).
abstract final class AppTheme {
  static ThemeData light() => _build(_lightColorScheme);

  static ThemeData dark() => _build(_darkColorScheme);

  static final ColorScheme _lightColorScheme =
      ColorScheme.fromSeed(seedColor: const Color(0xFF006874)).copyWith(
        primary: const Color(0xFF006874),
        onPrimary: Colors.white,
        primaryContainer: const Color(0xFF97F0FF),
        onPrimaryContainer: const Color(0xFF001F24),
        secondary: const Color(0xFF4A6267),
        onSecondary: Colors.white,
        secondaryContainer: const Color(0xFFCDE7ED),
        tertiary: const Color(0xFF525E7D),
        surface: const Color(0xFFFAFDFF),
        surfaceContainerHighest: const Color(0xFFDBE4E6),
        error: const Color(0xFFBA1A1A),
        outline: const Color(0xFF6F797A),
      );

  static final ColorScheme _darkColorScheme =
      ColorScheme.fromSeed(
        seedColor: const Color(0xFF006874),
        brightness: Brightness.dark,
      ).copyWith(
        primary: const Color(0xFF4FD8EB),
        onPrimary: const Color(0xFF00363D),
        primaryContainer: const Color(0xFF004F58),
        onPrimaryContainer: const Color(0xFF97F0FF),
        secondary: const Color(0xFFB1CBD0),
        onSecondary: const Color(0xFF1C3438),
        secondaryContainer: const Color(0xFF334B4F),
        surface: const Color(0xFF191C1D),
        surfaceContainerHighest: const Color(0xFF3F484A),
        error: const Color(0xFFFFB4AB),
        outline: const Color(0xFF899294),
      );

  static ThemeData _build(ColorScheme colorScheme) {
    final base = ThemeData(useMaterial3: true, colorScheme: colorScheme);
    final textTheme = GoogleFonts.interTextTheme(base.textTheme).copyWith(
      headlineLarge: GoogleFonts.inter(
        textStyle: base.textTheme.headlineLarge,
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: GoogleFonts.inter(
        textStyle: base.textTheme.headlineMedium,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: GoogleFonts.inter(
        textStyle: base.textTheme.headlineSmall,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: GoogleFonts.inter(
        textStyle: base.textTheme.titleLarge,
        fontWeight: FontWeight.w500,
      ),
    );

    return base.copyWith(
      textTheme: textTheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 2,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
      ),
      cardTheme: base.cardTheme.copyWith(
        elevation: 0,
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: const StadiumBorder(),
          textStyle: textTheme.labelLarge,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: const StadiumBorder(),
          elevation: 0,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: const StadiumBorder(),
          side: BorderSide(color: colorScheme.outline),
          foregroundColor: colorScheme.primary,
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: colorScheme.primary,
          textStyle: textTheme.labelLarge,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        elevation: 3,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.error),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        showDragHandle: true,
      ),
      dialogTheme: base.dialogTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      listTileTheme: base.listTileTheme.copyWith(
        iconColor: colorScheme.onSurfaceVariant,
      ),
      dividerTheme: DividerThemeData(color: colorScheme.outlineVariant),
    );
  }
}
