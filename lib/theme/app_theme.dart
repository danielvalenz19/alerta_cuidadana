import 'package:flutter/material.dart';

import 'brand_decorations.dart';
import 'tokens.dart';

ThemeData lightTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: Tokens.brand700,
        brightness: Brightness.light,
      ).copyWith(
        primary: Tokens.brand700,
        onPrimary: Colors.white,
        secondary: Tokens.accentCyan,
        onSecondary: Colors.white,
        error: Tokens.danger600,
        onError: Colors.white,
        background: Tokens.lightBackground,
        onBackground: Tokens.lightForeground,
        surface: Tokens.lightSurface,
        onSurface: Tokens.lightText,
        surfaceTint: Tokens.brand700,
      );
  final deco = BrandDecorations.light();

  OutlineInputBorder outline(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: color),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: Tokens.lightBackground,
    cardColor: Tokens.lightSurface,
    dividerColor: Tokens.lightBorder,
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: Tokens.lightHeading,
        fontWeight: FontWeight.w800,
      ),
      headlineMedium: TextStyle(
        color: Tokens.lightHeading,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: TextStyle(
        color: Tokens.lightText,
        fontWeight: FontWeight.w600,
      ),
      bodyMedium: TextStyle(color: Tokens.lightText),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Tokens.lightSurface,
      border: outline(Tokens.lightBorder),
      enabledBorder: outline(Tokens.lightBorder),
      focusedBorder: outline(Tokens.brand600),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Tokens.lightSurface,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 12),
      titleTextStyle: TextStyle(
        fontWeight: FontWeight.w600,
        color: Tokens.lightText,
      ),
      subtitleTextStyle: TextStyle(color: Tokens.lightMuted),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith<Color?>(
        (states) => states.contains(MaterialState.selected)
            ? Colors.white
            : Tokens.lightMuted,
      ),
      trackColor: MaterialStateProperty.resolveWith<Color?>(
        (states) => states.contains(MaterialState.selected)
            ? Tokens.brand700.withOpacity(0.9)
            : Tokens.lightBorder,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      foregroundColor: scheme.onBackground,
      titleTextStyle: const TextStyle(
        color: Tokens.lightHeading,
        fontWeight: FontWeight.w700,
        fontSize: 20,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Tokens.brand700,
      contentTextStyle: const TextStyle(color: Colors.white),
    ),
    extensions: [deco],
  );
}

ThemeData darkTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: const Color(0xFF5FB4DA),
        brightness: Brightness.dark,
      ).copyWith(
        primary: const Color(0xFF5FB4DA),
        onPrimary: const Color(0xFF0B141A),
        secondary: Tokens.accentPurple,
        onSecondary: const Color(0xFFEAF4FA),
        error: const Color(0xFFEF5350),
        onError: const Color(0xFF0B141A),
        background: Tokens.darkBackground,
        onBackground: Tokens.darkForeground,
        surface: Tokens.darkSurface,
        onSurface: Tokens.darkText,
        surfaceTint: const Color(0xFF5FB4DA),
      );
  final deco = BrandDecorations.dark();

  OutlineInputBorder outline(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: color),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: Tokens.darkBackground,
    cardColor: Tokens.darkSurface,
    dividerColor: Tokens.darkBorder,
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: Tokens.darkHeading,
        fontWeight: FontWeight.w800,
      ),
      headlineMedium: TextStyle(
        color: Tokens.darkHeading,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: TextStyle(
        color: Tokens.darkText,
        fontWeight: FontWeight.w600,
      ),
      bodyMedium: TextStyle(color: Tokens.darkText),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Tokens.darkSurface,
      border: outline(Tokens.darkBorder),
      enabledBorder: outline(Tokens.darkBorder),
      focusedBorder: outline(const Color(0xFF5FB4DA)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Tokens.darkSurface,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 12),
      titleTextStyle: TextStyle(
        fontWeight: FontWeight.w600,
        color: Tokens.darkText,
      ),
      subtitleTextStyle: TextStyle(color: Tokens.darkMuted),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith<Color?>(
        (states) => states.contains(MaterialState.selected)
            ? Tokens.darkBackground
            : Tokens.darkMuted,
      ),
      trackColor: MaterialStateProperty.resolveWith<Color?>(
        (states) => states.contains(MaterialState.selected)
            ? Tokens.accentPurple.withOpacity(0.7)
            : Tokens.darkBorder,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      foregroundColor: scheme.onBackground,
      titleTextStyle: const TextStyle(
        color: Tokens.darkHeading,
        fontWeight: FontWeight.w700,
        fontSize: 20,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Tokens.darkSurface,
      contentTextStyle: const TextStyle(color: Tokens.darkForeground),
    ),
    extensions: [deco],
  );
}
