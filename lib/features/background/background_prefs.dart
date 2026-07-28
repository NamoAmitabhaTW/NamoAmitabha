// amitabha/lib/features/background/background_prefs.dart
import 'package:amitabha/features/background/background_item.dart';
import 'package:amitabha/storage/json_prefs_file.dart';

class BackgroundPrefs {

  static final _active = JsonPrefsFile('background');

  static Future<void> saveActive(
    String id,
    BackgroundType type,
    int revision,
  ) => _active.write({'activeId': id, 'type': type.name, 'revision': revision});

  
  static Future<Map<String, dynamic>?> loadActive() => _active.read();

  static final _versions = JsonPrefsFile('background_versions');

  static Future<Map<String, int>> loadVersions() async {
    final j = await _versions.read();
    if (j == null) return {};
    return j.map((k, v) => MapEntry(k, (v as num).toInt()));
  }

  static Future<void> saveVersion(String id, int version) async {
    final map = await loadVersions();
    map[id] = version;
    await _versions.write(map);
  }

  static Future<void> removeVersion(String id) async {
    final map = await loadVersions();
    map.remove(id);
    await _versions.write(map);
  }
}
