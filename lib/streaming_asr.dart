// This file is modified based on the open-source project:
// Flutter-EasySpeechRecognition (https://github.com/Jason-chen-coder/Flutter-EasySpeechRecognition)
// Original copyright (c) 2024 Xiaomi Corporation

import 'dart:async';
import 'package:amitabha/ars_hotwords.dart';
import 'package:amitabha/amitabha_normalizer.dart';
import 'widgets/download_progress_dialog.dart';
import 'download_model.dart';
import 'online_model.dart';
import 'utils.dart';
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
import 'features/asr/widgets/save_button.dart';
import 'features/asr/widgets/record_toggle_button.dart';
import 'storage/firestore_syncToCloudBatch.dart';

enum SessionState { idle, recording }

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
    hotwordsScore: 6,
  );

  return sherpa_onnx.OnlineRecognizer(config);
}

class StreamingAsrScreen extends StatefulWidget {
  const StreamingAsrScreen({super.key});

  @override
  State<StreamingAsrScreen> createState() => _StreamingAsrScreenState();
}

class _StreamingAsrScreenState extends State<StreamingAsrScreen>
    with WidgetsBindingObserver {
  final TextEditingController _controller = TextEditingController();
  late final AudioRecorder _audioRecorder;
  String _last = '';
  int _index = 0;
  bool _isInitialized = false;
  sherpa_onnx.OnlineRecognizer? _recognizer;
  sherpa_onnx.OnlineStream? _stream;
  int _sampleRate = 16000;

  StreamSubscription<RecordState>? _recordSub;
  RecordState _recordState = RecordState.stop;

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
  bool get _saveEnabled => _asrHitCount > 0 && !_committing;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initAndStart();
  }

  Future<void> _initAndStart() async {
    await _initStorage();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DownloadModel>().useAsr(
        'sherpa-onnx-streaming-zipformer-bilingual-zh-en-2023-02-20',
      );
    });

    _audioRecorder = AudioRecorder();
    _recordSub = _audioRecorder.onStateChanged().listen(_updateRecordState);
  }

  Future<void> _start() async {
    final downloadModel = Provider.of<DownloadModel>(context, listen: false);
    final modelName = downloadModel.modelName;
    final progress = downloadModel.progress;
    final unzipProgress = downloadModel.unzipProgress;
    final unziping = unzipProgress > 0 && unzipProgress < 1;
    final downloading = progress > 0 && progress < 1;
    bool needsDownloadVal = await needsDownload(modelName);
    bool needsUnZipVal = await needsUnZip(modelName);
    if (downloading || unziping) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return DownloadProgressDialog();
        },
      );
      return;
    }
    if (needsDownloadVal) {
      downloadModelAndUnZip(context, modelName);
      return;
    }
    if (needsUnZipVal) {
      unzipModelFile(context, modelName);
      return;
    }
    if (!_isInitialized) {
      sherpa_onnx.initBindings();
      _recognizer = await createOnlineRecognizer(modelName);
      _stream = _recognizer?.createStream();

      _isInitialized = true;
    }

    if (_sessionState == SessionState.idle) {
      await _beginNewSession();
      _sessionState = SessionState.recording;
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

                final hitAdd = countAmitabhaOccurrences(text);
                if (hitAdd > 0) {
                  setState(() {
                    _asrHitCount += hitAdd;
                    _asrLastHitAt = DateTime.now();
                    debugPrint(
                      '[ASR] 阿彌陀佛 HIT=$hitAdd Count = $_asrHitCount '
                      ' Time = ${_asrLastHitAt!.toIso8601String()}',
                    );
                    for (int i = 0; i < hitAdd; i++) {
                      _buffer?.add(DateTime.now());
                    }
                  });
                }
              }
            }

            _controller.value = TextEditingValue(
              text: textToDisplay,
              selection: TextSelection.collapsed(offset: textToDisplay.length),
            );
          },
          onDone: () {
            print('stream stopped.');
          },
        );
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> _stop() async {
    await _buffer?.close();
    _stream?.free();
    _stream = _recognizer?.createStream();
    await _audioRecorder.stop();
  }

  void _updateRecordState(RecordState recordState) {
    setState(() => _recordState = recordState);
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
    await _buffer?.close();

    if (_asrHitCount <= 0) {
      return;
    }

    await _audioRecorder.stop();
    _sessionState = SessionState.idle;

    final lastAt = (_asrLastHitAt ?? DateTime.now()).toUtc();

    final snapshot = SessionSnapshot(
      sessionId: _sessionId,
      userId: _userId,
      userName: _userName,
      startedAt: _sessionStartedAt,
      lastAt: lastAt,
      amitabhaCount: _asrHitCount,
    );
    await _sessionRepo.upsertSnapshot(snapshot);

    final ymd = nowYmdLocal();
    await _dailyRepo.addCount(ymd, _userId, _userName, _asrHitCount);

    try {
      await syncToCloudBatch(snapshot, ymd, _asrHitCount);
    } catch (e) {
      debugPrint('cloud sync failed: $e');
    }

    setState(() {
      _asrHitCount = 0;
      _asrLastHitAt = null;
      _last = '';
      _index = 0;
    });

    _buffer = null;
    _hitLogger = null;
  }

  Future<void> _onSavePressed() async {
    if (_committing) return;
    setState(() => _committing = true);
    try {
      await _commitSession(reason: 'user_save');
    } catch (e) {
      debugPrint('Save failed: $e');
    } finally {
      if (mounted) setState(() => _committing = false);
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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _commitIfPending(reason: 'lifecycle_${state.name}');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _commitIfPending(reason: 'dispose');
    _recordSub?.cancel();
    _audioRecorder.dispose();
    _stream?.free();
    _recognizer?.free();
    _buffer?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 50),
        TextField(maxLines: 5, controller: _controller, readOnly: true),
        const SizedBox(height: 12),
        _asrCounterPanel(),
        const SizedBox(height: 38),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            RecordToggleButton(
              isRecording: _recordState != RecordState.stop,
              onStart: _start,
              onStop: _stop,
              disabled: _committing,
            ),
            const SizedBox(width: 20),
            _buildText(),
            const SizedBox(width: 20),
            SaveButton(
              enabled: _saveEnabled,
              loading: _committing,
              onPressed: _onSavePressed,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildText() {
    if (_recordState == RecordState.stop) {
      return const Text("Start");
    } else {
      return const Text("Stop");
    }
  }

  Widget _asrCounterPanel() {
    final ts = _asrLastHitAt != null
        ? _asrLastHitAt!
              .toLocal()
              .toIso8601String()
              .replaceFirst('T', ' ')
              .split('.')
              .first
        : '—';
    return Card(
      elevation: 0,
      color: Colors.amber.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'ASR 阿彌陀佛',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '累計：$_asrHitCount 聲',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  '最後：$ts',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
