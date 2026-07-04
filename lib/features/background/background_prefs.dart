// amitabha/lib/features/background/background_prefs.dart
import 'dart:io';
import 'dart:convert';
import 'package:amitabha/storage/app_paths.dart';
import 'package:amitabha/features/background/background_item.dart';
import 'package:path/path.dart' as p;

class BackgroundPrefs {
  // ── 使用中背景描述 ──

  static Future<File> _activeFile() async {
    final root = await AppPaths.root();
    final f = File(p.join(root.path, 'settings', 'background.json'));
    await f.parent.create(recursive: true);
    return f;
  }

  static Future<void> saveActive(
      String id, BackgroundType type, int revision) async {
    final f = await _activeFile();
    await f.writeAsString(
      jsonEncode({'activeId': id, 'type': type.name, 'revision': revision}),
      flush: true,
    );
  }

  /// 回傳 {activeId, type, revision};找不到回 null。
  static Future<Map<String, dynamic>?> loadActive() async {
    final f = await _activeFile();
    if (!await f.exists()) return null;
    try {
      final j = jsonDecode(await f.readAsString());
      return j is Map<String, dynamic> ? j : null;
    } catch (_) {
      return null;
    }
  }

  // ── 已下載背景的內容版本記錄({id: version}),用於偵測是否需更新 ──

  static Future<File> _versionsFile() async {
    final root = await AppPaths.root();
    final f = File(p.join(root.path, 'settings', 'background_versions.json'));
    await f.parent.create(recursive: true);
    return f;
  }

  static Future<Map<String, int>> loadVersions() async {
    final f = await _versionsFile();
    if (!await f.exists()) return {};
    try {
      final j = jsonDecode(await f.readAsString());
      if (j is Map<String, dynamic>) {
        return j.map((k, v) => MapEntry(k, (v as num).toInt()));
      }
    } catch (_) {}
    return {};
  }

  static Future<void> saveVersion(String id, int version) async {
    final map = await loadVersions();
    map[id] = version;
    final f = await _versionsFile();
    await f.writeAsString(jsonEncode(map), flush: true);
  }

  static Future<void> removeVersion(String id) async {
    final map = await loadVersions();
    map.remove(id);
    final f = await _versionsFile();
    await f.writeAsString(jsonEncode(map), flush: true);
  }
}