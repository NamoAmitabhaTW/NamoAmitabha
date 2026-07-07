// lib/features/asr/application/asr_session_controller.dart
// 念佛 session 的業務邏輯層(取代原本掛在 widget 樹裡的 StreamingAsrRunner):
// 狀態機(idle/recording/paused)、佛號計數、hit 落盤、session 提交。
//
// 設計重點:
// - 不碰 BuildContext、不開對話框;UI 透過 Provider 監聽本 controller。
// - 語音辨識硬體鏈路(麥克風+sherpa)抽象成 SpeechSegmentSource,
//   測試時注入假來源即可完整驗證計數與提交邏輯。
// - 提交採「journal 先行」:先把本輪結果寫入 pending journal 再歸零 UI,
//   之後才寫 session/daily 檔;任何一步失敗,資料都還在 journal,
//   下次啟動或下次儲存時自動重放,不會丟計數。

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:amitabha/features/asr/domain/amitabha_normalizer.dart';
import 'package:amitabha/core/utils/date_format.dart';
import 'package:amitabha/storage/buffered_hits.dart';
import 'package:amitabha/storage/daily_repo.dart';
import 'package:amitabha/storage/hit_logger.dart';
import 'package:amitabha/storage/models.dart';
import 'package:amitabha/storage/pending_commits.dart';
import 'package:amitabha/storage/session_repo.dart';

/// 本 App 使用的 ASR 模型。
const String kAsrModelName =
    'sherpa-onnx-streaming-zipformer-bilingual-zh-en-2023-02-20';

/// 尚未有帳號系統,本機使用者的固定識別(未來接帳號時只改這裡)。
const String kLocalUserId = 'local';
const String kLocalUserName = '使用者';

enum SessionState { idle, recording, paused }

/// 語音辨識來源的抽象:start() 之後,每辨識出一段完整語句
/// 就透過 onSegment 回呼送出文字。實作見 sherpa_mic_source.dart。
abstract class SpeechSegmentSource {
  /// 是否已取得麥克風權限(第一次呼叫會觸發系統原生權限彈窗)。
  Future<bool> hasPermission();

  Future<void> start({required void Function(String text) onSegment});

  Future<void> stop();

  Future<void> dispose();
}

class AsrSessionController extends ChangeNotifier with WidgetsBindingObserver {
  AsrSessionController({
    SpeechSegmentSource Function()? sourceFactory,
    SessionRepository? sessionRepo,
    DailyRepository? dailyRepo,
    PendingCommitStore? pendingStore,
    Future<void> Function(bool keepAwake)? setWakelock,
  }) : _sourceFactory = sourceFactory,
       _sessionRepo = sessionRepo ?? SessionRepository(),
       _dailyRepo = dailyRepo ?? DailyRepository(),
       _pendingStore = pendingStore ?? PendingCommitStore(),
       _setWakelock = setWakelock ?? _defaultSetWakelock {
    WidgetsBinding.instance.addObserver(this);
    // 啟動時重放先前提交失敗的紀錄(若有),不阻塞建構
    unawaited(
      replayPending().catchError((e) => debugPrint('replay on init: $e')),
    );
  }

  final SpeechSegmentSource Function()? _sourceFactory;
  final SessionRepository _sessionRepo;
  final DailyRepository _dailyRepo;
  final PendingCommitStore _pendingStore;
  final Future<void> Function(bool keepAwake) _setWakelock;

  SpeechSegmentSource? _source;

  // ── UI 可觀察狀態 ─────────────────────────────────────────

  SessionState _sessionState = SessionState.idle;
  SessionState get sessionState => _sessionState;
  bool get isRecording => _sessionState == SessionState.recording;

  int _sessionCount = 0;
  int get sessionCount => _sessionCount;

  DateTime? _lastHitAt;
  DateTime? get lastHitAt => _lastHitAt;

  /// 每次資料成功寫入磁碟就 +1;紀錄頁以此為 key 重新載入。
  int _dataVersion = 0;
  int get dataVersion => _dataVersion;

  // ── session 內部狀態 ─────────────────────────────────────

  String? _sessionId;
  String? get currentSessionId => _sessionId;
  DateTime? _sessionStartedAt;
  HitLogger? _hitLogger;
  BufferedHits? _buffer;
  bool _committing = false;

  // ── 對 UI 的操作 API ─────────────────────────────────────

  /// 是否已取得麥克風權限(第一次呼叫會觸發系統原生權限彈窗)。
  Future<bool> hasMicPermission() async {
    _source ??= _sourceFactory?.call();
    final source = _source;
    if (source == null) return false;
    return source.hasPermission();
  }

  /// 開始(或續錄)。模型就緒與權限確認由 UI 層先行處理。
  Future<void> start() async {
    if (_sessionState == SessionState.recording) return;
    _source ??= _sourceFactory?.call();
    final source = _source;
    if (source == null) {
      debugPrint('[ASR] no speech source configured');
      return;
    }

    if (_sessionState == SessionState.idle) {
      await _beginNewSession();
    }
    _sessionState = SessionState.recording;
    notifyListeners();

    try {
      await _setWakelock(true);
    } catch (_) {}

    try {
      await source.start(onSegment: _onSegment);
    } catch (e) {
      debugPrint('[ASR] source start error: $e');
      _sessionState = SessionState.paused;
      try {
        await _setWakelock(false);
      } catch (_) {}
      notifyListeners();
    }
  }

  /// 暫停錄音(session 保留,可續錄)。
  Future<void> stop() async {
    if (_sessionState != SessionState.recording) return;
    await _source?.stop();
    _sessionState = SessionState.paused;
    try {
      await _setWakelock(false);
    } catch (_) {}
    notifyListeners();
  }

  /// 使用者按「儲存」:提交本輪計數。
  Future<void> save() async {
    if (_committing) return;
    _committing = true;
    try {
      await _commitSession();
    } catch (e) {
      debugPrint('[ASR] save failed: $e');
    } finally {
      _committing = false;
    }
  }

  // ── 辨識結果進入點 ───────────────────────────────────────

  void _onSegment(String text) {
    final hits = countAmitabhaOccurrences(text);
    if (hits <= 0) return;

    _sessionCount += hits;
    _lastHitAt = DateTime.now();
    debugPrint('[ASR] 阿彌陀佛 HIT=$hits Count=$_sessionCount');

    for (int i = 0; i < hits; i++) {
      _buffer?.add(DateTime.now());
    }
    notifyListeners();
  }

  // ── session 生命週期 ─────────────────────────────────────

  Future<void> _beginNewSession() async {
    final sessionId = DateTime.now().toUtc().millisecondsSinceEpoch.toString();
    _sessionId = sessionId;
    _sessionStartedAt = DateTime.now().toUtc();
    _sessionCount = 0;
    _lastHitAt = null;

    final logger = HitLogger(sessionId, rotateEvery: 5000);
    await logger.initFromDisk();
    _hitLogger = logger;

    _buffer = BufferedHits(
      flushEvery: const Duration(seconds: 3),
      maxBuffer: 200,
      onFlush: (hits) async {
        if (hits.isEmpty) return;
        final hitsUtc = hits.map((e) => e.toUtc()).toList(growable: false);
        await _hitLogger?.appendMany(hitsUtc);
      },
    );
  }

  Future<void> _commitSession() async {
    if (_sessionCount <= 0) return;
    final sessionId = _sessionId;
    final startedAt = _sessionStartedAt;
    if (sessionId == null || startedAt == null) return;

    final pending = PendingCommit(
      snapshot: SessionSnapshot(
        sessionId: sessionId,
        userId: kLocalUserId,
        userName: kLocalUserName,
        startedAt: startedAt,
        lastAt: (_lastHitAt ?? DateTime.now()).toUtc(),
        amitabhaCount: _sessionCount,
      ),
      ymd: nowYmdLocal(),
    );

    // 1) 意圖先落盤:這步成功後,即使後續全失敗,計數也不會丟
    await _pendingStore.add(pending);

    // 2) 停止硬體與 hit 緩衝
    await _source?.stop();
    try {
      await _buffer?.close();
    } catch (_) {}
    _buffer = null;
    _hitLogger = null;

    // 3) UI 歸零
    _sessionCount = 0;
    _lastHitAt = null;
    _sessionState = SessionState.idle;
    try {
      await _setWakelock(false);
    } catch (_) {}
    notifyListeners();

    // 4) 真正寫入(順便重放先前失敗的紀錄)
    await replayPending();
  }

  /// 把 journal 裡的每一筆寫入 session/daily 檔;成功的移除 journal。
  /// daily 寫入以 sessionId 幂等,重放不會重複累計。
  Future<void> replayPending() async {
    final entries = await _pendingStore.list();
    if (entries.isEmpty) return;

    var wroteAny = false;
    for (final entry in entries) {
      try {
        await _sessionRepo.upsertSnapshot(entry.snapshot);
        await _dailyRepo.addCountForSession(
          entry.ymd,
          entry.snapshot.userId,
          entry.snapshot.userName,
          entry.snapshot.amitabhaCount,
          entry.snapshot.sessionId,
        );
        await _pendingStore.remove(entry.snapshot.sessionId);
        wroteAny = true;
      } catch (e) {
        debugPrint('[ASR] replay pending failed: $e'); // 留在 journal,下次再試
      }
    }
    if (wroteAny) {
      _dataVersion++;
      notifyListeners();
    }
  }

  // ── App 生命週期 ─────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      if (_sessionState == SessionState.recording) {
        unawaited(stop());
      }
      // 進背景就把目前計數寫成 journal 草稿:
      // 使用者從多工列滑掉 App 時,系統多半直接殺進程,detached 不會送達;
      // paused 是滑掉前必經的最後可靠時機。之後正常儲存會以同一個
      // sessionId 覆蓋草稿(幂等),不會重複計數;被殺則下次啟動自動重放。
      unawaited(_saveDraft());
    }
    if (state == AppLifecycleState.detached) {
      if (_sessionCount > 0 && !_committing) {
        unawaited(save());
      }
    }
  }

  /// 把目前 session 的計數寫成 journal 草稿(不歸零 UI、不重放)。
  Future<void> _saveDraft() async {
    if (_sessionCount <= 0) return;
    final sessionId = _sessionId;
    final startedAt = _sessionStartedAt;
    if (sessionId == null || startedAt == null) return;

    try {
      await _pendingStore.add(
        PendingCommit(
          snapshot: SessionSnapshot(
            sessionId: sessionId,
            userId: kLocalUserId,
            userName: kLocalUserName,
            startedAt: startedAt,
            lastAt: (_lastHitAt ?? DateTime.now()).toUtc(),
            amitabhaCount: _sessionCount,
          ),
          ymd: nowYmdLocal(),
        ),
      );
      debugPrint('[ASR] draft saved: $_sessionCount hits');
    } catch (e) {
      debugPrint('[ASR] draft save failed: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final source = _source;
    _source = null;
    if (source != null) {
      unawaited(source.dispose().catchError((_) {}));
    }
    final buffer = _buffer;
    _buffer = null;
    if (buffer != null) {
      unawaited(buffer.close().catchError((_) {}));
    }
    unawaited(_setWakelock(false).catchError((_) {}));
    super.dispose();
  }

  static Future<void> _defaultSetWakelock(bool keepAwake) =>
      keepAwake ? WakelockPlus.enable() : WakelockPlus.disable();
}
