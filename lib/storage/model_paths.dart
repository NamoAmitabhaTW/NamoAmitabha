//amitabha/lib/storage/model_paths.dart
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ModelPaths {
  static Future<Directory> root() async {
    final sup = await getApplicationSupportDirectory();
    final dir = Directory(p.join(sup.path, 'amitabha', 'models'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static Future<File> archiveFile(String modelName) async {
    final cache = await getTemporaryDirectory();
    final f = File(p.join(cache.path, '$modelName.tar.bz2'));
    return f;
  }

  static Future<Directory> modelDir(String modelName) async {
    final r = await root();
    final d = Directory(p.join(r.path, modelName));
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }
}