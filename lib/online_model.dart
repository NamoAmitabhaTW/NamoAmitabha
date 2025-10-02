// This file is modified based on the open-source project:
// Flutter-EasySpeechRecognition (https://github.com/Jason-chen-coder/Flutter-EasySpeechRecognition)
// Original copyright (c) 2024 Xiaomi Corporation

import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;
import 'utils.dart';

Future<sherpa_onnx.OnlineModelConfig> getOnlineModelConfig(
    {required int type}) async {
  switch (type) {
    case 0:
      final modelDir =
          'assets/sherpa-onnx-streaming-zipformer-bilingual-zh-en-2023-02-20';
      return sherpa_onnx.OnlineModelConfig(
        transducer: sherpa_onnx.OnlineTransducerModelConfig(
          encoder:
              await copyAssetFile('$modelDir/encoder-epoch-99-avg-1.int8.onnx'),
          decoder: await copyAssetFile('$modelDir/decoder-epoch-99-avg-1.onnx'),
          joiner: await copyAssetFile('$modelDir/joiner-epoch-99-avg-1.onnx'),
        ),
        tokens: await copyAssetFile('$modelDir/tokens.txt'),
        modelType: 'zipformer',
      );
    case 1:
      final modelDir = 'assets/sherpa-onnx-streaming-zipformer-en-2023-06-26';
      return sherpa_onnx.OnlineModelConfig(
        transducer: sherpa_onnx.OnlineTransducerModelConfig(
          encoder: await copyAssetFile(
              '$modelDir/encoder-epoch-99-avg-1-chunk-16-left-128.int8.onnx'),
          decoder: await copyAssetFile(
              '$modelDir/decoder-epoch-99-avg-1-chunk-16-left-128.onnx'),
          joiner: await copyAssetFile(
              '$modelDir/joiner-epoch-99-avg-1-chunk-16-left-128.onnx'),
        ),
        tokens: await copyAssetFile('$modelDir/tokens.txt'),
        modelType: 'zipformer2',
      );
    case 2:
      final modelDir =
          'assets/icefall-asr-zipformer-streaming-wenetspeech-20230615';
      return sherpa_onnx.OnlineModelConfig(
        transducer: sherpa_onnx.OnlineTransducerModelConfig(
          encoder: await copyAssetFile(
              '$modelDir/exp/encoder-epoch-12-avg-4-chunk-16-left-128.int8.onnx'),
          decoder: await copyAssetFile(
              '$modelDir/exp/decoder-epoch-12-avg-4-chunk-16-left-128.onnx'),
          joiner: await copyAssetFile(
              '$modelDir/exp/joiner-epoch-12-avg-4-chunk-16-left-128.onnx'),
        ),
        tokens: await copyAssetFile('$modelDir/data/lang_char/tokens.txt'),
        modelType: 'zipformer2',
      );
    case 3:
      final modelDir = 'assets/sherpa-onnx-streaming-zipformer-fr-2023-04-14';
      return sherpa_onnx.OnlineModelConfig(
        transducer: sherpa_onnx.OnlineTransducerModelConfig(
          encoder: await copyAssetFile(
              '$modelDir/encoder-epoch-29-avg-9-with-averaged-model.int8.onnx'),
          decoder: await copyAssetFile(
              '$modelDir/decoder-epoch-29-avg-9-with-averaged-model.onnx'),
          joiner: await copyAssetFile(
              '$modelDir/joiner-epoch-29-avg-9-with-averaged-model.onnx'),
        ),
        tokens: await copyAssetFile('$modelDir/tokens.txt'),
        modelType: 'zipformer',
      );
    default:
      throw ArgumentError('Unsupported type: $type');
  }
}

// ARS ：sherpa-onnx-streaming-zipformer-bilingual-zh-en-2023-02-20
Future<sherpa_onnx.OnlineModelConfig> getModelConfigByModelName(
    {required String modelName}) async {
  final Directory directory = await getApplicationDocumentsDirectory();
  final modulePath = join(directory.path, modelName);
  switch (modelName) {
    case "sherpa-onnx-streaming-zipformer-bilingual-zh-en-2023-02-20":
      final modelDir = modulePath;
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

// KWS ：sherpa-onnx-kws-zipformer-wenetspeech-3.3M-2024-01-01-mobile
Future<sherpa_onnx.KeywordSpotterConfig> getKwsConfigByModelName({
  required String modelName,
  required String keywordsFilePath,     
  double keywordsScore = 1.0,
  double keywordsThreshold = 0.25,
}) async {
  final Directory dir = await getApplicationDocumentsDirectory();
  final root = join(dir.path, modelName);

  final encoder = join(root, 'encoder-epoch-12-avg-2-chunk-16-left-64.int8.onnx');
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