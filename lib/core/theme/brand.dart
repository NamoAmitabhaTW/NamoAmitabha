// lib/core/theme/brand.dart
import 'package:flutter/material.dart';

enum AppThemeStyle { zenWood }

class Brand {
  static const cream = Color(0xFFFFF8E7);
  static const seed = Color(0xFF8C6A3F);
  static const settingsBrown = Color(0xFF6F4E37);
  static const settingsBrownSoft = Color(0xFF9A7B66);
  static const settingsTitle = Color(0xFF3A2E25);
  static const settingsCardBg = Color(0xFFFDF8EE);
  static const settingsIconBg = Color(0x1A6F4E37);
  static const settingsDivider = Color(0x14000000);
  static const settingsShadow = Color(0x0A000000);
  static const settingsGold = Color(0xFF8A6320);
  static const yamabuki = Color(0xFFC99833);
  static const amitabhaInk = Color(0xFF5A4735);

  static const lxgwWenkaiTc = 'LxgwWenkaiTC';

  static const kleeOne = 'KleeOne';

  static const notoSerifTc = 'NotoSerifTC';

  static const cjkFallback = <String>[lxgwWenkaiTc];

  static String primaryFontFor(Locale locale) =>
      locale.languageCode == 'vi' ? lxgwWenkaiTc : kleeOne;

  static String settingsFontFor(Locale locale) => primaryFontFor(locale);

  static Widget withFontFamily(
    BuildContext context,
    Widget child, {
    String family = lxgwWenkaiTc,
    List<String>? fallback,
  }) {
    final base = Theme.of(context);
    return Theme(
      data: base.copyWith(
        textTheme: base.textTheme.apply(
          fontFamily: family,
          fontFamilyFallback: fallback,
        ),
        primaryTextTheme: base.primaryTextTheme.apply(
          fontFamily: family,
          fontFamilyFallback: fallback,
        ),
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(fontFamily: family, fontFamilyFallback: fallback),
        child: child,
      ),
    );
  }

  static BoxDecoration getBackgroundDecoration(AppThemeStyle style) {
    switch (style) {
      case AppThemeStyle.zenWood:
        return const BoxDecoration(color: cream);
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
      bottomAppBarTheme: const BottomAppBarThemeData(
        surfaceTintColor: Colors.transparent,
      ),
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
      bottomAppBarTheme: const BottomAppBarThemeData(
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}
