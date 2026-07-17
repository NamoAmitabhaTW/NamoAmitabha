// lib/features/model_install/bundled_model.dart
// 內建模型:App 打包時就帶著模型檔(放在 assets/sherpa-onnx/),
// 首次使用時把 asset 複製到磁碟。
//
// 為什麼要複製:sherpa-onnx 只吃「真實檔案路徑」,無法直接讀 Flutter 的
// asset bundle。因此即使模型是內建的,仍要先把它落地成檔案,再把路徑交給
// online_model.dart。複製具冪等性:檔案已存在且非空就跳過,不會每次重抄。

import 'dart:io';

import 'package:amitabha/storage/model_paths.dart';
import 'package:flutter/services.dart';

/// asset 目錄(pubspec.yaml 的 flutter.assets 需登錄同一路徑)。
/// 指向內建串流模型的子資料夾;換模型時這裡與下方檔名清單一起改。
const String _assetDir =
    'assets/sherpa-onnx';

/// 內建模型的檔名清單。asset 端與落地端使用相同檔名。
/// 新增/更換模型檔時,這份清單、pubspec.yaml、online_model.dart 三處要同步。
const List<String> bundledModelFiles = <String>[
  'encoder.int8.onnx',
  'decoder.onnx',
  'joiner.int8.onnx',
  'tokens.txt',
  // hotwords 用:此模型的 token 全是 sentencepiece piece(中文皆為「▁字」,
  // 沒有裸中文字),所以 hotwords 走 modelingUnit=bpe,需要這份由 bpe.model
  // 匯出的 vocab(見 online_model.dart 的 bpeVocab)。
  'bpe.vocab',
];

/// 內建模型是否已完整落地到磁碟(所有檔案存在且非空)。
Future<bool> bundledModelReady(String modelName) async {
  final dir = await ModelPaths.modelDir(modelName);
  for (final name in bundledModelFiles) {
    final f = File('${dir.path}/$name');
    if (!await f.exists() || await f.length() == 0) return false;
  }
  return true;
}

/// 確保內建模型已複製到磁碟,回傳模型所在目錄。
///
/// - 冪等:已存在且非空的檔案會跳過。
/// - [onProgress] 依「累積位元組 / 總位元組」回報 0.0~1.0(以各檔實際大小加權,
///   encoder 佔絕大多數;單一檔在載入當下無法再細分進度)。
Future<Directory> materializeBundledModel(
  String modelName, {
  void Function(double progress)? onProgress,
}) async {
  final dir = await ModelPaths.modelDir(modelName);

  // 先算出「需要複製的檔案」與其總位元組,才能回報加權進度。
  final pending = <String, ByteData>{};
  var totalBytes = 0;
  for (final name in bundledModelFiles) {
    final dest = File('${dir.path}/$name');
    if (await dest.exists() && await dest.length() > 0) continue;
    final data = await rootBundle.load('$_assetDir/$name');
    pending[name] = data;
    totalBytes += data.lengthInBytes;
  }

  if (pending.isEmpty) {
    onProgress?.call(1.0);
    return dir;
  }

  var written = 0;
  for (final entry in pending.entries) {
    final data = entry.value;
    final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    await File('${dir.path}/${entry.key}').writeAsBytes(bytes, flush: true);
    written += data.lengthInBytes;
    if (totalBytes > 0) onProgress?.call(written / totalBytes);
  }
  return dir;
}
