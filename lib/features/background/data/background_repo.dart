// lib/features/background/data/background_repo.dart
import 'dart:convert';
import 'dart:io';
import 'package:amitabha/core/infrastructure/app_paths.dart';
import 'package:amitabha/core/infrastructure/atomic_io.dart';
import 'package:amitabha/features/background/data/background_paths.dart';
import 'package:amitabha/features/background/domain/background_item.dart';
import 'package:amitabha/features/background/domain/background_ports.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

class HttpBackgroundRepository implements BackgroundRepository {
  static const String manifestUrl =
      'https://cdn.jsdelivr.net/gh/Aaron-Tsai-iosDeveloper/NamoAmitabha@main/app-backgrounds/manifest.json';

  final Map<String, http.Client> _clients = {};

  Future<File> _manifestCacheFile() async {
    final root = await AppPaths.root();
    final f = File(p.join(root.path, 'settings', 'background_manifest.json'));
    await f.parent.create(recursive: true);
    return f;
  }

  @override
  Future<List<BackgroundItem>> fetchManifest() async {
    final res = await http.get(Uri.parse(manifestUrl));
    if (res.statusCode != 200) {
      throw HttpException('manifest HTTP ${res.statusCode}');
    }
    final raw = utf8.decode(res.bodyBytes);
    final data = jsonDecode(raw) as List<dynamic>;
    final items = data
        .map((e) => BackgroundItem.fromJson(e as Map<String, dynamic>))
        .toList();
    try {
      final f = await _manifestCacheFile();
      await atomicWriteJson(f, data);
    } catch (_) {}
    return items;
  }

  @override
  Future<List<BackgroundItem>> loadCachedManifest() async {
    try {
      final f = await _manifestCacheFile();
      if (!await f.exists()) return [];
      final data = jsonDecode(await f.readAsString()) as List<dynamic>;
      return data
          .map((e) => BackgroundItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<File> _downloadTarget(BackgroundItem item) =>
      BackgroundPaths.file(item.id, item.fileExtension);

  @override
  Future<File?> findById(String id) async {
    final dir = await BackgroundPaths.dir();
    if (!await dir.exists()) return null;
    await for (final entry in dir.list()) {
      if (entry is File && p.basenameWithoutExtension(entry.path) == id) {
        return entry;
      }
    }
    return null;
  }

  @override
  Future<bool> isDownloaded(BackgroundItem item) async =>
      await findById(item.id) != null;

  @override
  Future<void> download(
    BackgroundItem item, {
    required void Function(double progress) onProgress,
  }) async {
    final file = await _downloadTarget(item);
    final client = http.Client();
    _clients[item.id] = client;
    IOSink? sink;
    try {
      final req = http.Request('GET', Uri.parse(item.fileUrl));
      final res = await client.send(req);
      if (res.statusCode != 200) {
        throw HttpException('download HTTP ${res.statusCode}');
      }
      final total = res.contentLength ?? item.fileSize;
      var received = 0;
      sink = file.openWrite();
      await for (final chunk in res.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) onProgress(received / total);
      }
      await sink.close();
      sink = null;
    } catch (e) {
      if (sink != null) {
        try {
          await sink.close();
        } catch (_) {}
      }
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }
      rethrow;
    } finally {
      _clients.remove(item.id);
      client.close();
    }
  }

  @override
  void cancelDownload(String id) {
    _clients[id]?.close();
  }

  @override
  Future<void> delete(BackgroundItem item) => deleteById(item.id);

  @override
  Future<void> deleteById(String id) async {
    final dir = await BackgroundPaths.dir();
    if (!await dir.exists()) return;
    await for (final entry in dir.list()) {
      if (entry is File && p.basenameWithoutExtension(entry.path) == id) {
        await entry.delete();
      }
    }
  }

  @override
  Future<BackgroundSource?> sourceFor(BackgroundItem item) async {
    if (item.isBuiltin) {
      return BackgroundSource(
        type: item.type,
        assetPath: item.assetPath,
        revision: item.version,
      );
    }
    final f = await findById(item.id);
    if (f != null) {
      return BackgroundSource(type: item.type, file: f, revision: item.version);
    }
    return null;
  }
}
