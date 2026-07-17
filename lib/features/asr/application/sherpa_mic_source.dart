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

import 'package:amitabha/core/utils/audio_convert.dart';
import 'package:amitabha/features/model_install/asr_hotwords.dart';
import 'package:amitabha/features/model_install/bundled_model.dart';
import 'package:amitabha/features/model_install/online_model.dart';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;

import 'asr_session_controller.dart' show SpeechSegmentSource, kAsrModelName;

Future<sherpa_onnx.OnlineRecognizer> createOnlineRecognizer(
  String modelName,
) async {
  // 內建模型:確保 assets 已複製到磁碟(冪等;首次以外皆為 no-op),
  // 之後 getModelConfigByModelName 指向的落地路徑才會存在。
  await materializeBundledModel(modelName);
  final localModelConfig = await getModelConfigByModelName(
    modelName: modelName,
  );
  // ⚠️ hotwords 檔裡的每個 token 都必須切得出「當前模型的 tokens.txt」裡的 piece,
  //    否則建 hotword graph 時會報錯甚至崩潰。此模型走 bpe(見 online_model.dart),
  //    中文須逐字空白分隔才會編成「▁字」;hotwords.txt 已依此格式撰寫。
  //    hotwords 必須搭配 modified_beam_search 解碼才會生效。
  final hotwordsPath = await materializeHotwordsFile();
  final config = sherpa_onnx.OnlineRecognizerConfig(
    model: localModelConfig,
    ruleFsts: '',
    decodingMethod: 'modified_beam_search',
    // 熱詞「只保留難辨變體」(見 assets/hotwords.txt):標準「阿弥陀佛」模型本來
    // 就聽得很準,對它加成反而會重複多吐(實測 10 聲被吐成 12);故主佛號不列入,
    // 只用低加成接住口音近音(欧米斗魂等)與日/梵/越/韓羅馬拼音念法。
    // hotwordsScore 是未標分數者的預設;目前每條都自帶低分,這裡放低值兜底。
    hotwordsFile: hotwordsPath,
    hotwordsScore: 1.0,
    enableEndpoint: true,
    maxActivePaths: 8,
    blankPenalty: 1.2,
    // 0.6 太短:念到一半的短停頓就觸發端點,把一句「omito」切成「omi」+「to」
    // 兩半都不成詞而掉數。拉到 1.0 讓端點別在字中間切(代價:段落收尾稍慢)。
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

  // ── 診斷用(排查梵/英漏辨識;確認病因後可整段移除) ──
  int _dbgDecodeMs = 0; // 累計解碼耗時
  double _dbgAudioMs = 0; // 累計餵入的音訊時長
  int _dbgEmptyEndpoints = 0; // 端點觸發但辨識為空(模型漏辨識)的次數

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

    // 診斷計數歸零,讓每次錄音的 RTF/空端點統計獨立
    _dbgDecodeMs = 0;
    _dbgAudioMs = 0;
    _dbgEmptyEndpoints = 0;

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

        // 診斷:量測解碼耗時 vs 音訊時長,累計算 RTF(即時率)。
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
          // RTF>1 代表解碼跟不上即時音訊 → 麥克風緩衝可能溢出丟音訊。
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
