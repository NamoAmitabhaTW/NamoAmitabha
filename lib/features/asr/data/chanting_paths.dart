// lib/features/asr/data/chanting_paths.dart
import 'dart:io';
import 'package:amitabha/core/infrastructure/app_paths.dart';
import 'package:path/path.dart' as p;

class ChantingPaths {
  const ChantingPaths._();

  static Future<Directory> sessionsDir() async {
    final root = await AppPaths.dataRoot();
    return Directory(p.join(root.path, 'sessions'));
  }

  static Future<File> sessionSnapshot(String sessionId) async {
    final root = await AppPaths.dataRoot();
    final file = File(p.join(root.path, 'sessions', '$sessionId.json'));
    await file.parent.create(recursive: true);
    return file;
  }

  static Future<File> sessionHits(String sessionId, {int part = 1}) async {
    final root = await AppPaths.dataRoot();
    final file = File(
      p.join(root.path, 'sessions', '$sessionId-hits-$part.ndjson'),
    );
    await file.parent.create(recursive: true);
    return file;
  }

  static Future<Directory> dailyDir() async {
    final root = await AppPaths.dataRoot();
    return Directory(p.join(root.path, 'daily'));
  }

  static Future<File> daily(String yyyymmdd) async {
    final dir = await dailyDir();
    final file = File(p.join(dir.path, '$yyyymmdd.json'));
    await file.parent.create(recursive: true);
    return file;
  }

  static Future<File> dailyIndex() async {
    final root = await AppPaths.dataRoot();
    final file = File(p.join(root.path, 'daily_index.json'));
    await file.parent.create(recursive: true);
    return file;
  }

  static Future<Directory> pendingDir() async {
    final root = await AppPaths.dataRoot();
    return Directory(p.join(root.path, 'pending'));
  }

  static Future<File> pendingCommit(String sessionId) async {
    final dir = await pendingDir();
    final file = File(p.join(dir.path, '$sessionId.json'));
    await file.parent.create(recursive: true);
    return file;
  }
}
