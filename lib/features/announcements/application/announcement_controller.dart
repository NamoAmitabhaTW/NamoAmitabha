// lib/features/announcements/application/announcement_controller.dart
import 'package:amitabha/features/announcements/domain/announcement_item.dart';
import 'package:amitabha/features/announcements/domain/announcement_ports.dart';
import 'package:flutter/foundation.dart';

class AnnouncementController extends ChangeNotifier {
  AnnouncementController(this._repo, this._prefs);

  final AnnouncementRepository _repo;
  final AnnouncementPreferences _prefs;

  List<AnnouncementItem> items = [];
  bool isLoading = false;
  bool manifestLoadFailed = false;

  Map<String, int> _read = {};

  final Map<String, String> _bodies = {};

  final Map<String, Future<String?>> _bodyFutures = {};

  Future<void> load() async {
    isLoading = true;
    _read = await _prefs.loadRead();

    items = await _repo.loadLocalManifest();
    notifyListeners();

    manifestLoadFailed = false;
    if (!_repo.localOnly) {
      try {
        items = await _repo.fetchRemoteManifest();
      } catch (e) {
        debugPrint('公告 manifest 載入失敗: $e');
        manifestLoadFailed = true;
      }
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> markAllRead() async {
    final next = {for (final i in items) i.id: i.version};
    if (mapEquals(next, _read)) return;
    _read = next;
    await _prefs.saveRead(next);
    notifyListeners();
  }

  String? cachedBody(String id, String lang) => _bodies['$id@$lang'];

  Future<String?> ensureBody(AnnouncementItem item, String languageCode) {
    final lang = item.resolveBodyLang(languageCode) ?? 'zh';
    final key = '${item.id}@$lang';
    final existing = _bodyFutures[key];
    if (existing != null) return existing;
    final future = _loadBody(item, lang, key);
    _bodyFutures[key] = future;
    return future;
  }

  Future<String?> _loadBody(
    AnnouncementItem item,
    String lang,
    String key,
  ) async {
    final local = await _repo.loadLocalBody(item.id, lang);
    if (local != null) {
      _bodies[key] = local;
      notifyListeners();
    }

    final bodyVersions = await _prefs.loadBodyVersions();
    final localVersion = bodyVersions[item.id] ?? 0;
    final needsRemote =
        !_repo.localOnly && (local == null || localVersion < item.version);

    if (needsRemote) {
      final remote = await _repo.fetchRemoteBody(item.id, lang);
      if (remote != null) {
        _bodies[key] = remote;
        await _prefs.saveBodyVersion(item.id, item.version);
        notifyListeners();
      }
    }
    return _bodies[key];
  }
}
