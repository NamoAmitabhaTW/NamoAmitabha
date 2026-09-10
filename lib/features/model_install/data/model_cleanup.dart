// lib/features/model_install/data/model_cleanup.dart
import 'dart:io';
import 'package:amitabha/storage/model_paths.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';

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
  'sherpa-onnx-streaming-zipformer-bilingual-zh-en-2023-02-20': [
    'encoder-epoch-99-avg-1.onnx',
    'decoder-epoch-99-avg-1.int8.onnx',
    'joiner-epoch-99-avg-1.int8.onnx',
  ],

  'icefall-asr-zipformer-streaming-wenetspeech-20230615': [
    'exp/encoder-epoch-12-avg-4-chunk-16-left-128.onnx',
    'exp/decoder-epoch-12-avg-4-chunk-16-left-128.int8.onnx',
    'exp/joiner-epoch-12-avg-4-chunk-16-left-128.int8.onnx',
  ],
};

List<String> deleteListFor(String modelName) =>
    _deleteMap[modelName] ?? const [];

Future<void> deleteSpecificFilesForModel({
  required String modelName,
  required String modelRoot,
  bool dryRun = false,
}) async {
  final list = deleteListFor(modelName);
  if (list.isEmpty) return;
  await deleteSpecificFiles(modelRoot, list, dryRun: dryRun);
}

const List<String> obsoleteModelDirs = <String>[
  'sherpa-onnx-streaming-zipformer-bilingual-zh-en-2023-02-20',
];

Future<void> purgeObsoleteModels({bool dryRun = false}) async {
  final Directory root;
  try {
    root = await ModelPaths.root();
  } catch (_) {
    return;
  }
  for (final name in obsoleteModelDirs) {
    final dir = Directory(join(root.path, name));
    if (!isWithin(root.path, dir.path)) continue;
    if (!await dir.exists()) continue;
    if (dryRun) {
      if (kDebugMode) {
        debugPrint('[dryRun] would delete model dir: ${dir.path}');
      }
      continue;
    }
    try {
      await dir.delete(recursive: true);
      if (kDebugMode) debugPrint('deleted obsolete model dir: ${dir.path}');
    } catch (e) {
      if (kDebugMode) debugPrint('delete model dir failed: ${dir.path} -> $e');
    }
  }
}
