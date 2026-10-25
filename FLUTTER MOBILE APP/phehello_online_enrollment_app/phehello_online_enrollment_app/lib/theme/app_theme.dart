//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: app_theme.dart builds the app's overall Material theme (colour scheme, text
// colours, input fields, snack bars, dialogs and progress indicators) from AppColors.

import 'package:flutter/material.dart';

import 'app_colors.dart';

/// AppTheme (class) - static-only theme provider; the private constructor AppTheme._() prevents instances.
class AppTheme {
  AppTheme._();

  /// _border() - private helper that creates a rounded (radius 14) outline border for text fields
  /// in colour 'c' and thickness 'w' (default 1.2).
  static OutlineInputBorder _border(Color c, [double w = 1.2]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c, width: w),
      );

  /// light (getter) - returns the ThemeData for the app (assigned to MaterialApp.theme).
  /// It builds a Material 3 colour scheme seeded from the brand brown (gold secondary, off-white
  /// surface), then customises: the page background; text colours; text-field styling (white fill,
  /// padding, hint/error styles and brown focus border / red error border); floating dark-brown
  /// snack bars with rounded corners; rounded dialogs; and brown progress indicators.
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.brown,
      primary: AppColors.brown,
      secondary: AppColors.gold,
      surface: AppColors.background,
      error: AppColors.error,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: ThemeData.light().textTheme.apply(
        bodyColor: AppColors.textDark,
        displayColor: AppColors.textDark,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        errorStyle: const TextStyle(fontSize: 12, color: AppColors.error),
        border: _border(AppColors.border),
        enabledBorder: _border(AppColors.border),
        focusedBorder: _border(AppColors.brown, 1.6),
        errorBorder: _border(AppColors.error),
        focusedErrorBorder: _border(AppColors.error, 1.6),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.brownDark,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.brown,
      ),
    );
  }
}
