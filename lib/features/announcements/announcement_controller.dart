import 'package:amitabha/features/announcements/announcement_item.dart';
import 'package:amitabha/features/announcements/announcement_prefs.dart';
import 'package:amitabha/features/announcements/announcement_repo.dart';
import 'package:flutter/foundation.dart';

class AnnouncementController extends ChangeNotifier {
  AnnouncementController({AnnouncementRepo? repo})
    : _repo = repo ?? AnnouncementRepo();

  final AnnouncementRepo _repo;

  List<AnnouncementItem> items = [];
  bool isLoading = false;
  bool manifestLoadFailed = false;

  Map<String, int> _read = {};

  final Map<String, String> _bodies = {};

  final Map<String, Future<String?>> _bodyFutures = {};

  bool get hasUnread {
    for (final item in items) {
      if (item.version > (_read[item.id] ?? 0)) return true;
    }
    return false;
  }

  Future<void> load() async {
    isLoading = true;
    _read = await AnnouncementPrefs.loadRead();

    items = await _repo.loadLocalManifest();
    notifyListeners();

    manifestLoadFailed = false;
    if (!AnnouncementRepo.localOnly) {
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
    await AnnouncementPrefs.saveRead(next);
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

    final bodyVersions = await AnnouncementPrefs.loadBodyVersions();
    final localVersion = bodyVersions[item.id] ?? 0;
    final needsRemote = !AnnouncementRepo.localOnly &&
        (local == null || localVersion < item.version);

    if (needsRemote) {
      final remote = await _repo.fetchRemoteBody(item.id, lang);
      if (remote != null) {
        _bodies[key] = remote;
        await AnnouncementPrefs.saveBodyVersion(item.id, item.version);
        notifyListeners();
      }
    }
    return _bodies[key];
  }
}
