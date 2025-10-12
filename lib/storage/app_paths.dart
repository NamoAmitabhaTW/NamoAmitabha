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
}