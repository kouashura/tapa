// lib/theme/app_theme.dart

import 'package:flutter/material.dart';

class TAPAColors {
  // Couleurs principales
  static const Color navy = Color(0xFF1F3A5F);
  static const Color gold = Color(0xFFC9A227);
  static const Color goldLight = Color(0xFFFEF3C7); // ✅ AJOUTÉ
  static const Color white = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF5F6FA);
  static const Color surface = Color(0xFFFFFFFF);

  // Couleurs d'état
  static const Color green = Color(0xFF2ECC71);
  static const Color greenLight = Color(0xFFEAFAF1);
  static const Color red = Color(0xFFE74C3C);
  static const Color redLight = Color(0xFFFDEDEC);
  static const Color amber = Color(0xFFF39C12);
  static const Color amberLight = Color(0xFFFEF9E7);
  static const Color purple = Color(0xFF8E44AD);
  static const Color purpleLight = Color(0xFFF4ECF7);

  // Textes
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecond = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);

  // Bordures
  static const Color border = Color(0xFFE5E7EB);
}

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: TAPAColors.navy,
      scaffoldBackgroundColor: TAPAColors.background,
      colorScheme: const ColorScheme.light(
        primary: TAPAColors.navy,
        secondary: TAPAColors.gold,
        surface: TAPAColors.surface,
        error: TAPAColors.red,
        onPrimary: TAPAColors.white,
        onSecondary: TAPAColors.white,
        onSurface: TAPAColors.textPrimary,
        onError: TAPAColors.white,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: TAPAColors.navy,
        foregroundColor: TAPAColors.white,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: TAPAColors.white,
        ),
        iconTheme: IconThemeData(
          color: TAPAColors.white,
          size: 24,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: TAPAColors.navy,
          foregroundColor: TAPAColors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: TAPAColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: TAPAColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: TAPAColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: TAPAColors.gold, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: TAPAColors.red),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: const TextStyle(
          color: TAPAColors.textSecond,
          fontSize: 14,
        ),
        hintStyle: const TextStyle(
          color: TAPAColors.textHint,
          fontSize: 14,
        ),
        prefixIconColor: TAPAColors.textHint,
        suffixIconColor: TAPAColors.textHint,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: TAPAColors.surface,
        margin: const EdgeInsets.all(8),
      ),
      dividerTheme: const DividerThemeData(
        color: TAPAColors.border,
        thickness: 1,
        space: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: TAPAColors.navy,
        contentTextStyle: const TextStyle(
          color: TAPAColors.white,
          fontSize: 14,
        ),
      ),
      dialogTheme: DialogTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: TAPAColors.textPrimary,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 14,
          color: TAPAColors.textSecond,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: TAPAColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
      ),
    );
  }
}
