//amitabha/lib/utils.dart
// This file is modified based on the open-source project:
// Flutter-EasySpeechRecognition (https://github.com/Jason-chen-coder/Flutter-EasySpeechRecognition)
// Original copyright (c) 2024 Xiaomi Corporation

import "dart:io";
import 'dart:async';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'download_model.dart';
import 'model_cleanup.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'widgets/download_progress_dialog.dart';
import 'package:amitabha/storage/model_paths.dart';
import 'package:amitabha/l10n/generated/app_localizations.dart';

Float32List convertBytesToFloat32(
  Uint8List bytes, [
  Endian endian = Endian.little,
]) {
  final pairCount = bytes.length >> 1;
  if (pairCount == 0) return Float32List(0);

  final out = Float32List(pairCount);
  final data = ByteData.sublistView(bytes);

  for (int j = 0, i = 0; j < pairCount; j++, i += 2) {
    final s = data.getInt16(i, endian);
    out[j] = s / 32768.0;
  }
  return out;
}

Future<void> downloadModelAndUnZip(
  BuildContext context,
  String modelName,
) async {
  final store = Provider.of<DownloadModel>(context, listen: false);
  final channel = store.channel;
  final fileName = ModelPaths.archiveFileName(modelName);
  final downLoadUrl =
      'https://github.com/k2-fsa/sherpa-onnx/releases/download/$channel/$fileName';
  final downloadModel = Provider.of<DownloadModel>(context, listen: false);

  final destinationRoot = (await ModelPaths.root()).path;
  final modulePath = join(destinationRoot, modelName);

  final archive = await ModelPaths.archiveFile(modelName);
  final moduleZipFilePath = archive.path;

  final moduleExists = await Directory(modulePath).exists();
  final moduleZipExists = await File(moduleZipFilePath).exists();

  if (moduleExists) {
    return;
  }

  if (!moduleExists && !moduleZipExists) {
    bool confirmed = await _showDownloadConfirmationDialog(context);
    if (!confirmed) {
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return DownloadProgressDialog();
      },
    );

    try {
      final client = http.Client();
      try {
        final request = http.Request('GET', Uri.parse(downLoadUrl));
        request.headers['User-Agent'] = 'AmitabhaApp/1.0';
        final response = await client.send(request);

        int totalBytes = response.contentLength ?? 0;
        int receivedBytes = 0;

        final sink = File(moduleZipFilePath).openWrite();

        await response.stream.forEach((List<int> chunk) {
          sink.add(chunk);
          receivedBytes += chunk.length;
          double progress = totalBytes > 0 ? receivedBytes / totalBytes : 0;
          downloadModel.setProgress(progress);
        });

        await sink.flush();
        await sink.close();

        await _unzipDownloadedFile(moduleZipFilePath, destinationRoot, context);
      } finally {
        client.close();
      }
    } catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      try {
        if (await File(moduleZipFilePath).exists()) {
          await File(moduleZipFilePath).delete();
        }
      } catch (_) {}

      downloadModel.reset();

      await _showRetryDownloadDialog(
        context,
        onRetryDownload: () => downloadModelAndUnZip(context, modelName),
      );
    }
  }
}

Future<bool> _showDownloadConfirmationDialog(BuildContext context) async {
  final downloadModel = Provider.of<DownloadModel>(context, listen: false);
  final modelName = downloadModel.modelName;
  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          final t = AppLocalizations.of(context); // 防止父層 context 失效
          return AlertDialog(
            title: Text(t.downloadRequiredTitle),
            content: Text(t.downloadRequiredBody(modelName)),
            actions: <Widget>[
              TextButton(
                child: Text(t.cancel),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
              TextButton(
                child: Text(t.download),
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
              ),
            ],
          );
        },
      ) ??
      false;
}

Future<void> unzipModelFile(BuildContext context, String modelName) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return DownloadProgressDialog();
    },
  );
  final moduleZipFilePath = (await ModelPaths.archiveFile(modelName)).path;
  final downloadModel = Provider.of<DownloadModel>(context, listen: false);
  try {
    final destinationRoot = (await ModelPaths.root()).path;
    await _unzipDownloadedFile(moduleZipFilePath, destinationRoot, context);
  } catch (e) {
    if (Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }

    if (_looksLikeDiskFull(e)) {
      downloadModel.setUnzipProgress(0.0);
      final destinationRoot = (await ModelPaths.root()).path;
      await _showRetryUnzipOnlyDialog(
        context,
        zipFilePath: moduleZipFilePath,
        destinationRoot: destinationRoot,
      );
    } else {
      downloadModel.reset();
      try {
        await File(moduleZipFilePath).delete();
      } catch (_) {}
      await _showRetryDownloadDialog(
        context,
        onRetryDownload: () => downloadModelAndUnZip(context, modelName),
      );
    }
  }
}

Future<bool> needsDownload(String modelName) async {
  final destinationRoot = (await ModelPaths.root()).path;
  final modulePath = join(destinationRoot, modelName);
  final moduleZipFilePath = (await ModelPaths.archiveFile(modelName)).path;

  final moduleExists = await Directory(modulePath).exists();
  final moduleZipExists = await File(moduleZipFilePath).exists();

  debugPrint(
    'needsDownload: moduleExists=$moduleExists, moduleZipExists=$moduleZipExists',
  );
  return !moduleExists && !moduleZipExists;
}

Future<bool> needsUnZip(String modelName) async {
  final destinationRoot = (await ModelPaths.root()).path;
  final modulePath = join(destinationRoot, modelName);
  final moduleZipFilePath = (await ModelPaths.archiveFile(modelName)).path;

  final moduleExists = await Directory(modulePath).exists();
  final moduleZipExists = await File(moduleZipFilePath).exists();

  return moduleZipExists && !moduleExists;
}

void _showSuccessDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      final t = AppLocalizations.of(context);
      return AlertDialog(
        title: Text(t.successTitle),
        content: Text(t.successBody),
        actions: <Widget>[
          TextButton(
            child: Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

//確認磁碟儲存空間是否足夠
bool _looksLikeDiskFull(Object e) {
  if (e is FileSystemException) {
    final msg = (e.osError?.message ?? e.message).toLowerCase();
    return msg.contains('no space left') || msg.contains('enospc');
  }
  // Android 有時候訊息會不同，可再擴充
  return false;
}

Future<void> _showRetryUnzipOnlyDialog(
  BuildContext context, {
  required String zipFilePath,
  required String destinationRoot,
}) async {
  final t = AppLocalizations.of(context);
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      title: Text(t.unzipFailedTitle), // 例：解壓縮失敗
      content: Text(t.unzipFailedLowSpaceBody), // 例：可能是空間不足...
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.close),
        ),
        TextButton(
          onPressed: () async {
            Navigator.of(context).pop();
            // 直接再解壓一次（保留 zip）
            await _unzipDownloadedFile(zipFilePath, destinationRoot, context);
          },
          child: Text(t.retryUnzip), // 例：重試解壓
        ),
      ],
    ),
  );
}

Future<void> _showRetryDownloadDialog(
  BuildContext context, {
  required VoidCallback onRetryDownload,
}) async {
  final t = AppLocalizations.of(context);
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      title: Text(t.downloadFailedTitle), // 下載失敗
      content: Text(t.downloadFailedShort), // 模型下載失敗，請重試或稍後再試
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.close),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onRetryDownload();
          },
          child: Text(t.retry), // 重新下載
        ),
      ],
    ),
  );
}

class UnzipParams {
  final String zipFilePath;
  final String destinationPath;

  UnzipParams(this.zipFilePath, this.destinationPath);
}

Future<List<dynamic>> _decompressInIsolate(UnzipParams params) async {
  final bytes = File(params.zipFilePath).readAsBytesSync();

  final archive = BZip2Decoder().decodeBytes(bytes);

  final tarArchive = TarDecoder().decodeBytes(archive);

  return [archive, tarArchive.files];
}

Future<void> _extractFileInIsolate(Map<String, dynamic> params) async {
  final file = params['file'] as ArchiveFile;
  final destinationPath = params['destinationPath'] as String;
  final filename = file.name;

  if (file.isFile) {
    final data = file.content as List<int>;
    File(join(destinationPath, filename))
      ..createSync(recursive: true)
      ..writeAsBytesSync(data);
  } else {
    Directory(join(destinationPath, filename)).create(recursive: true);
  }
}

Future<void> _unzipDownloadedFile(
  String zipFilePath,
  String destinationPath,
  BuildContext context,
) async {
  final downloadModel = Provider.of<DownloadModel>(context, listen: false);
  downloadModel.setUnzipProgress(0.01);

  // === 平滑假進度：0.10 → 0.39，每秒 +0.01 ===
  Timer? smoothTimer;
  smoothTimer = Timer.periodic(const Duration(seconds: 4), (_) {
    final cur = downloadModel.unzipProgress;
    // 如果已經被真實進度推到 0.39 以上，就停掉
    if (cur >= 0.59) {
      smoothTimer?.cancel();
      return;
    }
    final next = (cur + 0.01);
    downloadModel.setUnzipProgress(next >= 0.59 ? 0.59 : next);
  });

  try {
    final result = await compute(
      _decompressInIsolate,
      UnzipParams(zipFilePath, destinationPath),
    );

    // 進入可量測階段，先停掉假進度，直接切到 0.4
    smoothTimer?.cancel();
    downloadModel.setUnzipProgress(0.6);

    final files = result[1] as List<ArchiveFile>;
    final totalFiles = files.length;
    int processedFiles = 0;

    for (final file in files) {
      await compute(_extractFileInIsolate, {
        'file': file,
        'destinationPath': destinationPath,
      });

      processedFiles++;
      final progress = 0.4 + (0.6 * processedFiles / totalFiles);
      if (processedFiles % 10 == 0) {
        await Future.delayed(const Duration(milliseconds: 1));
      }
      downloadModel.setUnzipProgress(progress);
    }

    downloadModel.setProgress(1.0);
    downloadModel.setUnzipProgress(1.0);

    try {
      final f = File(zipFilePath);
      if (await f.exists()) await f.delete();
    } catch (_) {}

    final modelRootName = basenameWithoutExtension(
      basenameWithoutExtension(zipFilePath),
    );
    final modelRoot = join(destinationPath, modelRootName);

    await deleteSpecificFilesForModel(
      modelName: downloadModel.modelName,
      modelRoot: modelRoot,
      dryRun: false,
    );

    if (Navigator.canPop(context)) {
      Navigator.of(context).pop();
      _showSuccessDialog(context);
    }
  } finally {
    // 防止任何例外時計時器沒被關
    smoothTimer?.cancel();
  }
}

String nowYmdLocal() {
  return DateFormat('yyyyMMdd').format(DateTime.now());
}

String formatYMd(BuildContext context, DateTime dt) {
  final locale = Localizations.localeOf(context).toString();
  return DateFormat.yMd(locale).format(dt);
}
