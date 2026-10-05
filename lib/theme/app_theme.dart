import 'package:flutter/material.dart';

class AppTheme {
  static const seed = Color(0xFF168C7A);
  static ThemeData get light => _theme(Brightness.light);
  static ThemeData get dark => _theme(Brightness.dark);
  static ThemeData _theme(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      scaffoldBackgroundColor: scheme.surface,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
        filled: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      cardTheme: const CardThemeData(margin: EdgeInsets.zero, elevation: 0),
      appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
    );
  }
}
