// lib/core/theme/brand.dart
import 'package:flutter/material.dart';

enum AppThemeStyle {
  zenWood,
  lotusPond,
}

class Brand {
  static const cream = Color(0xFFFFF8E7);
  static const seed  = Color(0xFF8C6A3F);
  static const lotusSeed = Color(0xFF009688); 
  static const lotusSurface = Color(0xFFF0FDF4); 

  // ── 設定頁暖棕色系(原 settings_screen 內的硬編碼常數) ──
  static const settingsBrown = Color(0xFF6F4E37); // 主要暖棕
  static const settingsBrownSoft = Color(0xFF9A7B66); // 副標題 / 箭頭
  static const settingsTitle = Color(0xFF3A2E25); // 標題深棕
  static const settingsCardBg = Color(0xFFFDF8EE); // 暖白卡片,與米底同色溫
  static const settingsIconBg = Color(0x1A6F4E37); // 暖棕 10%,圖示圓底
  static const settingsDivider = Color(0x14000000); // 卡片內分隔線
  static const settingsShadow = Color(0x0A000000); // 卡片陰影
  
  // 新增：取得對應風格的背景裝飾 (BoxDecoration)
  static BoxDecoration getBackgroundDecoration(AppThemeStyle style) {
    switch (style) {
      case AppThemeStyle.zenWood:
        // 禪堂木紋目前維持純色 (或你未來可換成木紋圖片)
        return const BoxDecoration(
          color: cream,
        );
        
      case AppThemeStyle.lotusPond:
        // 蓮花七寶池：琉璃光影漸層
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            // 這裡配置琉璃光澤：從淺青綠過渡到深琉璃藍，中間帶點通透感
            colors: [
              Color(0xFFE0F2F1), // 非常淺的青綠 (反光處)
              Color(0xFF80CBC4), // 中等青琉璃色
              Color(0xFF26A69A), // 深琉璃色
            ],
            stops: [0.0, 0.5, 1.0], // 控制漸層的位置
          ),
        );
    }
  }

  static ThemeData getTheme(AppThemeStyle style) {
    switch (style) {
      case AppThemeStyle.zenWood:
        return light(); // 使用你原本設定的 cream/seed 作為木紋風格
      case AppThemeStyle.lotusPond:
        return _lotusPondTheme(); // 呼叫蓮花風格的主題
    }
  }
  static ThemeData _lotusPondTheme() {
    final base = ColorScheme.fromSeed(
      seedColor: lotusSeed,
      brightness: Brightness.light,
      contrastLevel: .5,
    );

    final scheme = base.copyWith(
      surface: lotusSurface,
      surfaceContainerLowest: lotusSurface,
      surfaceContainerLow: lotusSurface,
      surfaceContainer: lotusSurface,
      surfaceContainerHigh: lotusSurface,
      surfaceContainerHighest: lotusSurface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: lotusSurface,
      canvasColor: lotusSurface,

      appBarTheme: const AppBarTheme(surfaceTintColor: Colors.transparent),
      cardTheme: const CardThemeData(surfaceTintColor: Colors.transparent),
      dialogTheme: const DialogThemeData(surfaceTintColor: Colors.transparent),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: lotusSurface,
        surfaceTintColor: Colors.transparent,
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: lotusSurface,
        surfaceTintColor: Colors.transparent,
      ),
      bottomAppBarTheme:
          const BottomAppBarThemeData(surfaceTintColor: Colors.transparent),
    );
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
