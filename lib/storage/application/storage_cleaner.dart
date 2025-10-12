// lib/storage/application/storage_cleaner.dart
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:amitabha/storage/app_paths.dart';

class StorageCleaner {
  Future<void> purgeAllLocal({bool keepModels = true}) async {
    final root = await AppPaths.root();
    final dataDir = Directory(p.join(root.path, 'data'));

    if (await dataDir.exists()) {
      await dataDir.delete(recursive: true);
    }

    if (!keepModels) {
      if (await root.exists()) {
        await root.delete(recursive: true);
      }
    }
  }
}
