// This file is modified based on the open-source project:
// Flutter-EasySpeechRecognition (https://github.com/Jason-chen-coder/Flutter-EasySpeechRecognition)
// Original copyright (c) 2024 Xiaomi Corporation

import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;

// ASR 
Future<sherpa_onnx.OnlineModelConfig> getModelConfigByModelName(
    {required String modelName}) async {
  final Directory directory = await getApplicationDocumentsDirectory();
  final modulePath = join(directory.path, modelName);
  final modelDir = modulePath;
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

// KWS 
Future<sherpa_onnx.KeywordSpotterConfig> getKwsConfigByModelName({
  required String modelName,
  required String keywordsFilePath,     
  double keywordsScore = 1.0,
  double keywordsThreshold = 0.25,
}) async {
  final Directory dir = await getApplicationDocumentsDirectory();
  final root = join(dir.path, modelName);

  final encoder = join(root, 'encoder-epoch-12-avg-2-chunk-16-left-64.onnx');
  final decoder = join(root, 'decoder-epoch-12-avg-2-chunk-16-left-64.onnx');    
  final joiner  = join(root, 'joiner-epoch-12-avg-2-chunk-16-left-64.int8.onnx');
  final tokens  = join(root, 'tokens.txt');

  final model = sherpa_onnx.OnlineModelConfig(
    transducer: sherpa_onnx.OnlineTransducerModelConfig(
      encoder: encoder,
      decoder: decoder,
      joiner : joiner,
    ),
    tokens: tokens,
    modelType: 'zipformer2',   
  );

  return sherpa_onnx.KeywordSpotterConfig(
    model: model,
    keywordsFile: keywordsFilePath,
    keywordsScore: keywordsScore,
    keywordsThreshold: keywordsThreshold,
    maxActivePaths: 4,
    numTrailingBlanks: 1,
  );
}