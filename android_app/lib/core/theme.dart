import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF1E3A5F);
  static const Color safe = Color(0xFF27AE60);
  static const Color danger = Color(0xFFE74C3C);
  static const Color suspicious = Color(0xFFF39C12);
  static const Color background = Color(0xFFF8F9FA);
  static const Color textColor = Color(0xFF2C3E50);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: background,
    appBarTheme: const AppBarTheme(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: primary.withValues(alpha: 0.9),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
  );
}
