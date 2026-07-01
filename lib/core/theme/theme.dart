import 'package:flutter/material.dart';

class ReceiptoTheme {
  // Brand Colors
  static const Color backgroundDark = Color(0xff050816);
  static const Color backgroundMedium = Color(0xff070B18);
  static const Color backgroundLight = Color(0xff0B1022);

  static const Color primary = Color(0xff6C63FF);
  static const Color secondary = Color(0xff00E5FF);
  static const Color accent = Color(0xffFF5ACD);
  static const Color highlight = Color(0xff9EFFA9);
  static const Color warning = Color(0xffFFC857);
  static const Color error = Color(0xffFF4D6D);

  static const Color glassWhite = Color(0x14FFFFFF); // rgba(255,255,255,0.08)
  static const Color glassBorder = Color(0x2EFFFFFF); // rgba(255,255,255,0.18)

  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xffB0B5C6);
  static const Color textMuted = Color(0xff606580);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundDark,
      primaryColor: primary,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        tertiary: accent,
        surface: backgroundMedium,
        error: error,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.w900,
          letterSpacing: -1.0,
        ),
        headlineLarge: TextStyle(
          color: textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
        bodyLarge: TextStyle(
          color: textSecondary,
          fontSize: 16,
          fontWeight: FontWeight.normal,
        ),
        bodyMedium: TextStyle(
          color: textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
        labelLarge: TextStyle(
          color: textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
