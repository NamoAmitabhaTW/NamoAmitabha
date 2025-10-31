// lib/core/theme/brand.dart
import 'package:flutter/material.dart';

class Brand {
  static const cream = Color(0xFFFFF8E7);
  static const seed  = Color(0xFF8C6A3F);

  static ThemeData light() {
    final base = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
      contrastLevel: .5,
    );

    final scheme = base.copyWith(
      surface: cream,
      surfaceContainerLowest: cream,
      surfaceContainerLow: cream,
      surfaceContainer: cream,
      surfaceContainerHigh: cream,
      surfaceContainerHighest: cream,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: cream,
      canvasColor: cream,

      appBarTheme: const AppBarTheme(surfaceTintColor: Colors.transparent),
      cardTheme: const CardThemeData(surfaceTintColor: Colors.transparent),
      dialogTheme: const DialogThemeData(surfaceTintColor: Colors.transparent),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: cream,
        surfaceTintColor: Colors.transparent,
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: cream,
        surfaceTintColor: Colors.transparent,
      ),
      bottomAppBarTheme:
          const BottomAppBarThemeData(surfaceTintColor: Colors.transparent),
    );
  }

  static ThemeData darkSameCream() {
    final base = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    );

    final scheme = base.copyWith(
      surface: cream,
      surfaceContainerLowest: cream,
      surfaceContainerLow: cream,
      surfaceContainer: cream,
      surfaceContainerHigh: cream,
      surfaceContainerHighest: cream,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: cream,
      canvasColor: cream,

      appBarTheme: const AppBarTheme(surfaceTintColor: Colors.transparent),
      cardTheme: const CardThemeData(surfaceTintColor: Colors.transparent),
      dialogTheme: const DialogThemeData(surfaceTintColor: Colors.transparent),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: cream,
        surfaceTintColor: Colors.transparent,
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: cream,
        surfaceTintColor: Colors.transparent,
      ),
      bottomAppBarTheme:
          const BottomAppBarThemeData(surfaceTintColor: Colors.transparent),
    );
  }
}
