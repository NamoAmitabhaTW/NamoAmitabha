//amitabha/lib/storage/app_paths.dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class AppPaths {
  static Future<Directory> root() async {
    final doc = await getApplicationSupportDirectory();
    final dir = Directory(p.join(doc.path, 'amitabha'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static Future<Directory> dataRoot() async {
    final r = await root();
    final d = Directory(p.join(r.path, 'data'));
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  static Future<File> sessionSnapshot(String sessionId) async {
    final r = await root();
    final file = File(p.join(r.path, 'data', 'sessions', '$sessionId.json'));
    await file.parent.create(recursive: true);
    return file;
  }

  static Future<File> sessionHits(String sessionId, {int part = 1}) async {
    final r = await root();
    final file = File(p.join(r.path, 'data', 'sessions', '$sessionId-hits-$part.ndjson'));
    await file.parent.create(recursive: true);
    return file;
  }

  static Future<File> daily(String yyyymmdd) async {
    final r = await root();
    final file = File(p.join(r.path, 'data', 'daily', '$yyyymmdd.json'));
    await file.parent.create(recursive: true);
    return file;
  }

  // ── 新增:背景素材 ──────────────────────────────────────────
  // 背景影片/圖片是「可從遠端重新下載」的素材,放 Caches:
  //  - iOS 不納入 iCloud 備份,符合審查規範(可重下載資料不該被備份)
  //  - 系統空間吃緊時可能被清掉 → 已有「檔案不在就退回預設 + 可重抓」的 fallback
  static Future<File> background(String id, String ext) async {
    final base = await getApplicationCacheDirectory();
    final file = File(p.join(base.path, 'amitabha', 'backgrounds', '$id.$ext'));
    await file.parent.create(recursive: true);
    return file;
  }
}