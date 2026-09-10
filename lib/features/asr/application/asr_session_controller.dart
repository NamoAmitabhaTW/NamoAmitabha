// lib/features/asr/application/asr_session_controller.dart
import 'dart:async';
import 'package:amitabha/core/utils/date_format.dart';
import 'package:amitabha/features/asr/application/buffered_hits.dart';
import 'package:amitabha/features/asr/domain/amitabha_normalizer.dart';
import 'package:amitabha/features/asr/domain/chanting_repositories.dart';
import 'package:amitabha/features/asr/domain/pending_commit.dart';
import 'package:amitabha/features/asr/domain/session_snapshot.dart';
import 'package:amitabha/features/asr/domain/speech_segment_source.dart';
import 'package:flutter/widgets.dart';

const String kAsrModelName =
    'sherpa-onnx-x-asr-960ms-streaming-zipformer-transducer-zh-en-punct-int8-2026-06-05';

enum SessionState { idle, recording, paused }

class AsrSessionController extends ChangeNotifier with WidgetsBindingObserver {
  AsrSessionController({
    required SessionRepository sessionRepo,
    required DailyRepository dailyRepo,
    required PendingCommitStore pendingStore,
    required HitLogFactory hitLogFactory,
    required Future<void> Function(bool keepAwake) setWakelock,
    SpeechSegmentSource Function()? sourceFactory,
  }) : _sourceFactory = sourceFactory,
       _sessionRepo = sessionRepo,
       _dailyRepo = dailyRepo,
       _pendingStore = pendingStore,
       _hitLogFactory = hitLogFactory,
       _setWakelock = setWakelock {
    WidgetsBinding.instance.addObserver(this);
    unawaited(
      replayPending().catchError((e) => debugPrint('replay on init: $e')),
    );
  }

  final SpeechSegmentSource Function()? _sourceFactory;
  final SessionRepository _sessionRepo;
  final DailyRepository _dailyRepo;
  final PendingCommitStore _pendingStore;
  final HitLogFactory _hitLogFactory;
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
  HitLog? _hitLogger;
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

    final logger = _hitLogFactory(sessionId);
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
}
