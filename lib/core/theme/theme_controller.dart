// lib/core/theme/theme_controller.dart
import 'package:flutter/material.dart';
import 'brand.dart';
import 'theme_prefs.dart';

class ThemeController extends ChangeNotifier {
  AppThemeStyle _style = AppThemeStyle.zenWood;
  AppThemeStyle get style => _style;

  ThemeController() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      restore();
    });
  }

  Future<void> restore() async {
    final savedStyle = await ThemePrefs.load();
    if (savedStyle != null) {
      _style = savedStyle;
      notifyListeners();
    }
  }

  Future<void> setStyle(AppThemeStyle nextStyle) async {
    if (_style == nextStyle) return;
    _style = nextStyle;
    notifyListeners();
    await ThemePrefs.save(nextStyle);
  }
  
  ThemeData get themeData => Brand.getTheme(_style);
}