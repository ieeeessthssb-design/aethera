import 'package:flutter/material.dart';

import 'colors.dart';

const List<String> kFontFallback = ['NotoArabic'];

double _lh(double size) {
  // Tailwind default line-heights.
  final m = {
    12.0: 16.0,
    14.0: 20.0,
    16.0: 24.0,
    18.0: 28.0,
    20.0: 28.0,
    24.0: 32.0,
    30.0: 36.0,
    36.0: 40.0
  };
  final v = m[size];
  return v != null ? v / size : 1.25;
}

/// Body text (Figtree).
TextStyle body(
        {double size = 16,
        FontWeight w = FontWeight.w400,
        Color color = AppColors.foreground,
        double? height,
        double? letterSpacing,
        TextDecoration? decoration,
        FontStyle? style}) =>
    TextStyle(
        fontFamily: 'Figtree',
        fontFamilyFallback: kFontFallback,
        fontSize: size,
        fontWeight: w,
        color: color,
        height: height ?? _lh(size),
        letterSpacing: letterSpacing,
        decoration: decoration,
        fontStyle: style);

/// Headings / numbers (Bricolage Grotesque, tracking -0.02em like the web app).
TextStyle display(
        {double size = 24,
        FontWeight w = FontWeight.w700,
        Color color = AppColors.foreground,
        double? height}) =>
    TextStyle(
        fontFamily: 'Bricolage',
        fontFamilyFallback: kFontFallback,
        fontSize: size,
        fontWeight: w,
        color: color,
        height: height ?? _lh(size),
        letterSpacing: size * -0.02);

ThemeData buildTheme({bool arabic = false}) {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary).copyWith(
      primary: AppColors.primary,
      onPrimary: AppColors.primaryForeground,
      secondary: AppColors.secondary,
      onSecondary: AppColors.secondaryForeground,
      surface: AppColors.card,
      onSurface: AppColors.foreground,
      error: AppColors.destructive,
      onError: AppColors.destructiveForeground,
      outline: AppColors.border,
    ),
    scaffoldBackgroundColor: AppColors.background,
    canvasColor: AppColors.background,
    fontFamily: arabic ? 'NotoArabic' : 'Figtree',
    fontFamilyFallback: kFontFallback,
    splashFactory: InkRipple.splashFactory,
    dividerColor: AppColors.border,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
        bodyColor: AppColors.foreground,
        displayColor: AppColors.foreground,
        fontFamily: arabic ? 'NotoArabic' : 'Figtree'),
    textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.primary,
        selectionHandleColor: AppColors.primary),
  );
}
