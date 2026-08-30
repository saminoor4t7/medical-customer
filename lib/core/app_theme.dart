import 'package:flutter/material.dart';

class AppTheme {
  static const background = Color(0xFF071A33);
  static const surface = Color(0xFF102642);
  static const cardColor = Color(0xFF09243D);
  static const primary = Color(0xFF00B9AB);
  static const primaryBright = Color(0xFF00C7C2);
  static const mutedText = Color(0xFF8D9BB0);
  static const error = Color(0xFFB8404A);
  static const border = Color(0xFF1D3C5B);
  static const accentBackground = Color(0xFF07384D);
  static const accentBorder = Color(0xFF006E70);
  static const topCircle = Color(0xFF0A7778);
  static const bottomCircle = Color(0xFF0B526D);

  static ThemeData get theme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
      surface: surface,
      error: error,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        labelStyle: const TextStyle(color: mutedText),
        prefixIconColor: primary,
        suffixIconColor: mutedText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide.none,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}
