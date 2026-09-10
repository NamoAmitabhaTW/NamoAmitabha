// lib/features/background/domain/background_ports.dart
import 'dart:io';
import 'package:amitabha/features/background/domain/background_item.dart';

abstract class BackgroundRepository {
  Future<List<BackgroundItem>> fetchManifest();

  Future<List<BackgroundItem>> loadCachedManifest();

  Future<File?> findById(String id);

  Future<bool> isDownloaded(BackgroundItem item);

  Future<void> download(
    BackgroundItem item, {
    required void Function(double progress) onProgress,
  });

  void cancelDownload(String id);

  Future<void> delete(BackgroundItem item);

  Future<void> deleteById(String id);

  Future<BackgroundSource?> sourceFor(BackgroundItem item);
}

abstract class BackgroundPreferences {
  Future<void> saveActive(String id, BackgroundType type, int revision);

  Future<Map<String, dynamic>?> loadActive();

  Future<Map<String, int>> loadVersions();

  Future<void> saveVersion(String id, int version);

  Future<void> removeVersion(String id);
}
