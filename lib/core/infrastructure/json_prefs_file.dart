// lib/core/infrastructure/json_prefs_file.dart
import 'dart:io';
import 'package:amitabha/core/infrastructure/app_paths.dart';
import 'package:amitabha/core/infrastructure/atomic_io.dart';
import 'package:path/path.dart' as p;

class JsonPrefsFile {
  JsonPrefsFile(this.name);

  final String name;

  Future<File> file() async {
    final root = await AppPaths.root();
    final f = File(p.join(root.path, 'settings', '$name.json'));
    await f.parent.create(recursive: true);
    return f;
  }

  Future<Map<String, dynamic>?> read() async {
    final f = await file();
    if (!await f.exists()) return null;
    final j = await readJsonOrEmpty(f);
    return j.isEmpty ? null : j;
  }

  Future<void> write(Map<String, dynamic> json) async {
    final f = await file();
    await atomicWriteJson(f, json);
  }
}
