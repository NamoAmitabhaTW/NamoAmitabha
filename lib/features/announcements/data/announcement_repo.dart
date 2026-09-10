// lib/features/announcements/data/announcement_repo.dart
import 'dart:convert';
import 'dart:io';
import 'package:amitabha/core/assets/app_assets.dart';
import 'package:amitabha/core/infrastructure/app_paths.dart';
import 'package:amitabha/core/infrastructure/atomic_io.dart';
import 'package:amitabha/features/announcements/domain/announcement_item.dart';
import 'package:amitabha/features/announcements/domain/announcement_ports.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

class GithubAnnouncementRepository implements AnnouncementRepository {
  const GithubAnnouncementRepository({this.localOnly = false});

  @override
  final bool localOnly;

  static const String _base =
      'https://raw.githubusercontent.com/Aaron-Tsai-iosDeveloper/NamoAmitabha/main/app-announcements';

  static String get manifestUrl => '$_base/manifest.json';

  static String bodyUrl(String id, String lang) => '$_base/$id/$lang.md';

  static const String _assetManifest = AppAssets.announcementManifest;
  static String _assetBody(String id, String lang) =>
      AppAssets.announcementBody(id, lang);

  Future<File> _manifestCacheFile() async {
    final root = await AppPaths.root();
    return File(p.join(root.path, 'announcements', 'manifest.json'));
  }

  Future<File> _bodyCacheFile(String id, String lang) async {
    final root = await AppPaths.root();
    return File(p.join(root.path, 'announcements', 'bodies', '$id.$lang.md'));
  }

  @override
  Future<List<AnnouncementItem>> loadLocalManifest() async {
    if (!localOnly) {
      try {
        final f = await _manifestCacheFile();
        if (await f.exists()) {
          return _parseManifest(await f.readAsString());
        }
      } catch (_) {}
    }
    try {
      return _parseManifest(
        await rootBundle.loadString(_assetManifest, cache: false),
      );
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<AnnouncementItem>> fetchRemoteManifest() async {
    final res = await http.get(Uri.parse(manifestUrl));
    if (res.statusCode != 200) {
      throw HttpException('manifest HTTP ${res.statusCode}');
    }
    final raw = utf8.decode(res.bodyBytes);
    final items = _parseManifest(raw);
    try {
      final f = await _manifestCacheFile();
      await f.parent.create(recursive: true);
      await atomicWriteJson(f, jsonDecode(raw));
    } catch (_) {}
    return items;
  }

  List<AnnouncementItem> _parseManifest(String raw) {
    final data = jsonDecode(raw) as List<dynamic>;
    return data
        .map((e) => AnnouncementItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<String?> loadLocalBody(String id, String lang) async {
    if (!localOnly) {
      try {
        final f = await _bodyCacheFile(id, lang);
        if (await f.exists()) return await f.readAsString();
      } catch (_) {}
    }
    try {
      return await rootBundle.loadString(_assetBody(id, lang), cache: false);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> fetchRemoteBody(String id, String lang) async {
    try {
      final res = await http.get(Uri.parse(bodyUrl(id, lang)));
      if (res.statusCode != 200) return null;
      final raw = utf8.decode(res.bodyBytes);
      final f = await _bodyCacheFile(id, lang);
      await f.parent.create(recursive: true);
      final tmp = File('${f.path}.tmp');
      await tmp.writeAsString(raw, flush: true);
      await tmp.rename(f.path);
      return raw;
    } catch (_) {
      return null;
    }
  }
}
