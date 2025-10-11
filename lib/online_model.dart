// This file is modified based on the open-source project:
// Flutter-EasySpeechRecognition (https://github.com/Jason-chen-coder/Flutter-EasySpeechRecognition)
// Original copyright (c) 2024 Xiaomi Corporation

import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;
import 'package:amitabha/storage/model_paths.dart';

// ASR 
Future<sherpa_onnx.OnlineModelConfig> getModelConfigByModelName(
    {required String modelName}) async {
  final dir = await ModelPaths.modelDir(modelName);
  final modelDir = dir.path;
  switch (modelName) {
    case "icefall-asr-zipformer-streaming-wenetspeech-20230615":
      return sherpa_onnx.OnlineModelConfig(
        transducer: sherpa_onnx.OnlineTransducerModelConfig(
          encoder: '$modelDir/exp/encoder-epoch-12-avg-4-chunk-16-left-128.int8.onnx',
          decoder: '$modelDir/exp/decoder-epoch-12-avg-4-chunk-16-left-128.onnx',
          joiner: '$modelDir/exp/joiner-epoch-12-avg-4-chunk-16-left-128.onnx'
        ),
        tokens: '$modelDir/tokens.txt',
        modelType: 'zipformer',
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