//amitabha/lib/utils.dart
// This file is modified based on the open-source project:
// Flutter-EasySpeechRecognition (https://github.com/Jason-chen-coder/Flutter-EasySpeechRecognition)
// Original copyright (c) 2024 Xiaomi Corporation

import "dart:io";
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
  final downLoadUrl =
      'https://github.com/k2-fsa/sherpa-onnx/releases/download/$channel/$modelName.tar.bz2';
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
      final request = http.Request('GET', Uri.parse(downLoadUrl));
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
    } catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      showDialog(
        context: context,
        builder: (BuildContext context) {
          final t = AppLocalizations.of(context);
          return AlertDialog(
            title: Text(t.downloadFailedTitle),
            content: Text(t.downloadFailedBody(e.toString())),
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
      try {
        if (await File(moduleZipFilePath).exists()) {
          await File(moduleZipFilePath).delete();
        }
      } catch (_) {}
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
    downloadModel.setUnzipProgress(0.0);
    Navigator.of(context).pop();

    try {
      final f = File(moduleZipFilePath);
      if (await f.exists()) await f.delete();
    } catch (_) {}

    downloadModelAndUnZip(context, modelName);
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
  downloadModel.setUnzipProgress(0.1);

  final result = await compute(
    _decompressInIsolate,
    UnzipParams(zipFilePath, destinationPath),
  );

  downloadModel.setUnzipProgress(0.4);

  final files = result[1] as List<ArchiveFile>;
  final totalFiles = files.length;
  int processedFiles = 0;

  for (final file in files) {
    await compute(_extractFileInIsolate, {
      'file': file,
      'destinationPath': destinationPath,
    });

    processedFiles++;
    double progress = 0.4 + (0.6 * processedFiles / totalFiles);

    if (processedFiles % 10 == 0) {
      await Future.delayed(Duration(milliseconds: 1));
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
}

String nowYmdLocal() {
  return DateFormat('yyyyMMdd').format(DateTime.now());
}

String formatYMd(BuildContext context, DateTime dt) {
  final locale = Localizations.localeOf(context).toString();
  return DateFormat.yMd(locale).format(dt);
}
