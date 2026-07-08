// lib/core/theme/theme_prefs.dart
import 'package:amitabha/storage/json_prefs_file.dart';
import 'brand.dart';

class ThemePrefs {
  static final _file = JsonPrefsFile('theme');

  static Future<void> save(AppThemeStyle style) =>
      _file.write({'theme_style': style.name});

  static Future<AppThemeStyle?> load() async {
    final j = await _file.read();
    final value = j?['theme_style'] as String?;
    if (value == null) return null;
    try {
      return AppThemeStyle.values.firstWhere((e) => e.name == value);
    } catch (_) {
      return null;
    }
  }
}
