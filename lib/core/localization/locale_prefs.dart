//語系持久化
// lib/core/localization/locale_prefs.dart
import 'dart:io';
import 'dart:convert';
import 'package:amitabha/storage/app_paths.dart';
import 'package:path/path.dart' as p;

class LocalePrefs {
  static Future<File> _file() async {
    final root = await AppPaths.root();
    final f = File(p.join(root.path, 'settings', 'locale.json'));
    await f.parent.create(recursive: true);
    return f;
  }

  static Future<void> save(String localeCode) async {
    final f = await _file();
    final j = jsonEncode({'locale': localeCode});
    await f.writeAsString(j, flush: true);
  }

  static Future<String?> load() async {
    final f = await _file();
    if (!await f.exists()) return null;
    try {
      final j = jsonDecode(await f.readAsString());
      final v = j is Map<String, dynamic> ? j['locale'] as String? : null;
      return v;
    } catch (_) {
      return null;
    }
  }
}