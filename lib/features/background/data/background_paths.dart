// lib/features/background/data/background_paths.dart
import 'dart:io';
import 'package:amitabha/core/infrastructure/app_paths.dart';
import 'package:path/path.dart' as p;

class BackgroundPaths {
  const BackgroundPaths._();

  static Future<Directory> dir() async {
    final base = await AppPaths.cacheRoot();
    final dir = Directory(p.join(base.path, 'backgrounds'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static Future<File> file(String id, String ext) async {
    final d = await dir();
    return File(p.join(d.path, '$id.$ext'));
  }
}
