// lib/core/theme/brand.dart
import 'package:flutter/material.dart';

enum AppThemeStyle {
  zenWood,
}

class Brand {
  static const cream = Color(0xFFFFF8E7);
  static const seed  = Color(0xFF8C6A3F);
  static const settingsBrown = Color(0xFF6F4E37); // 主要暖棕
  static const settingsBrownSoft = Color(0xFF9A7B66); // 副標題 / 箭頭
  static const settingsTitle = Color(0xFF3A2E25); // 標題深棕
  static const settingsCardBg = Color(0xFFFDF8EE); // 暖白卡片,與米底同色溫
  static const settingsIconBg = Color(0x1A6F4E37); // 暖棕 10%,圖示圓底
  static const settingsDivider = Color(0x14000000); // 卡片內分隔線
  static const settingsShadow = Color(0x0A000000); // 卡片陰影
  
  static BoxDecoration getBackgroundDecoration(AppThemeStyle style) {
    switch (style) {
      case AppThemeStyle.zenWood:
        return const BoxDecoration(
          color: cream,
        );
    }
  }

  static ThemeData getTheme(AppThemeStyle style) {
    switch (style) {
      case AppThemeStyle.zenWood:
        return light(); 
    }
  }

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
