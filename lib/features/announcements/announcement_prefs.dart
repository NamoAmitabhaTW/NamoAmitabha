// lib/features/announcements/announcement_prefs.dart
import 'package:amitabha/storage/json_prefs_file.dart';

class AnnouncementPrefs {
  static final _read = JsonPrefsFile('announcement_read');
  static final _bodyVersions = JsonPrefsFile('announcement_body_versions');

  static Future<Map<String, int>> loadRead() => _loadIntMap(_read);

  static Future<void> saveRead(Map<String, int> versions) =>
      _read.write(versions.map((k, v) => MapEntry(k, v)));

  static Future<Map<String, int>> loadBodyVersions() =>
      _loadIntMap(_bodyVersions);

  static Future<void> saveBodyVersion(String id, int version) async {
    final map = await loadBodyVersions();
    map[id] = version;
    await _bodyVersions.write(map.map((k, v) => MapEntry(k, v)));
  }

  static Future<Map<String, int>> _loadIntMap(JsonPrefsFile f) async {
    final j = await f.read();
    if (j == null) return {};
    return j.map((k, v) => MapEntry(k, (v as num).toInt()));
  }
}
