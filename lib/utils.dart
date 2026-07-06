//amitabha/lib/utils.dart
// This file is modified based on the open-source project:
// Flutter-EasySpeechRecognition (https://github.com/Jason-chen-coder/Flutter-EasySpeechRecognition)
// Original copyright (c) 2024 Xiaomi Corporation

import "dart:io";
import 'dart:async';
import 'package:archive/archive.dart';
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
import 'package:wakelock_plus/wakelock_plus.dart';

// ═══════════════════════════ 例外類別 ═══════════════════════════

/// 使用者主動取消（不是錯誤，不顯示失敗對話框）
class UserCancelledException implements Exception {}

/// 解壓完成後最終驗證失敗（關鍵模型檔案缺失）
class ModelVerificationException implements Exception {
  final String message;
  ModelVerificationException(this.message);
  @override
  String toString() => 'ModelVerificationException: $message';
}

// ═══════════════════════════ 音訊工具 ═══════════════════════════

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

// ═══════════════════════════ 下載主流程 ═══════════════════════════

Future<void> downloadModelAndUnZip(
  BuildContext context,
  String modelName,
) async {
  await _withWakelock(() async {
    final downloadModel = Provider.of<DownloadModel>(context, listen: false);
    final channel = downloadModel.channel;
    final fileName = ModelPaths.archiveFileName(modelName);
    final downLoadUrl =
        'https://github.com/k2-fsa/sherpa-onnx/releases/download/$channel/$fileName';

    final destinationRoot = (await ModelPaths.root()).path;
    final modulePath = join(destinationRoot, modelName);
    final moduleZipFilePath = (await ModelPaths.archiveFile(modelName)).path;

    final moduleExists = await Directory(modulePath).exists();
    final moduleZipExists = await File(moduleZipFilePath).exists();

    if (moduleExists) return;
    if (moduleZipExists) return; // 有 zip 沒資料夾 → 應走 unzipModelFile

    final confirmed = await _showDownloadConfirmationDialog(context);
    if (!confirmed) return;

    downloadModel.clearCancel();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => DownloadProgressDialog(),
    );
    // 立刻給非零進度，跳過「準備中」畫面，避免一閃而過
    downloadModel.setProgress(0.001);

    // 標記下載階段是否已完整結束：
    // 取消發生在下載中 → 殘檔沒用，刪掉
    // 取消發生在解壓中 → zip 是完整的，保留，之後可只解壓
    bool downloadFinished = false;

    try {
      final client = http.Client();
      try {
        final request = http.Request('GET', Uri.parse(downLoadUrl));
        request.headers['User-Agent'] = 'AmitabhaApp/1.0';

        // 20 秒內連不上/等不到回應標頭 → 逾時
        final response = await client
            .send(request)
            .timeout(const Duration(seconds: 20));

        // 伺服器回應異常（404、5xx 等）明確拋出，跟網路問題區分開
        if (response.statusCode != 200) {
          throw HttpException(
            'Server responded ${response.statusCode}',
            uri: Uri.parse(downLoadUrl),
          );
        }

        final totalBytes = response.contentLength ?? 0;
        int receivedBytes = 0;

        final sink = File(moduleZipFilePath).openWrite();
        try {
          // 傳輸中超過 30 秒沒有任何新資料 → 視為連線中斷
          await response.stream
              .timeout(
                const Duration(seconds: 30),
                onTimeout: (eventSink) {
                  eventSink.close();
                  throw TimeoutException('download stalled');
                },
              )
              .forEach((List<int> chunk) {
                if (downloadModel.cancelRequested) {
                  throw UserCancelledException();
                }
                sink.add(chunk);
                receivedBytes += chunk.length;
                final progress = totalBytes > 0
                    ? receivedBytes / totalBytes
                    : 0.0;
                // 保持非零，避免畫面退回「準備中」
                downloadModel.setProgress(progress < 0.001 ? 0.001 : progress);
              });
          await sink.flush();
        } finally {
          await sink.close();
        }

        // ── 下載完整性驗證:實際大小要跟伺服器宣稱的一致 ──
        if (totalBytes > 0) {
          final actualSize = await File(moduleZipFilePath).length();
          if (actualSize != totalBytes) {
            throw const FileSystemException('incomplete download');
          }
        }
        downloadFinished = true;

        await _unzipDownloadedFile(moduleZipFilePath, destinationRoot, context);
      } finally {
        client.close();
      }
    } on UserCancelledException {
      if (Navigator.canPop(context)) Navigator.of(context).pop();
      if (!downloadFinished) {
        await _safeDelete(moduleZipFilePath); // 下載中取消 → 殘檔刪除
      }
      downloadModel.reset();
      // 使用者主動取消，不顯示任何失敗對話框
    } on SocketException {
      await _handleDownloadFailure(
        context,
        moduleZipFilePath,
        keepZip: downloadFinished,
        titleOf: (t) => t.downloadFailedTitle,
        messageOf: (t) => t.networkErrorBody,
        onRetry: () => _retryFrom(context, modelName),
      );
    } on TimeoutException {
      await _handleDownloadFailure(
        context,
        moduleZipFilePath,
        keepZip: downloadFinished,
        titleOf: (t) => t.downloadFailedTitle,
        messageOf: (t) => t.timeoutErrorBody,
        onRetry: () => _retryFrom(context, modelName),
      );
    } on HttpException {
      await _handleDownloadFailure(
        context,
        moduleZipFilePath,
        keepZip: false, // 伺服器回應異常，殘檔不可信
        titleOf: (t) => t.downloadFailedTitle,
        messageOf: (t) => t.serverErrorBody,
        onRetry: () => _retryFrom(context, modelName),
      );
    } catch (e) {
      if (_looksLikeDiskFull(e)) {
        await _handleDownloadFailure(
          context,
          moduleZipFilePath,
          keepZip: downloadFinished, // 解壓階段空間不足 → zip 是好的,保留
          titleOf: (t) => t.downloadFailedLowSpaceTitle,
          messageOf: (t) => t.downloadFailedLowSpaceBody,
          retryLabelOf: (t) => t.retryAfterFreeSpace,
          onRetry: () => _retryFrom(context, modelName),
        );
      } else {
        await _handleDownloadFailure(
          context,
          moduleZipFilePath,
          keepZip: false,
          titleOf: (t) => t.downloadFailedTitle,
          messageOf: (t) => t.downloadFailedShort,
          onRetry: () => _retryFrom(context, modelName),
        );
      }
    }
  });
}

/// 重試進入點：依當下實際狀態（zip 在不在）決定走下載還是只解壓
Future<void> _retryFrom(BuildContext context, String modelName) async {
  final moduleZipFilePath = (await ModelPaths.archiveFile(modelName)).path;
  if (await File(moduleZipFilePath).exists()) {
    await unzipModelFile(context, modelName);
  } else {
    await downloadModelAndUnZip(context, modelName);
  }
}

/// 失敗收尾的共用流程：關進度框 → 視情況刪 zip → 重置狀態 → 顯示對應錯誤對話框
Future<void> _handleDownloadFailure(
  BuildContext context,
  String zipFilePath, {
  required bool keepZip,
  required String Function(AppLocalizations) titleOf,
  required String Function(AppLocalizations) messageOf,
  String Function(AppLocalizations)? retryLabelOf,
  required Future<void> Function() onRetry,
}) async {
  if (Navigator.canPop(context)) Navigator.of(context).pop();
  if (!keepZip) await _safeDelete(zipFilePath);

  final downloadModel = Provider.of<DownloadModel>(context, listen: false);
  downloadModel.reset();

  final t = AppLocalizations.of(context);
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      title: Text(titleOf(t)),
      content: Text(messageOf(t)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.close),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onRetry();
          },
          child: Text(retryLabelOf?.call(t) ?? t.retry),
        ),
      ],
    ),
  );
}

Future<void> _safeDelete(String path) async {
  try {
    final f = File(path);
    if (await f.exists()) await f.delete();
  } catch (_) {}
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
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child: Text(t.download),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          );
        },
      ) ??
      false;
}

// ═══════════════════════════ 解壓主流程 ═══════════════════════════

Future<void> unzipModelFile(BuildContext context, String modelName) async {
  await _withWakelock(() async {
    final downloadModel = Provider.of<DownloadModel>(context, listen: false);

    downloadModel.clearCancel();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => DownloadProgressDialog(),
    );
    downloadModel.setUnzipProgress(0.001); // 跳過「準備中」畫面

    final moduleZipFilePath = (await ModelPaths.archiveFile(modelName)).path;
    try {
      final destinationRoot = (await ModelPaths.root()).path;
      await _unzipDownloadedFile(moduleZipFilePath, destinationRoot, context);
    } on UserCancelledException {
      if (Navigator.canPop(context)) Navigator.of(context).pop();
      // 取消解壓 → zip 保留，之後可直接再解壓，不用重新下載
      downloadModel.reset();
    } catch (e) {
      if (Navigator.canPop(context)) Navigator.of(context).pop();

      if (_looksLikeDiskFull(e)) {
        downloadModel.reset();
        final destinationRoot = (await ModelPaths.root()).path;
        await _showRetryUnzipOnlyDialog(
          context,
          zipFilePath: moduleZipFilePath,
          destinationRoot: destinationRoot,
        );
      } else {
        // 解壓失敗且非空間問題 → zip 很可能損毀，刪除並重新下載
        downloadModel.reset();
        await _safeDelete(moduleZipFilePath);
        await _handleGenericUnzipFailure(context, modelName);
      }
    }
  });
}

Future<void> _handleGenericUnzipFailure(
  BuildContext context,
  String modelName,
) async {
  final t = AppLocalizations.of(context);
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      title: Text(t.downloadFailedTitle),
      content: Text(t.downloadFailedShort),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.close),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            downloadModelAndUnZip(context, modelName);
          },
          child: Text(t.retry),
        ),
      ],
    ),
  );
}

/// 空間不足專用：文案明確要求「先清出空間」，按鈕語意是「我已清好空間」
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
      title: Text(t.unzipFailedTitle),
      content: Text(t.unzipFailedLowSpaceBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.close),
        ),
        TextButton(
          onPressed: () async {
            Navigator.of(context).pop();

            // 重新叫出進度對話框（原本那個已在 catch 區塊被關掉）
            final downloadModel = Provider.of<DownloadModel>(
              context,
              listen: false,
            );
            downloadModel.clearCancel();
            downloadModel.setStatusNote(t.retryUnzipNote);
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) => DownloadProgressDialog(),
            );
            downloadModel.setUnzipProgress(0.001);

            try {
              await _unzipDownloadedFile(zipFilePath, destinationRoot, context);
            } on UserCancelledException {
              if (Navigator.canPop(context)) Navigator.of(context).pop();
              downloadModel.reset();
            } catch (e) {
              if (Navigator.canPop(context)) Navigator.of(context).pop();
              if (_looksLikeDiskFull(e)) {
                downloadModel.reset();
                // 空間還是不夠 → 再次顯示同一個提示，讓使用者繼續清
                await _showRetryUnzipOnlyDialog(
                  context,
                  zipFilePath: zipFilePath,
                  destinationRoot: destinationRoot,
                );
              } else {
                downloadModel.reset();
                await _safeDelete(zipFilePath);
                final modelName = downloadModel.modelName;
                await _handleGenericUnzipFailure(context, modelName);
              }
            }
          },
          child: Text(t.retryUnzipAfterFreeSpace),
        ),
      ],
    ),
  );
}

// ═══════════════════════════ 解壓實作 ═══════════════════════════

class UnzipParams {
  final String zipFilePath;
  final String destinationPath;
  UnzipParams(this.zipFilePath, this.destinationPath);
}

Future<List<ArchiveFile>> _decompressInIsolate(UnzipParams params) async {
  final bytes = File(params.zipFilePath).readAsBytesSync();
  final tarBytes = BZip2Decoder().decodeBytes(bytes);
  final tarArchive = TarDecoder().decodeBytes(tarBytes);
  return tarArchive.files;
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

  // 平滑假進度：BZip2 + Tar 解碼階段無法取得真實進度，先用假進度撐著
  // 上限對齊到下一階段的起始基準值（0.35），避免銜接時進度「倒退」
  const decodePhaseCap = 0.35;
  Timer? smoothTimer;
  smoothTimer = Timer.periodic(const Duration(milliseconds: 300), (_) {
    final cur = downloadModel.unzipProgress;
    if (cur >= decodePhaseCap) {
      smoothTimer?.cancel();
      return;
    }
    downloadModel.setUnzipProgress((cur + 0.01).clamp(0.0, decodePhaseCap));
  });

  try {
    final files = await compute(
      _decompressInIsolate,
      UnzipParams(zipFilePath, destinationPath),
    );

    smoothTimer.cancel();
    downloadModel.setUnzipProgress(decodePhaseCap);

    // ── 跳過清單：_deleteMap 裡「解壓後本來就要刪掉」的檔案，
    //    直接不寫入磁碟，省下跨 isolate 複製 + 閃存寫入的時間。
    final modelRootName = basenameWithoutExtension(
      basenameWithoutExtension(zipFilePath),
    );
    final skipPaths = deleteListFor(
      downloadModel.modelName,
    ).map((rel) => normalize(join(modelRootName, rel))).toSet();

    final filesToWrite = files.where((f) {
      return !skipPaths.contains(normalize(f.name));
    }).toList();

    // 位元組加權進度改以「實際要寫入的檔案」計算
    final totalBytes = filesToWrite.fold<int>(
      0,
      (sum, f) => sum + (f.isFile ? f.size : 0),
    );
    int processedBytes = 0;

    for (final file in filesToWrite) {
      await compute(_extractFileInIsolate, {
        'file': file,
        'destinationPath': destinationPath,
      });

      processedBytes += file.isFile ? file.size : 0;
      final ratio = totalBytes > 0 ? processedBytes / totalBytes : 1.0;
      downloadModel.setUnzipProgress(
        decodePhaseCap + (1 - decodePhaseCap) * ratio,
      );
    }

    // ── 清理多餘檔案（在標記 100% 之前做，避免「完成」畫面一閃而過）──
    // 清理保留作為安全網：跳過清單已讓這些檔案不存在，
    // 此呼叫會直接無事可做，但萬一未來清單不同步仍能兜底
    final modelRoot = join(destinationPath, modelRootName);

    await deleteSpecificFilesForModel(
      modelName: downloadModel.modelName,
      modelRoot: modelRoot,
      dryRun: false,
    );

    // ── 最終驗證：關鍵模型檔案必須齊全，才能宣告安裝成功 ──
    // 驗證放在刪 zip 之前：萬一失敗，zip 還在，重試不用重新下載
    final isComplete = await modelFilesComplete(downloadModel.modelName);
    if (!isComplete) {
      throw ModelVerificationException(
        'Required model files missing after extraction',
      );
    }

    // 驗證通過才刪 zip
    await _safeDelete(zipFilePath);

    if (Navigator.canPop(context)) {
      Navigator.of(context).pop(); // 進度框直接關閉，不顯示「完成」狀態
    }

    downloadModel.reset();

    _showSuccessDialog(context); // 唯一的完成通知
  } finally {
    smoothTimer.cancel();
  }
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
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      );
    },
  );
}

// ═══════════════════════════ 狀態查詢 ═══════════════════════════

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

//確認磁碟儲存空間是否足夠（事後判斷：讀系統回傳的錯誤訊息字串）
bool _looksLikeDiskFull(Object e) {
  if (e is FileSystemException) {
    final msg = (e.osError?.message ?? e.message).toLowerCase();
    return msg.contains('no space left') || msg.contains('enospc');
  }
  // Android 有時候訊息會不同，可再擴充
  return false;
}

// ═══════════════════════════ 模型完整性驗證 ═══════════════════════════

/// 各模型的必要檔案清單。
/// 外層 List = 每一項都必須滿足；內層 List = 其中任一存在即可（float / int8 擇一）。
/// 檔名以 online_model.dart 實際載入的路徑為準。
const Map<String, List<List<String>>> _requiredModelFiles = {
  'sherpa-onnx-streaming-zipformer-bilingual-zh-en-2023-02-20': [
    ['encoder-epoch-99-avg-1.int8.onnx', 'encoder-epoch-99-avg-1.onnx'],
    ['decoder-epoch-99-avg-1.onnx', 'decoder-epoch-99-avg-1.int8.onnx'],
    ['joiner-epoch-99-avg-1.onnx', 'joiner-epoch-99-avg-1.int8.onnx'],
    ['tokens.txt'],
  ],
  'icefall-asr-zipformer-streaming-wenetspeech-20230615': [
    [
      'exp/encoder-epoch-12-avg-4-chunk-16-left-128.int8.onnx',
      'exp/encoder-epoch-12-avg-4-chunk-16-left-128.onnx',
    ],
    [
      'exp/decoder-epoch-12-avg-4-chunk-16-left-128.onnx',
      'exp/decoder-epoch-12-avg-4-chunk-16-left-128.int8.onnx',
    ],
    [
      'exp/joiner-epoch-12-avg-4-chunk-16-left-128.onnx',
      'exp/joiner-epoch-12-avg-4-chunk-16-left-128.int8.onnx',
    ],
    ['tokens.txt'],
  ],
};

/// 檢查指定模型的關鍵檔案是否齊全。
/// 未登錄在 _requiredModelFiles 的模型（例如 KWS）回傳 true（不做驗證），
/// 避免誤判觸發不必要的重新下載；新增模型時記得補上清單。
Future<bool> modelFilesComplete(String modelName) async {
  final required = _requiredModelFiles[modelName];
  if (required == null) {
    debugPrint('modelFilesComplete: no rule for $modelName, skip check');
    return true;
  }

  final root = (await ModelPaths.root()).path;
  final dir = join(root, modelName);

  for (final alternatives in required) {
    bool anyExists = false;
    for (final rel in alternatives) {
      if (await File(join(dir, rel)).exists()) {
        anyExists = true;
        break;
      }
    }
    if (!anyExists) {
      debugPrint('modelFilesComplete: missing ${alternatives.join(" / ")}');
      return false;
    }
  }
  return true;
}

/// 若資料夾存在但缺檔，優先嘗試：
/// 1) 若 zip 還在 → 直接「只解壓」
/// 2) 若 zip 不在 → 重新下載
Future<void> ensureModelReady(BuildContext context, String modelName) async {
  final destinationRoot = (await ModelPaths.root()).path;
  final modulePath = join(destinationRoot, modelName);
  final moduleZipFilePath = (await ModelPaths.archiveFile(modelName)).path;

  final moduleExists = await Directory(modulePath).exists();
  final zipExists = await File(moduleZipFilePath).exists();

  if (!moduleExists && !zipExists) {
    await downloadModelAndUnZip(context, modelName);
    return;
  }

  if (!moduleExists && zipExists) {
    await unzipModelFile(context, modelName);
    return;
  }

  final ok = await modelFilesComplete(modelName);
  if (!ok) {
    if (zipExists) {
      await unzipModelFile(context, modelName);
    } else {
      await downloadModelAndUnZip(context, modelName);
    }
  }
}

// ═══════════════════════════ 其他工具 ═══════════════════════════

String nowYmdLocal() {
  return DateFormat('yyyyMMdd').format(DateTime.now());
}

String formatYMd(BuildContext context, DateTime dt) {
  final locale = Localizations.localeOf(context).toString();
  return DateFormat.yMd(locale).format(dt);
}

Future<T> _withWakelock<T>(Future<T> Function() action) async {
  final wasEnabled = await WakelockPlus.enabled;
  try {
    if (!wasEnabled) {
      await WakelockPlus.enable();
    }
    return await action();
  } finally {
    if (!wasEnabled) {
      await WakelockPlus.disable();
    }
  }
}
