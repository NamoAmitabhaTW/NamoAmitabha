//amitabha/lib/model_cleanup.dart
import 'dart:io';
import 'package:path/path.dart' ;
import 'package:flutter/foundation.dart';

Future<void> deleteSpecificFiles(
  String modelRoot,
  List<String> deleteRelPaths, {
  bool dryRun = false,
}) async {
  for (final rel in deleteRelPaths) {
    final abs = normalize(join(modelRoot, rel));


    final inRoot = isWithin(modelRoot, abs);
    if (!inRoot) continue;

    final f = File(abs);
    if (await f.exists()) {
      if (dryRun) {  
        if (kDebugMode) debugPrint('[dryRun] would delete: $abs');
      } else {
        try {
          await f.delete();
          if (kDebugMode) debugPrint('deleted: $abs');
        } catch (e) {
          if (kDebugMode) debugPrint('delete failed: $abs -> $e');
        }
      }
    }
  }
}


const Map<String, List<String>> _deleteMap = {
  // 雙語 ASR（2023-02-20）
  'sherpa-onnx-streaming-zipformer-bilingual-zh-en-2023-02-20': [
    'encoder-epoch-99-avg-1.int8.onnx', 
    'decoder-epoch-99-avg-1.int8.onnx',
    'joiner-epoch-99-avg-1.int8.onnx',
  ],

  // WenetSpeech ASR（20230615）
  'icefall-asr-zipformer-streaming-wenetspeech-20230615': [
    'exp/encoder-epoch-12-avg-4-chunk-16-left-128.onnx',
    'exp/decoder-epoch-12-avg-4-chunk-16-left-128.int8.onnx',
    'exp/joiner-epoch-12-avg-4-chunk-16-left-128.int8.onnx' 
  ],

  // KWS（3.3M mobile）
  'sherpa-onnx-kws-zipformer-wenetspeech-3.3M-2024-01-01-mobile': [
    'encoder-epoch-12-avg-2-chunk-16-left-64.int8.onnx'
  ],
};

List<String> deleteListFor(String modelName) => _deleteMap[modelName] ?? const [];

Future<void> deleteSpecificFilesForModel({
  required String modelName,
  required String modelRoot,
  bool dryRun = false,
}) async {
  final list = deleteListFor(modelName);
  if (list.isEmpty) return; 
  await deleteSpecificFiles(modelRoot, list, dryRun: dryRun);
}
