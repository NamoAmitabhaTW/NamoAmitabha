// 背景偏好持久化(使用中背景描述 + 已下載版本)
// amitabha/lib/features/background/background_prefs.dart
//
// 寫法對齊 locale_prefs.dart:寫 JSON 檔到 AppPaths.root()/settings/。
// 注意:這些檔在 Support 目錄,不在 Caches —— 即使影片快取被系統清掉,
// 「使用者選過哪個背景」與版本記錄都不會丟。
//
// background.json          : {activeId, type, revision} 使用中背景的描述
//   (連 type 與 revision 一起存,讓下次啟動能「離線、免 manifest」快速還原背景)
// background_versions.json : {id: version} 各已下載背景的內容版本
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