// lib/presentation/themes/app_theme.dart

import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData getTheme() {
    return ThemeData(
      // Properti lain tetap sama...
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.deepPurple,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 2,
      ),

      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
    );
  }
}
