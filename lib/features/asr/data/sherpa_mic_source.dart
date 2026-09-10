// lib/features/asr/data/sherpa_mic_source.dart
// This file is modified based on the open-source project:
// Flutter-EasySpeechRecognition (https://github.com/Jason-chen-coder/Flutter-EasySpeechRecognition)
// Original copyright (c) 2024 Xiaomi Corporation
import 'dart:async';
import 'package:amitabha/core/utils/audio_convert.dart';
import 'package:amitabha/features/asr/application/asr_session_controller.dart'
    show SpeechSegmentSource, kAsrModelName;
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

  int _dbgDecodeMs = 0;
  double _dbgAudioMs = 0;
  int _dbgEmptyEndpoints = 0;

  @override
  Future<bool> hasPermission() => _recorder.hasPermission();

  @override
  Future<void> start({required void Function(String text) onSegment}) async {
    if (_running) return;

    if (_recognizer == null) {
      sherpa_onnx.initBindings();
      _recognizer = await createOnlineRecognizer(modelName);
    }
    _stream ??= _recognizer!.createStream();

    const encoder = AudioEncoder.pcm16bits;
    if (!await _isEncoderSupported(encoder)) return;

    const config = RecordConfig(
      encoder: encoder,
      sampleRate: _sampleRate,
      numChannels: 1,
    );
    final audio = await _recorder.startStream(config);

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

  @override
  Future<void> stop() async {
    if (!_running) return;
    _running = false;
    await _subscription?.cancel();
    _subscription = null;
    try {
      await _recorder.stop();
    } catch (_) {}

    _stream?.free();
    _stream = _recognizer?.createStream();
  }

  @override
  Future<void> dispose() async {
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
