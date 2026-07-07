// lib/features/asr/streaming_asr.dart
// This file is modified based on the open-source project:
// Flutter-EasySpeechRecognition (https://github.com/Jason-chen-coder/Flutter-EasySpeechRecognition)
// Original copyright (c) 2024 Xiaomi Corporation

import 'dart:async';
import 'package:amitabha/features/model_install/asr_hotwords.dart';
import 'package:amitabha/features/asr/domain/amitabha_normalizer.dart';
import 'package:amitabha/features/model_install/widgets/download_progress_dialog.dart';
import 'package:amitabha/features/model_install/install_progress_model.dart';
import 'package:amitabha/features/model_install/online_model.dart';
import 'package:amitabha/features/model_install/model_installer.dart';
import 'package:amitabha/features/model_install/model_install_flow.dart';
import 'package:amitabha/core/utils/audio_convert.dart';
import 'package:amitabha/core/utils/date_format.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;
import 'package:amitabha/storage/hit_logger.dart';
import 'package:amitabha/storage/session_repo.dart';
import 'package:amitabha/storage/daily_repo.dart';
import 'package:amitabha/storage/buffered_hits.dart';
import 'package:amitabha/storage/models.dart';
import 'package:amitabha/app/app_state.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:amitabha/l10n/generated/app_localizations.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

enum SessionState { idle, recording, paused }

/// 本 App 使用的 ASR 模型。
const String kAsrModelName =
    'sherpa-onnx-streaming-zipformer-bilingual-zh-en-2023-02-20';

Future<sherpa_onnx.OnlineRecognizer> createOnlineRecognizer(
  String modelName,
) async {
  final localModelConfig = await getModelConfigByModelName(
    modelName: modelName,
  );
  final hotwordsPath = await materializeHotwordsFile();
  final config = sherpa_onnx.OnlineRecognizerConfig(
    model: localModelConfig,
    ruleFsts: '',
    decodingMethod: 'modified_beam_search',
    hotwordsFile: hotwordsPath,
    hotwordsScore: 3,
    enableEndpoint: true,
    rule2MinTrailingSilence: 1.2,
    rule3MinUtteranceLength: 30,
  );

  return sherpa_onnx.OnlineRecognizer(config);
}

class StreamingAsrRunner extends StatefulWidget {
  const StreamingAsrRunner({super.key});

  @override
  State<StreamingAsrRunner> createState() => _StreamingAsrRunnerState();
}

class _StreamingAsrRunnerState extends State<StreamingAsrRunner>
    with WidgetsBindingObserver {
  late final AudioRecorder _audioRecorder = AudioRecorder();
  String _last = '';
  int _index = 0;
  bool _isInitialized = false;
  sherpa_onnx.OnlineRecognizer? _recognizer;
  sherpa_onnx.OnlineStream? _stream;
  int _sampleRate = 16000;

  int _asrHitCount = 0;
  DateTime? _asrLastHitAt;

  late final SessionRepository _sessionRepo;
  late final DailyRepository _dailyRepo;
  HitLogger? _hitLogger;
  BufferedHits? _buffer;
  late String _sessionId;
  late DateTime _sessionStartedAt;
  SessionState _sessionState = SessionState.idle;

  final String _userId = 'local';
  final String _userName = '使用者';

  bool _committing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initAndStart();
    // 🔗 綁定 ASR 控制指令到 AppState（UI 會呼叫這些）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        context.read<AppState>().bindAsrHandlers(
          onStart: _start,
          onStop: _stop,
          onSave: _onSavePressed, // 內部會呼叫 _commitSession()
        );
      } catch (_) {}
    });
  }

  Future<void> _initAndStart() async {
    await _initStorage();
  }

  Future<void> _start() async {
    // 安裝已在進行中 → 重新開啟進度對話框即可
    final progressModel = context.read<InstallProgressModel>();
    if (progressModel.isBusy) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const DownloadProgressDialog(),
      );
      return;
    }

    // 模型缺件 → 走安裝流程(所有對話框都在 ModelInstallFlow 內處理);
    // 安裝完成後由使用者再按一次「開始」進入錄音。
    final installer = ModelInstaller();
    if (await installer.status(kAsrModelName) != InstallStatus.ready) {
      if (!mounted) return;
      await ModelInstallFlow(
        installer: installer,
      ).ensureReady(context, kAsrModelName);
      return;
    }

    // 先用 record 觸發系統原生權限（第一次會跳 iOS/Android 原生彈窗）
    bool granted = await _audioRecorder.hasPermission();

    // 若沒拿到，就視平台做一次補救；仍沒拿到就顯示「前往設定」
    if (!granted) {
      if (!mounted) return;
      await _showOpenSettingsDialog(context); // 第二次才看到你的自家 dialog
      return;
    }

    if (!_isInitialized) {
      sherpa_onnx.initBindings();
      _recognizer = await createOnlineRecognizer(kAsrModelName);
      _stream = _recognizer?.createStream();

      _isInitialized = true;
    }

    if (_sessionState == SessionState.idle) {
      await _beginNewSession();
    }
    _sessionState = SessionState.recording;

    if (!(await WakelockPlus.enabled)) {
      await WakelockPlus.enable();
    }

    try {
      if (await _audioRecorder.hasPermission()) {
        const encoder = AudioEncoder.pcm16bits;

        if (!await _isEncoderSupported(encoder)) {
          return;
        }

        final devs = await _audioRecorder.listInputDevices();
        debugPrint(devs.toString());

        const config = RecordConfig(
          encoder: encoder,
          sampleRate: 16000,
          numChannels: 1,
        );

        final stream = await _audioRecorder.startStream(config);

        context.read<AppState>().setRecording(true);
        await WakelockPlus.enable();

        stream.listen(
          (data) {
            final samplesFloat32 = convertBytesToFloat32(
              Uint8List.fromList(data),
            );

            _stream!.acceptWaveform(
              samples: samplesFloat32,
              sampleRate: _sampleRate,
            );
            while (_recognizer!.isReady(_stream!)) {
              _recognizer!.decode(_stream!);
            }
            final text = _recognizer!.getResult(_stream!).text;
            String textToDisplay = _last;
            if (text != '') {
              if (_last == '') {
                textToDisplay = '$_index: $text';
              } else {
                textToDisplay = '$_index: $text\n$_last';
              }
            }

            if (_recognizer!.isEndpoint(_stream!)) {
              _recognizer!.reset(_stream!);
              if (text != '') {
                _last = textToDisplay;
                _index += 1;
                debugPrint('[ASR] =$text');
                final hitAdd = countAmitabhaOccurrences(text);
                if (hitAdd > 0) {
                  _asrHitCount += hitAdd;
                  _asrLastHitAt = DateTime.now();
                  debugPrint(
                    '[ASR] 阿彌陀佛 HIT=$hitAdd Count = $_asrHitCount '
                    ' Time = ${_asrLastHitAt!.toIso8601String()}',
                  );
                  for (int i = 0; i < hitAdd; i++) {
                    _buffer?.add(DateTime.now());
                  }

                  if (mounted) {
                    try {
                      context.read<AppState>().setAsrTempProgress(
                        count: _asrHitCount,
                        last: _asrLastHitAt,
                      );
                    } catch (_) {}
                  }
                }
              }
            }
          },
          onDone: () {
            debugPrint('stream stopped.');
          },
        );
      }
    } catch (e) {
      debugPrint('[ASR] startStream error: $e');
    }
  }

  Future<void> _stop() async {
    _stream?.free();
    _stream = _recognizer?.createStream();
    try {
      await _audioRecorder.stop();
    } catch (_) {}
    context.read<AppState>().setRecording(false);
    await WakelockPlus.disable();
    _sessionState = SessionState.paused;
  }

  Future<bool> _isEncoderSupported(AudioEncoder encoder) async {
    final isSupported = await _audioRecorder.isEncoderSupported(encoder);

    if (!isSupported) {
      debugPrint('${encoder.name} is not supported on this platform.');
      debugPrint('Supported encoders are:');

      for (final e in AudioEncoder.values) {
        if (await _audioRecorder.isEncoderSupported(e)) {
          debugPrint('- ${encoder.name}');
        }
      }
    }

    return isSupported;
  }

  Future<void> _initStorage() async {
    _sessionRepo = SessionRepository();
    _dailyRepo = DailyRepository();
  }

  Future<void> _beginNewSession() async {
    _sessionId = DateTime.now().toUtc().millisecondsSinceEpoch.toString();
    _sessionStartedAt = DateTime.now().toUtc();

    _asrHitCount = 0;
    _asrLastHitAt = null;
    _last = '';
    _index = 0;

    _hitLogger = HitLogger(_sessionId, rotateEvery: 5000);
    await _hitLogger!.initFromDisk();

    _buffer = BufferedHits(
      flushEvery: const Duration(seconds: 3),
      maxBuffer: 200,
      onFlush: (hits) async {
        if (hits.isEmpty) return;
        final hitsUtc = hits.map((e) => e.toUtc()).toList(growable: false);
        final logger = _hitLogger;
        if (logger != null) {
          await logger.appendMany(hitsUtc);
        }
      },
    );
  }

  Future<void> _commitSession({String reason = 'user_action'}) async {
    final currentCount = _asrHitCount;
    final lastHitAt = _asrLastHitAt;

    if (_asrHitCount <= 0) {
      return;
    }

    _asrHitCount = 0;
    _asrLastHitAt = null;
    _last = '';
    _index = 0;
    _sessionState = SessionState.idle;

    final snapshot = SessionSnapshot(
      sessionId: _sessionId,
      userId: _userId,
      userName: _userName,
      startedAt: _sessionStartedAt,
      lastAt: (lastHitAt ?? DateTime.now()).toUtc(),
      amitabhaCount: currentCount,
    );

    try {
      await _sessionRepo.upsertSnapshot(snapshot);
      final ymd = nowYmdLocal();
      await _dailyRepo.addCount(ymd, _userId, _userName, currentCount);
    } catch (e) {
      debugPrint('cloud sync failed: $e');
    }

    try {
      await _buffer?.close();
    } catch (_) {}
    try {
      await _audioRecorder.stop();
    } catch (_) {}
    try {
      await WakelockPlus.disable();
    } catch (_) {}

    if (mounted) {
      try {
        context.read<AppState>().onSessionCommitted();
        context.read<AppState>().setRecording(false);
      } catch (_) {}
    }

    _buffer = null;
    _hitLogger = null;
  }

  Future<void> _onSavePressed() async {
    if (_committing) return;
    _committing = true;
    try {
      await _commitSession(reason: 'user_save');
    } catch (e) {
      debugPrint('Save failed: $e');
    } finally {
      _committing = false;
    }
  }

  Future<void> _commitIfPending({String reason = 'auto'}) async {
    if (_committing) return;
    if (_asrHitCount > 0) {
      try {
        await _commitSession(reason: reason);
      } catch (_) {}
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.paused) {
      if (_sessionState == SessionState.recording) {
        await _stop();
      }
    }

    if (state == AppLifecycleState.detached) {
      await _commitIfPending(reason: 'app_killed');
    }
  }

  Future<void> _showOpenSettingsDialog(BuildContext context) async {
    final t = AppLocalizations.of(context);
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(t.micPermissionTitle), // i18n (見下方 ARB)
        content: Text(t.micPermissionRationale), // i18n
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.cancel),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await openAppSettings(); // 由 permission_handler 提供
            },
            child: Text(t.openSettings),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WakelockPlus.disable();
    _audioRecorder.dispose();
    _stream?.free();
    _recognizer?.free();
    _buffer?.close();
    try {
      context.read<AppState>().bindAsrHandlers(
        onStart: null,
        onStop: null,
        onSave: null,
      );
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //Runner 不出畫面
    return const SizedBox.shrink();
  }
}
