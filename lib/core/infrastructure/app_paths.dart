// lib/core/infrastructure/app_paths.dart
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AppPaths {
  const AppPaths._();

  static Future<Directory> root() async {
    final support = await getApplicationSupportDirectory();
    final dir = Directory(p.join(support.path, 'amitabha'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static Future<Directory> dataRoot() async {
    final r = await root();
    final d = Directory(p.join(r.path, 'data'));
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  static Future<Directory> cacheRoot() async {
    final base = await getApplicationCacheDirectory();
    final dir = Directory(p.join(base.path, 'amitabha'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }
}
