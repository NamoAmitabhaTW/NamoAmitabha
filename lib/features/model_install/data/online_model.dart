// lib/features/model_install/data/online_model.dart
// This file is modified based on the open-source project:
// Flutter-EasySpeechRecognition (https://github.com/Jason-chen-coder/Flutter-EasySpeechRecognition)
// Original copyright (c) 2024 Xiaomi Corporation
import 'package:amitabha/features/model_install/data/model_paths.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;

Future<sherpa_onnx.OnlineModelConfig> getModelConfigByModelName({
  required String modelName,
}) async {
  final dir = await ModelPaths.modelDir(modelName);
  final modelDir = dir.path;
  switch (modelName) {
    case "sherpa-onnx-x-asr-960ms-streaming-zipformer-transducer-zh-en-punct-int8-2026-06-05":
      return sherpa_onnx.OnlineModelConfig(
        transducer: sherpa_onnx.OnlineTransducerModelConfig(
          encoder: '$modelDir/encoder.int8.onnx',
          decoder: '$modelDir/decoder.onnx',
          joiner: '$modelDir/joiner.int8.onnx',
        ),
        tokens: '$modelDir/tokens.txt',
        modelType: 'zipformer2',
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
