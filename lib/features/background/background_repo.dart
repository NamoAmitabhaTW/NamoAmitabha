// amitabha/lib/features/background/background_repo.dart
import 'dart:convert';
import 'dart:io';

import 'package:amitabha/features/background/background_item.dart';
import 'package:amitabha/storage/app_paths.dart';
import 'package:amitabha/storage/atomic_io.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

class BackgroundRepo {
  // 遠端 manifest(JSON 清單);更新素材時記得發新 tag 並同步這裡的版號。
  // 帳號務必全小寫。
  static const String manifestUrl =
      'https://cdn.jsdelivr.net/gh/Aaron-Tsai-iosDeveloper/NamoAmitabha@main/app-backgrounds/manifest.json';

  final Map<String, http.Client> _clients = {};

  // ── manifest 本地快取(放 Support,離線重建清單用) ──
  Future<File> _manifestCacheFile() async {
    final root = await AppPaths.root();
    final f = File(p.join(root.path, 'settings', 'background_manifest.json'));
    await f.parent.create(recursive: true);
    return f;
  }

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
    // 成功解析後才覆寫快取,避免壞資料蓋掉上次的好資料;
    // 原子寫入,寫到一半中斷也不會留下半套快取
    try {
      final f = await _manifestCacheFile();
      await atomicWriteJson(f, data);
    } catch (_) {}
    return items;
  }

  /// 讀上次成功抓到的 manifest 快取;沒有或解析失敗回 []。
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

  Future<File> fileFor(BackgroundItem item) =>
      AppPaths.background(item.id, item.ext);

  Future<File> fileForRaw(String id, BackgroundType type) =>
      AppPaths.background(id, type == BackgroundType.image ? 'jpg' : 'mp4');

  Future<bool> isDownloaded(BackgroundItem item) async {
    final f = await fileFor(item);
    return f.exists();
  }

  Future<void> download(
    BackgroundItem item, {
    required void Function(double progress) onProgress,
  }) async {
    final file = await fileFor(item);
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

  /// 中斷進行中的下載(關閉連線會讓上面的 await for 丟例外)。
  void cancelDownload(String id) {
    _clients[id]?.close();
  }

  Future<void> delete(BackgroundItem item) async {
    final f = await fileFor(item);
    if (await f.exists()) await f.delete();
  }

  /// 給 ChantingBackground 用:回傳目前該播的來源(asset 或本地檔)。
  Future<BackgroundSource?> sourceFor(BackgroundItem item) async {
    if (item.isBuiltin) {
      return BackgroundSource(
        type: item.type,
        assetPath: item.assetPath,
        revision: item.version,
      );
    }
    final f = await fileFor(item);
    if (await f.exists()) {
      return BackgroundSource(type: item.type, file: f, revision: item.version);
    }
    return null;
  }
}
