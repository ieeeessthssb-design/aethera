import 'package:flutter/material.dart';

/// AETHERA design tokens and shared Material component defaults.
class AppTheme {
  static const Color forestGreen = Color(0xFF205C40);
  static const Color mintGreen = Color(0xFFEAF4EC);
  static const Color limeGreen = Color(0xFFB6DC70);
  static const Color lightSurface = Color(0xFFFFFDF8);
  static const Color lightBackground = Color(0xFFF8FAF6);
  static const Color lightBorder = Color(0xFFE2E9E1);
  static const Color darkSurface = Color(0xFF10271D);
  static const Color darkBackground = Color(0xFF0B1E15);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: forestGreen,
      brightness: Brightness.light,
      surface: lightSurface,
    ),
    scaffoldBackgroundColor: lightBackground,
    cardColor: Colors.white,
    textTheme: Typography.material2021().black.apply(
      bodyColor: const Color(0xFF26352B),
      displayColor: const Color(0xFF26352B),
    ),
    fontFamily: 'Tajawal',
    appBarTheme: const AppBarTheme(
      backgroundColor: lightBackground,
      foregroundColor: forestGreen,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(fontFamily: 'Tajawal', fontSize: 20, fontWeight: FontWeight.w800, color: forestGreen),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(18)), side: BorderSide(color: lightBorder)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      labelStyle: const TextStyle(color: Color(0xFF4C5B52)),
      hintStyle: const TextStyle(color: Color(0xFF5C6A61)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: lightBorder)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: lightBorder)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: forestGreen, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13))),
    outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13))),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: limeGreen,
      brightness: Brightness.dark,
      surface: darkSurface,
    ),
    scaffoldBackgroundColor: darkBackground,
    cardColor: const Color(0xFF173629),
    textTheme: Typography.material2021().white.apply(
      bodyColor: const Color(0xFFE5EEE8),
      displayColor: const Color(0xFFE5EEE8),
    ),
    fontFamily: 'Tajawal',
    appBarTheme: const AppBarTheme(backgroundColor: darkBackground, foregroundColor: limeGreen, elevation: 0),
    cardTheme: CardThemeData(color: const Color(0xFF173629), elevation: 1, margin: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(18)))),
    inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: const Color(0xFF173629), labelStyle: const TextStyle(color: Color(0xFFC1D1C5)), hintStyle: const TextStyle(color: Color(0xFFB5C5BA)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13)),
  );
}
