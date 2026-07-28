// lib/features/model_install/bundled_model.dart

import 'dart:io';
import 'package:amitabha/features/model_install/model_cleanup.dart';
import 'package:amitabha/storage/backup_exclusion.dart';
import 'package:amitabha/storage/model_paths.dart';
import 'package:flutter/services.dart';

const String _assetDir =
    'assets/sherpa-onnx';

const List<String> bundledModelFiles = <String>[
  'encoder.int8.onnx',
  'decoder.onnx',
  'joiner.int8.onnx',
  'tokens.txt',
  'bpe.vocab',
];

Future<bool> bundledModelReady(String modelName) async {
  final dir = await ModelPaths.modelDir(modelName);
  for (final name in bundledModelFiles) {
    final f = File('${dir.path}/$name');
    if (!await f.exists() || await f.length() == 0) return false;
  }
  return true;
}


Future<Directory> materializeBundledModel(
  String modelName, {
  void Function(double progress)? onProgress,
}) async {
  final dir = await ModelPaths.modelDir(modelName);
  await purgeObsoleteModels();
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
  } else {
    var written = 0;
    for (final entry in pending.entries) {
      final data = entry.value;
      final bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await File('${dir.path}/${entry.key}').writeAsBytes(bytes, flush: true);
      written += data.lengthInBytes;
      if (totalBytes > 0) onProgress?.call(written / totalBytes);
    }
  }
  await excludeFromICloudBackup(dir.path);
  return dir;
}
