//amitabha/lib/online_model.dart
// This file is modified based on the open-source project:
// Flutter-EasySpeechRecognition (https://github.com/Jason-chen-coder/Flutter-EasySpeechRecognition)
// Original copyright (c) 2024 Xiaomi Corporation

import 'package:amitabha/storage/model_paths.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;

// ASR 
Future<sherpa_onnx.OnlineModelConfig> getModelConfigByModelName(
    {required String modelName}) async {
  final dir = await ModelPaths.modelDir(modelName);
  final modelDir = dir.path;
  switch (modelName) {
    // 內建(bundled)streaming zipformer transducer(中英,X-ASR 960ms)。
    // 檔案由 bundled_model.dart 從 assets 複製到 modelDir 後,這裡指向落地路徑。
    case "sherpa-onnx-x-asr-960ms-streaming-zipformer-transducer-zh-en-punct-int8-2026-06-05":
      return sherpa_onnx.OnlineModelConfig(
        transducer: sherpa_onnx.OnlineTransducerModelConfig(
          encoder: '$modelDir/encoder.int8.onnx',
          decoder: '$modelDir/decoder.onnx',
          joiner: '$modelDir/joiner.int8.onnx',
        ),
        tokens: '$modelDir/tokens.txt',
        // metadata: model_type = zipformer2(streaming)。
        modelType: 'zipformer2',
        // 此模型 tokens 全是 sentencepiece piece(中文皆為「▁字」,無裸中文字),
        // 所以 hotwords 一律走 bpe:sherpa 用 bpe.vocab 把熱詞切成 piece。
        // 注意 hotwords.txt 的中文須逐字以空白分隔(見 assets/hotwords.txt),
        // 這樣每個字才會編成「▁字」,與模型實際輸出的 token 對齊。
        modelingUnit: 'bpe',
        bpeVocab: '$modelDir/bpe.vocab',
      );
    case "sherpa-onnx-streaming-zipformer-bilingual-zh-en-2023-02-20":
      return sherpa_onnx.OnlineModelConfig(
        transducer: sherpa_onnx.OnlineTransducerModelConfig(
          encoder: '$modelDir/encoder-epoch-99-avg-1.int8.onnx',
          decoder: '$modelDir/decoder-epoch-99-avg-1.onnx',
          joiner: '$modelDir/joiner-epoch-99-avg-1.onnx',
        ),
        tokens: '$modelDir/tokens.txt',
        modelType: 'zipformer',
      );
    default:
      throw ArgumentError('Unsupported modelName: $modelName');
  }
}