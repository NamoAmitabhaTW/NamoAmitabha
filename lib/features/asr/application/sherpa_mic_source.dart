// lib/features/asr/application/sherpa_mic_source.dart
// SpeechSegmentSource 的正式實作:麥克風串流 → sherpa-onnx 即時辨識。
//
// 生命週期安全(修正舊版的 use-after-free 隱患):
// - 音訊訂閱(StreamSubscription)保存為成員,stop() 時「先 cancel 訂閱、
//   再停錄音器,最後才釋放/重建 native stream」——確保釋放當下不再有
//   音訊 callback 會碰到已釋放的 native 資源。
// - callback 內以 _running 旗標 + 區域變數快照防禦遲到的事件。
//
// This file is modified based on the open-source project:
// Flutter-EasySpeechRecognition (https://github.com/Jason-chen-coder/Flutter-EasySpeechRecognition)
// Original copyright (c) 2024 Xiaomi Corporation

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;

import 'package:amitabha/core/utils/audio_convert.dart';
import 'package:amitabha/features/model_install/asr_hotwords.dart';
import 'package:amitabha/features/model_install/online_model.dart';
import 'asr_session_controller.dart' show SpeechSegmentSource, kAsrModelName;

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

class SherpaMicSource implements SpeechSegmentSource {
  SherpaMicSource({this.modelName = kAsrModelName});

  final String modelName;

  static const int _sampleRate = 16000;

  late final AudioRecorder _recorder = AudioRecorder();
  sherpa_onnx.OnlineRecognizer? _recognizer;
  sherpa_onnx.OnlineStream? _stream;
  StreamSubscription<Uint8List>? _subscription;
  bool _running = false;

  @override
  Future<bool> hasPermission() => _recorder.hasPermission();

  @override
  Future<void> start({
    required void Function(String text) onSegment,
  }) async {
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

    _running = true;
    _subscription = audio.listen(
      (data) {
        // 快照 + 旗標:訂閱取消後若還有遲到的事件,不碰任何 native 資源
        if (!_running) return;
        final recognizer = _recognizer;
        final stream = _stream;
        if (recognizer == null || stream == null) return;

        final samples = convertBytesToFloat32(Uint8List.fromList(data));
        stream.acceptWaveform(samples: samples, sampleRate: _sampleRate);
        while (recognizer.isReady(stream)) {
          recognizer.decode(stream);
        }
        final text = recognizer.getResult(stream).text;
        if (recognizer.isEndpoint(stream)) {
          recognizer.reset(stream);
          if (text != '') {
            debugPrint('[ASR] =$text');
            onSegment(text);
          }
        }
      },
      onDone: () => debugPrint('[ASR] audio stream done'),
    );
  }

  @override
  Future<void> stop() async {
    if (!_running) return;
    _running = false;

    // 順序很重要:先斷資料流,確定沒有 callback 在跑,才動 native stream
    await _subscription?.cancel();
    _subscription = null;
    try {
      await _recorder.stop();
    } catch (_) {}

    _stream?.free();
    _stream = _recognizer?.createStream(); // 重建,下次續錄從乾淨狀態開始
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
