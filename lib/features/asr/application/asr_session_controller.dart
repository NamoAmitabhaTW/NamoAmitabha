// lib/features/asr/application/asr_session_controller.dart
import 'dart:async';
import 'package:amitabha/core/utils/date_format.dart';
import 'package:amitabha/features/asr/domain/amitabha_normalizer.dart';
import 'package:amitabha/storage/buffered_hits.dart';
import 'package:amitabha/storage/daily_repo.dart';
import 'package:amitabha/storage/hit_logger.dart';
import 'package:amitabha/storage/models.dart';
import 'package:amitabha/storage/pending_commits.dart';
import 'package:amitabha/storage/session_repo.dart';
import 'package:flutter/widgets.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

const String kAsrModelName =
    'sherpa-onnx-x-asr-960ms-streaming-zipformer-transducer-zh-en-punct-int8-2026-06-05';

const String kLocalUserId = 'local';
const String kLocalUserName = '使用者';

enum SessionState { idle, recording, paused }

abstract class SpeechSegmentSource {
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
  SessionState _sessionState = SessionState.idle;
  SessionState get sessionState => _sessionState;
  bool get isRecording => _sessionState == SessionState.recording;

  int _sessionCount = 0;
  int get sessionCount => _sessionCount;

  DateTime? _lastHitAt;
  DateTime? get lastHitAt => _lastHitAt;

  int _dataVersion = 0;
  int get dataVersion => _dataVersion;

  String? _sessionId;
  String? get currentSessionId => _sessionId;
  DateTime? _sessionStartedAt;
  HitLogger? _hitLogger;
  BufferedHits? _buffer;
  bool _committing = false;

  Future<bool> hasMicPermission() async {
    _source ??= _sourceFactory?.call();
    final source = _source;
    if (source == null) return false;
    return source.hasPermission();
  }

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

  Future<void> stop() async {
    if (_sessionState != SessionState.recording) return;
    await _source?.stop();
    _sessionState = SessionState.paused;
    try {
      await _setWakelock(false);
    } catch (_) {}
    notifyListeners();
  }

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

    await _pendingStore.add(pending);

    await _source?.stop();
    try {
      await _buffer?.close();
    } catch (_) {}
    _buffer = null;
    _hitLogger = null;
    _sessionCount = 0;
    _lastHitAt = null;
    _sessionState = SessionState.idle;
    try {
      await _setWakelock(false);
    } catch (_) {}
    notifyListeners();
    await replayPending();
  }

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
        debugPrint('[ASR] replay pending failed: $e');
      }
    }
    if (wroteAny) {
      _dataVersion++;
      notifyListeners();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      if (_sessionState == SessionState.recording) {
        unawaited(stop());
      }
      unawaited(_saveDraft());
    }
    if (state == AppLifecycleState.detached) {
      if (_sessionCount > 0 && !_committing) {
        unawaited(save());
      }
    }
  }

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
