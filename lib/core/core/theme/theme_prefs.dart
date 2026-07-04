// lib/core/theme/theme_prefs.dart
import 'dart:io';
import 'dart:convert';
import 'package:amitabha/storage/app_paths.dart';
import 'package:path/path.dart' as p;
import 'brand.dart'; 

class ThemePrefs {
  static Future<File> _file() async {
    final root = await AppPaths.root();
    final f = File(p.join(root.path, 'settings', 'theme.json'));
    await f.parent.create(recursive: true);
    return f;
  }

  static Future<void> save(AppThemeStyle style) async {
    final f = await _file();
    final j = jsonEncode({'theme_style': style.name}); 
    await f.writeAsString(j, flush: true);
  }

  static Future<AppThemeStyle?> load() async {
    final f = await _file();
    if (!await f.exists()) return null;
    try {
      final j = jsonDecode(await f.readAsString());
      final value = j['theme_style'] as String?;
      return AppThemeStyle.values.firstWhere((e) => e.name == value);
    } catch (_) {
      return null;
    }
  }
}