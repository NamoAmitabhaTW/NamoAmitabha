import 'dart:io';
import 'package:path/path.dart' ;
import 'package:flutter/foundation.dart';

/// 只刪 deleteRelPaths 內列出的檔案（相對於 modelRoot）
Future<void> deleteSpecificFiles(
  String modelRoot,
  List<String> deleteRelPaths, {
  bool dryRun = false,
}) async {
  for (final rel in deleteRelPaths) {
    final abs = normalize(join(modelRoot, rel));

    // 保險：確保仍在 modelRoot 下
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

/// 各模型的「要刪除」清單（相對於 modelRoot）
const Map<String, List<String>> _deleteMap = {
  // 雙語 ASR（2023-02-20）
  'sherpa-onnx-streaming-zipformer-bilingual-zh-en-2023-02-20': [
    'encoder-epoch-99-avg-1.onnx', 
    'decoder-epoch-99-avg-1.int8.onnx',
    'joiner-epoch-99-avg-1.int8.onnx',
  ],

  // WenetSpeech ASR（20230615）
  'icefall-asr-zipformer-streaming-wenetspeech-20230615': [
    'exp/encoder-epoch-12-avg-4-chunk-16-left-128.onnx',
    'exp/decoder-epoch-12-avg-4-chunk-16-left-128.int8.onnx',
    'exp/joiner-epoch-12-avg-4-chunk-16-left-128.int8.onnx' // 刪浮點版，保留 int8 版
  ],

  // KWS（3.3M mobile）
  'sherpa-onnx-kws-zipformer-wenetspeech-3.3M-2024-01-01-mobile': [
    'encoder-epoch-12-avg-2-chunk-16-left-64.int8.onnx'
  ],
};

List<String> deleteListFor(String modelName) => _deleteMap[modelName] ?? const [];

/// 封裝：依 modelName 刪指定檔
Future<void> deleteSpecificFilesForModel({
  required String modelName,
  required String modelRoot,
  bool dryRun = false,
}) async {
  final list = deleteListFor(modelName);
  if (list.isEmpty) return; // 不認得的模型就不動（最安全）
  await deleteSpecificFiles(modelRoot, list, dryRun: dryRun);
}
