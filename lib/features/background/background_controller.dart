// lib/features/background/background_controller.dart
import 'dart:io';
import 'package:amitabha/features/background/background_item.dart';
import 'package:amitabha/features/background/background_prefs.dart';
import 'package:amitabha/features/background/background_repo.dart';
import 'package:flutter/foundation.dart';

enum BackgroundDownloadError { network, notAvailable, unknown }

class BackgroundController extends ChangeNotifier {
  BackgroundController({BackgroundRepo? repo})
    : _repo = repo ?? BackgroundRepo();

  final BackgroundRepo _repo;

  bool manifestLoadFailed = false;

  final Set<String> _cancelling = {};

  List<BackgroundItem> items = [];
  String? activeId;
  bool isLoading = false;
  BackgroundDownloadError? lastDownloadError;

  BackgroundSource? _currentSource;
  BackgroundSource? get currentSource => _currentSource;

  BackgroundItem? clearedNoticeItem;
  void consumeClearedNotice() {
    clearedNoticeItem = null;
    notifyListeners();
  }

  BackgroundItem? get activeItem {
    for (final i in items) {
      if (i.id == activeId) return i;
    }
    return null;
  }

  BackgroundItem? get _defaultBuiltin {
    final b = BackgroundItem.builtinDefaults();
    return b.isNotEmpty ? b.first : null;
  }

  Future<void> load() async {
    isLoading = true;
    final builtins = BackgroundItem.builtinDefaults();

    final cached = await _repo.loadCachedManifest();
    items = await _reconcile(builtins, cached);
    final active = await BackgroundPrefs.loadActive();
    activeId = (active?['activeId'] as String?) ?? _defaultBuiltin?.id;
    await _resolveSourceFast(active);
    notifyListeners();

    manifestLoadFailed = false;
    try {
      final remote = await _repo.fetchManifest();
      items = await _reconcile(builtins, remote);
    } catch (e) {
      debugPrint('manifest 載入失敗: $e');
      manifestLoadFailed = true;
    }

    if (!items.any((i) => i.id == activeId)) {
      activeId = _defaultBuiltin?.id;
    }

    final cur = activeItem;
    if (cur != null && !cur.isBuiltin && !cur.isDownloaded) {
      clearedNoticeItem = cur;
      final fb = _defaultBuiltin;
      activeId = fb?.id;
      if (fb != null) await _saveActive(fb);
    }

    await _resolveSource();
    isLoading = false;
    notifyListeners();
  }

  Future<List<BackgroundItem>> _reconcile(
    List<BackgroundItem> builtins,
    List<BackgroundItem> manifest,
  ) async {
    final merged = <BackgroundItem>[...builtins];
    final versions = await BackgroundPrefs.loadVersions();
    for (final item in manifest) {
      if (builtins.any((b) => b.id == item.id)) continue;
      item.isDownloaded = await _repo.isDownloaded(item);
      if (item.isDownloaded) {
        final local = versions[item.id] ?? 1;
        item.needsUpdate = local < item.version;
      }
      merged.add(item);
    }
    return merged;
  }

  Future<bool> download(BackgroundItem item) async {
    if (item.isBuiltin || item.isDownloading) return false;
    if (item.isDownloaded && !item.needsUpdate) return false;

    _cancelling.remove(item.id);
    lastDownloadError = null;
    item.isDownloading = true;
    item.downloadProgress = 0;
    notifyListeners();

    try {
      await _repo.download(
        item,
        onProgress: (p) {
          if (p >= 1.0 || (p - item.downloadProgress).abs() >= 0.01) {
            item.downloadProgress = p;
            notifyListeners();
          }
        },
      );
      item.isDownloaded = true;
      item.needsUpdate = false;
      await BackgroundPrefs.saveVersion(item.id, item.version);
      if (item.id == activeId) {
        await _saveActive(item);
        await _resolveSource();
      }
      return true;
    } catch (e) {
      if (_cancelling.contains(item.id)) {
        return false;
      }
      lastDownloadError = _classifyDownloadError(e);
      return false;
    } finally {
      item.isDownloading = false;
      item.downloadProgress = 0;
      _cancelling.remove(item.id);
      notifyListeners();
    }
  }

  static BackgroundDownloadError _classifyDownloadError(Object e) {
    if (e is SocketException) return BackgroundDownloadError.network;
    if (e is HttpException) {
      final match = RegExp(r'HTTP (\d{3})').firstMatch(e.message);
      final code = int.tryParse(match?.group(1) ?? '');
      if (code != null && code >= 400 && code < 500) {
        return BackgroundDownloadError.notAvailable;
      }
    }
    return BackgroundDownloadError.unknown;
  }

  void cancelDownload(BackgroundItem item) {
    _cancelling.add(item.id);
    _repo.cancelDownload(item.id);
  }

  Future<void> use(BackgroundItem item) async {
    if (!item.isBuiltin && !item.isDownloaded) return;
    activeId = item.id;
    await _saveActive(item);
    await _resolveSource();
    notifyListeners();
  }

  Future<void> delete(BackgroundItem item) async {
    if (item.isBuiltin) return;

    await _repo.delete(item);
    await BackgroundPrefs.removeVersion(item.id);
    item.isDownloaded = false;
    item.needsUpdate = false;

    if (activeId == item.id) {
      final fb = _defaultBuiltin;
      activeId = fb?.id;
      if (fb != null) await _saveActive(fb);
    }
    await _resolveSource();
    notifyListeners();
  }

  Future<BackgroundSource?> _buildSource(BackgroundItem? item) async {
    if (item == null) return null;
    if (item.isBuiltin) {
      return BackgroundSource(
        type: item.type,
        assetPath: item.assetPath,
        revision: 1,
      );
    }
    final f = await _repo.findById(item.id);
    if (f == null) return null;
    final versions = await BackgroundPrefs.loadVersions();
    final localRev = versions[item.id] ?? 1;
    return BackgroundSource(type: item.type, file: f, revision: localRev);
  }

  Future<void> _resolveSource() async {
    _currentSource = await _buildSource(activeItem);
  }

  Future<void> _resolveSourceFast(Map<String, dynamic>? active) async {
    final id = activeId;
    if (id == null) {
      _currentSource = null;
      return;
    }

    for (final b in BackgroundItem.builtinDefaults()) {
      if (b.id == id) {
        _currentSource = BackgroundSource(
          type: b.type,
          assetPath: b.assetPath,
          revision: 1,
        );
        return;
      }
    }

    if (active != null) {
      final type = (active['type'] as String?) == 'image'
          ? BackgroundType.image
          : BackgroundType.video;
      final rev = (active['revision'] as num?)?.toInt() ?? 1;
      final f = await _repo.findById(id);
      if (f != null) {
        _currentSource = BackgroundSource(type: type, file: f, revision: rev);
        return;
      }
    }
    _currentSource = null;
  }

  Future<void> _saveActive(BackgroundItem item) async {
    final localRev = item.isBuiltin
        ? 1
        : ((await BackgroundPrefs.loadVersions())[item.id] ?? item.version);
    await BackgroundPrefs.saveActive(item.id, item.type, localRev);
  }
}
