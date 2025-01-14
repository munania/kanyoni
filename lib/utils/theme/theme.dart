import 'package:flutter/material.dart';

class AppTheme {
  static const double cornerRadius = 8.0;

  // Updated Colors for Dark Theme
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF2E3532),
    secondaryHeaderColor: const Color(0xFFE4572E),
    scaffoldBackgroundColor: const Color(0xFF2E3532),
    appBarTheme: AppBarTheme(backgroundColor: const Color(0xFF2E3532)),
  );

  // Updated Colors for Light Theme
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: const Color(0xFFF2F7F2),
    secondaryHeaderColor: const Color(0xFFE4572E),
    scaffoldBackgroundColor: const Color(0xFFF2F7F2),
    appBarTheme: AppBarTheme(backgroundColor: const Color(0xFFF2F7F2)),
  );

  // Custom Colors for Music App
  static const Color nowPlayingLight = Color(0xFFF2F7F2);
  static const Color nowPlayingDark = Color(0xFF2E3532);
  static const Color playerControlsLight = Color(0xFFFF8C00);
  static const Color playerControlsDark = Color(0xFFFF8C00);
  static const Color progressBarLight = Color(0xFFFF007F);
  static const Color progressBarDark = Color(0xFFFF007F);

  // Text Styles
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.25,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
  );
}
