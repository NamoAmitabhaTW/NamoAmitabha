// 背景狀態控制器(ChangeNotifier),對齊 theme_controller / locale_controller
// amitabha/lib/features/background/background_controller.dart
import 'package:flutter/foundation.dart';
import 'package:amitabha/features/background/background_item.dart';
import 'package:amitabha/features/background/background_prefs.dart';
import 'package:amitabha/features/background/background_repo.dart';
import 'dart:io'; // for SocketException

class BackgroundController extends ChangeNotifier {
  BackgroundController({BackgroundRepo? repo})
    : _repo = repo ?? BackgroundRepo();

  final BackgroundRepo _repo;

  // 是否抓清單失敗(離線/伺服器問題)
  bool manifestLoadFailed = false;

  // 被使用者取消中的下載 id,用來區分「取消」與「真的失敗」。
  final Set<String> _cancelling = {};

  List<BackgroundItem> items = [];
  String? activeId;
  bool isLoading = false;
  String? lastDownloadError; // 給使用者看的下載失敗文案,SnackBar用

  // 目前背景來源的快取:同步讀取,避免在 build 裡跑 Future 造成影片重建/閃爍。
  BackgroundSource? _currentSource;
  BackgroundSource? get currentSource => _currentSource;

  // 偵測到「使用中的背景被系統清掉」時,記下名稱供 UI 顯示一次提醒。
  String? clearedNoticeName;
  void consumeClearedNotice() {
    clearedNoticeName = null;
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

    // ── Phase 1:本地優先(內建 + 上次快取的 manifest),離線也能顯示 ──
    final cached = await _repo.loadCachedManifest();
    items = await _reconcile(builtins, cached);
    final active = await BackgroundPrefs.loadActive();
    activeId = (active?['activeId'] as String?) ?? _defaultBuiltin?.id;
    await _resolveSourceFast(active);
    notifyListeners(); // 背景先動起來,不被網路卡住

    // ── Phase 2:抓遠端,成功才覆寫;失敗則保留 Phase 1 結果 ──
    manifestLoadFailed = false;
    try {
      final remote = await _repo.fetchManifest();
      items = await _reconcile(builtins, remote);
    } catch (e) {
      debugPrint('manifest 載入失敗: $e');
      manifestLoadFailed = true;
      // 關鍵:不再把 items 打回只剩 builtins,維持 Phase 1(內建 + 快取)
    }

    if (!items.any((i) => i.id == activeId)) {
      activeId = _defaultBuiltin?.id;
    }

    // 偵測:使用中是「非內建、但本地檔已不在」→ 被系統清掉了
    final cur = activeItem;
    if (cur != null && !cur.isBuiltin && !cur.isDownloaded) {
      clearedNoticeName = cur.name;
      final fb = _defaultBuiltin;
      activeId = fb?.id;
      if (fb != null) await _saveActive(fb);
    }

    await _resolveSource();
    isLoading = false;
    notifyListeners();
  }

  /// 把 manifest 清單與內建合併,並依本地檔案狀態標記 isDownloaded / needsUpdate。
  /// Phase 1(快取)與 Phase 2(遠端)共用,確保兩條路徑邏輯一致。
  Future<List<BackgroundItem>> _reconcile(
    List<BackgroundItem> builtins,
    List<BackgroundItem> manifest,
  ) async {
    final merged = <BackgroundItem>[...builtins];
    final versions = await BackgroundPrefs.loadVersions();
    for (final item in manifest) {
      if (builtins.any((b) => b.id == item.id)) continue; // 去重
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
      return true; // ← 成功
    } catch (e) {
      if (_cancelling.contains(item.id)) {
        return false; // 使用者主動取消,不算失敗、不提示
      }
      // 區分離線與其他錯誤,給 UI 更精準的文案
      lastDownloadError = e is SocketException
          ? '網路未連線,無法下載背景。'
          : '下載失敗,請稍後再試。';
      return false; // ← 失敗
    } finally {
      item.isDownloading = false;
      item.downloadProgress = 0;
      _cancelling.remove(item.id);
      notifyListeners();
    }
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
    if (item.isBuiltin) return; // 內建不可刪

    await _repo.delete(item);
    await BackgroundPrefs.removeVersion(item.id);
    item.isDownloaded = false;
    item.needsUpdate = false;

    // 刪到使用中的 → 自動退回內建預設,避免畫面變空白
    if (activeId == item.id) {
      final fb = _defaultBuiltin;
      activeId = fb?.id;
      if (fb != null) await _saveActive(fb);
    }
    await _resolveSource();
    notifyListeners();
  }

  // ── 來源解析 ──────────────────────────────────────────────

  /// 由 item 建出來源。已下載者的 revision 取「本地版本」(代表磁碟上的內容),
  /// 這樣只有真正更新過檔案、revision 改變時播放端才會重載。
  Future<BackgroundSource?> _buildSource(BackgroundItem? item) async {
    if (item == null) return null;
    if (item.isBuiltin) {
      return BackgroundSource(
        type: item.type,
        assetPath: item.assetPath,
        revision: 1,
      );
    }
    final f = await _repo.fileFor(item);
    if (!await f.exists()) return null;
    final versions = await BackgroundPrefs.loadVersions();
    final localRev = versions[item.id] ?? 1;
    return BackgroundSource(type: item.type, file: f, revision: localRev);
  }

  Future<void> _resolveSource() async {
    _currentSource = await _buildSource(activeItem);
  }

  /// Phase 1 快速解析:只靠本地資料(內建用 asset;已下載用持久化描述 + 本地檔),
  /// 免 manifest、可離線,讓背景在啟動瞬間就出現。
  Future<void> _resolveSourceFast(Map<String, dynamic>? active) async {
    final id = activeId;
    if (id == null) {
      _currentSource = null;
      return;
    }
    // 內建?直接拿 asset
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
    // 非內建:用持久化描述 + 本地檔還原
    if (active != null) {
      final type = (active['type'] as String?) == 'image'
          ? BackgroundType.image
          : BackgroundType.video;
      final rev = (active['revision'] as num?)?.toInt() ?? 1;
      final f = await _repo.fileForRaw(id, type);
      if (await f.exists()) {
        _currentSource = BackgroundSource(type: type, file: f, revision: rev);
        return;
      }
    }
    _currentSource = null; // 檔案不在(可能被清)→ Phase 2 再處理 fallback
  }

  /// 存使用中背景的描述(id + type + 本地版本),供下次啟動離線快速還原。
  Future<void> _saveActive(BackgroundItem item) async {
    final localRev = item.isBuiltin
        ? 1
        : ((await BackgroundPrefs.loadVersions())[item.id] ?? item.version);
    await BackgroundPrefs.saveActive(item.id, item.type, localRev);
  }
}
