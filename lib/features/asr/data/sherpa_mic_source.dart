// lib/features/asr/data/sherpa_mic_source.dart
// This file is modified based on the open-source project:
// Flutter-EasySpeechRecognition (https://github.com/Jason-chen-coder/Flutter-EasySpeechRecognition)
// Original copyright (c) 2024 Xiaomi Corporation
import 'dart:async';
import 'package:amitabha/core/utils/audio_convert.dart';
import 'package:amitabha/features/asr/application/asr_session_controller.dart'
    show kAsrModelName;
import 'package:amitabha/features/asr/domain/speech_segment_source.dart';
import 'package:amitabha/features/model_install/model_install.dart';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;

Future<sherpa_onnx.OnlineRecognizer> createOnlineRecognizer(
  String modelName,
) async {
  await materializeBundledModel(modelName);
  final localModelConfig = await getModelConfigByModelName(
    modelName: modelName,
  );
  final hotwordsPath = await materializeHotwordsFile();
  final config = sherpa_onnx.OnlineRecognizerConfig(
    model: localModelConfig,
    ruleFsts: '',
    decodingMethod: 'modified_beam_search',
    hotwordsFile: hotwordsPath,
    hotwordsScore: 1.0,
    enableEndpoint: true,
    maxActivePaths: 8,
    blankPenalty: 0.0,
    rule2MinTrailingSilence: 1.0,
    rule3MinUtteranceLength: 20,
  );

  return sherpa_onnx.OnlineRecognizer(config);
}

class SherpaMicSource implements SpeechSegmentSource {
  SherpaMicSource({this.modelName = kAsrModelName});

  final String modelName;

  static const int _sampleRate = 16000;

  late final AudioRecorder _recorder = AudioRecorder();
  sherpa_onnx.OnlineRecognizer? _recognizer;
  sherpa_onnx.OnlineStream? _stream;
  StreamSubscription<Uint8List>? _subscription;
  bool _running = false;

  // start() only flips _running once the model is loaded and the stream is
  // open, which takes seconds on the first run. Without these two, a stop()
  // arriving in that window sees _running == false, returns, and start() then
  // opens the microphone behind a UI that already says it stopped.
  bool _stopRequested = false;
  Future<void> _queue = Future.value();

  int _dbgDecodeMs = 0;
  double _dbgAudioMs = 0;
  int _dbgEmptyEndpoints = 0;

  @override
  Future<bool> hasPermission() => _recorder.hasPermission();

  /// Runs [op] after everything already queued, so a stop can never overtake
  /// a start that is still loading.
  Future<void> _serialize(Future<void> Function() op) {
    final next = _queue.then((_) => op());
    _queue = next.catchError((_) {});
    return next;
  }

  @override
  Future<void> start({required void Function(String text) onSegment}) {
    _stopRequested = false;
    return _serialize(() => _start(onSegment: onSegment));
  }

  @override
  Future<void> stop() {
    _stopRequested = true;
    return _serialize(_stop);
  }

  @override
  Future<void> dispose() {
    _stopRequested = true;
    return _serialize(_dispose);
  }

  Future<void> _start({required void Function(String text) onSegment}) async {
    if (_running) return;

    if (_recognizer == null) {
      sherpa_onnx.initBindings();
      _recognizer = await createOnlineRecognizer(modelName);
    }
    if (_stopRequested) return;

    _stream ??= _recognizer!.createStream();

    const encoder = AudioEncoder.pcm16bits;
    if (!await _isEncoderSupported(encoder)) return;
    if (_stopRequested) return;

    const config = RecordConfig(
      encoder: encoder,
      sampleRate: _sampleRate,
      numChannels: 1,
    );
    final audio = await _recorder.startStream(config);

    // The stream is open now, so a stop that arrived while it was opening has
    // to release the microphone rather than just walk away from it.
    if (_stopRequested) {
      try {
        await _recorder.stop();
      } catch (e) {
        debugPrint('[ASR] recorder stop failed: $e');
      }
      return;
    }

    _dbgDecodeMs = 0;
    _dbgAudioMs = 0;
    _dbgEmptyEndpoints = 0;

    _running = true;
    _subscription = audio.listen((data) {
      if (!_running) return;
      final recognizer = _recognizer;
      final stream = _stream;
      if (recognizer == null || stream == null) return;

      final samples = convertBytesToFloat32(Uint8List.fromList(data));
      stream.acceptWaveform(samples: samples, sampleRate: _sampleRate);

      final sw = Stopwatch()..start();
      while (recognizer.isReady(stream)) {
        recognizer.decode(stream);
      }
      sw.stop();
      _dbgDecodeMs += sw.elapsedMilliseconds;
      _dbgAudioMs += samples.length / _sampleRate * 1000;

      final text = recognizer.getResult(stream).text;
      if (recognizer.isEndpoint(stream)) {
        recognizer.reset(stream);
        final rtf = _dbgAudioMs > 0 ? _dbgDecodeMs / _dbgAudioMs : 0;
        final rtfStr = rtf.toStringAsFixed(2);
        if (text != '') {
          debugPrint('[ASR] =$text  [RTF=$rtfStr]');
          onSegment(text);
        } else {
          _dbgEmptyEndpoints++;
          debugPrint(
            '[ASR] (空端點#$_dbgEmptyEndpoints — 有端點但辨識為空,模型漏辨識或未出聲)  [RTF=$rtfStr]',
          );
        }
      }
    }, onDone: () => debugPrint('[ASR] audio stream done'));
  }

  Future<void> _stop() async {
    if (!_running) return;
    _running = false;
    await _subscription?.cancel();
    _subscription = null;
    try {
      await _recorder.stop();
    } catch (e) {
      debugPrint('[ASR] recorder stop failed: $e');
    }

    _stream?.free();
    _stream = _recognizer?.createStream();
  }

  Future<void> _dispose() async {
    _running = false;
    await _subscription?.cancel();
    _subscription = null;
    try {
      await _recorder.dispose();
    } catch (_) {}
    _stream?.free();
    _stream = null;
    _recognizer?.free();
    _recognizer = null;
  }

  Future<bool> _isEncoderSupported(AudioEncoder encoder) async {
    final isSupported = await _recorder.isEncoderSupported(encoder);

    if (!isSupported) {
      debugPrint('${encoder.name} is not supported on this platform.');
      debugPrint('Supported encoders are:');
      for (final e in AudioEncoder.values) {
        if (await _recorder.isEncoderSupported(e)) {
          debugPrint('- ${e.name}');
        }
      }
    }
    return isSupported;
  }
}
