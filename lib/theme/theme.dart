import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // 1. Color System (Light Theme Tokens)
  static const Color primary = Color(0xFFFF6D00);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFFFDBCB);
  static const Color onPrimaryContainer = Color(0xFF5D2B0E);
  static const Color primaryVariant = Color(0xFFE65100);
  static const Color secondary = Color(0xFF5D2B0E);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFFFDBC8);
  static const Color tertiary = Color(0xFF006D5B);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFB2F1E0);
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color surface = Color(0xFFFFF8F6);
  static const Color onSurface = Color(0xFF1C1B1F);
  static const Color onSurfaceVariant = Color(0xFF52443C);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFFFF1EB);
  static const Color surfaceContainer = Color(0xFFFFE8DB);
  static const Color surfaceContainerHigh = Color(0xFFFFDBC8);
  static const Color outline = Color(0xFF85736B);
  static const Color outlineVariant = Color(0xFFD8C2B6);
  static const Color scrim = Color(0x52000000);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        secondaryContainer: AppColors.secondaryContainer,
        tertiary: AppColors.tertiary,
        onTertiary: AppColors.onTertiary,
        tertiaryContainer: AppColors.tertiaryContainer,
        error: AppColors.error,
        onError: AppColors.onError,
        errorContainer: AppColors.errorContainer,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        onSurfaceVariant: AppColors.onSurfaceVariant,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
        scrim: AppColors.scrim,
      ),
      scaffoldBackgroundColor: AppColors.surface,
      textTheme: GoogleFonts.interTextTheme(
        const TextTheme(
          displayLarge: TextStyle(fontSize: 57, fontWeight: FontWeight.w400, letterSpacing: -0.25),
          headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w400),
          headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
          titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
          bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
          bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
          labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 1,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceContainerLow,
        modalBackgroundColor: AppColors.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
      ),
    );
  }
}
