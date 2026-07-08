// lib/features/model_install/model_installer.dart
// 模型安裝的「純邏輯層」:狀態判定、下載、解壓、完整性驗證。
//
// 這一層不 import 任何 Flutter UI(僅 foundation 供 compute/debugPrint)、
// 不開對話框、不碰 BuildContext。失敗一律以 typed 的 InstallException 拋出,
// 由 model_install_flow.dart 決定要顯示什麼 UI。
//
// This file is modified based on the open-source project:
// Flutter-EasySpeechRecognition (https://github.com/Jason-chen-coder/Flutter-EasySpeechRecognition)
// Original copyright (c) 2024 Xiaomi Corporation

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:amitabha/storage/model_paths.dart';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';

import 'model_cleanup.dart';

// ═══════════════════════════ 狀態與例外 ═══════════════════════════

enum InstallStatus {
  /// 關鍵模型檔案齊全,可直接使用。
  ready,

  /// 無資料夾也無 zip → 需要下載。
  needsDownload,

  /// zip 在本地(資料夾不在,或資料夾缺檔)→ 只需解壓,不用重新下載。
  needsUnzip,

  /// 資料夾在但缺檔,且 zip 也不在 → 需要重新下載。
  incompleteNeedsDownload,
}

enum InstallFailureReason {
  /// 網路不通(SocketException)。
  network,

  /// 連線逾時或傳輸中斷(TimeoutException)。
  timeout,

  /// 伺服器回應異常(404、5xx 等)。
  server,

  /// 磁碟空間不足。zip(若已完整下載)會保留,清出空間後可只解壓。
  diskFull,

  /// 解壓失敗(zip 損毀)。zip 已刪除,需重新下載。
  corruptedArchive,

  /// 解壓完成但關鍵檔案缺失。zip 已刪除,需重新下載。
  verificationFailed,

  /// 其他未分類錯誤。
  unknown,
}

class InstallException implements Exception {
  final InstallFailureReason reason;
  final Object? cause;
  InstallException(this.reason, [this.cause]);
  @override
  String toString() =>
      'InstallException($reason${cause == null ? '' : ', cause: $cause'})';
}

/// 使用者主動取消(不是錯誤,UI 不顯示失敗對話框)。
class UserCancelledException implements Exception {}

// ═══════════════════════════ 必要檔案清單 ═══════════════════════════

/// 各模型的必要檔案清單。
/// 外層 List = 每一項都必須滿足;內層 List = 其中任一存在即可(float / int8 擇一)。
/// 檔名以 online_model.dart 實際載入的路徑為準。
const Map<String, List<List<String>>> _defaultRequiredModelFiles = {
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

// ═══════════════════════════ 安裝器 ═══════════════════════════

class ModelInstaller {
  ModelInstaller({
    http.Client Function()? httpClientFactory,
    this.connectTimeout = const Duration(seconds: 20),
    this.stallTimeout = const Duration(seconds: 30),
    this.channel = 'asr-models',
    Map<String, List<List<String>>>? requiredFilesOverride,
  }) : _httpClientFactory = httpClientFactory ?? http.Client.new,
       _requiredFiles = requiredFilesOverride ?? _defaultRequiredModelFiles;

  final http.Client Function() _httpClientFactory;

  /// 連不上/等不到回應標頭的逾時。
  final Duration connectTimeout;

  /// 傳輸中「沒有任何新資料」超過此時間 → 視為連線中斷。
  final Duration stallTimeout;

  /// sherpa-onnx release 的下載頻道(本 App 只用 ASR 模型)。
  final String channel;

  final Map<String, List<List<String>>> _requiredFiles;

  String downloadUrlFor(String modelName) {
    final fileName = ModelPaths.archiveFileName(modelName);
    return 'https://github.com/k2-fsa/sherpa-onnx/releases/download/$channel/$fileName';
  }

  // ── 狀態判定 ──────────────────────────────────────────────

  Future<InstallStatus> status(String modelName) async {
    final destinationRoot = (await ModelPaths.root()).path;
    final modulePath = join(destinationRoot, modelName);
    final zipPath = (await ModelPaths.archiveFile(modelName)).path;

    final moduleExists = await Directory(modulePath).exists();
    final zipExists = await File(zipPath).exists();

    if (!moduleExists) {
      return zipExists ? InstallStatus.needsUnzip : InstallStatus.needsDownload;
    }
    if (await modelFilesComplete(modelName)) return InstallStatus.ready;
    return zipExists
        ? InstallStatus.needsUnzip
        : InstallStatus.incompleteNeedsDownload;
  }

  /// 檢查指定模型的關鍵檔案是否齊全。
  /// 未登錄在必要檔案清單的模型回傳 true(不做驗證),
  /// 避免誤判觸發不必要的重新下載;新增模型時記得補上清單。
  Future<bool> modelFilesComplete(String modelName) async {
    final required = _requiredFiles[modelName];
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

  // ── 下載 ──────────────────────────────────────────────────

  /// 下載模型壓縮檔到暫存目錄。
  ///
  /// - 進度以 0.0~1.0 回報給 [onProgress](伺服器未提供大小時不回報)。
  /// - [isCancelled] 每收到一塊資料就檢查一次;取消時拋 [UserCancelledException]。
  /// - 任何失敗(含取消)都會刪除下載到一半的殘檔後,再以 typed 例外拋出。
  Future<void> download(
    String modelName, {
    void Function(double progress)? onProgress,
    bool Function()? isCancelled,
  }) async {
    final zipPath = (await ModelPaths.archiveFile(modelName)).path;
    final url = downloadUrlFor(modelName);

    try {
      final client = _httpClientFactory();
      try {
        final request = http.Request('GET', Uri.parse(url));
        request.headers['User-Agent'] = 'AmitabhaApp/1.0';

        final response = await client.send(request).timeout(connectTimeout);

        // 伺服器回應異常(404、5xx 等)明確拋出,跟網路問題區分開
        if (response.statusCode != 200) {
          throw HttpException(
            'Server responded ${response.statusCode}',
            uri: Uri.parse(url),
          );
        }

        final totalBytes = response.contentLength ?? 0;
        int receivedBytes = 0;

        final sink = File(zipPath).openWrite();
        try {
          await response.stream
              .timeout(
                stallTimeout,
                onTimeout: (eventSink) {
                  eventSink.close();
                  throw TimeoutException('download stalled');
                },
              )
              .forEach((List<int> chunk) {
                if (isCancelled?.call() ?? false) {
                  throw UserCancelledException();
                }
                sink.add(chunk);
                receivedBytes += chunk.length;
                if (totalBytes > 0) {
                  onProgress?.call(receivedBytes / totalBytes);
                }
              });
          await sink.flush();
        } finally {
          await sink.close();
        }

        // 下載完整性驗證:實際大小要跟伺服器宣稱的一致
        if (totalBytes > 0) {
          final actualSize = await File(zipPath).length();
          if (actualSize != totalBytes) {
            throw const FileSystemException('incomplete download');
          }
        }
      } finally {
        client.close();
      }
    } on UserCancelledException {
      await _safeDelete(zipPath); // 下載中取消 → 殘檔刪除
      rethrow;
    } on SocketException catch (e) {
      await _safeDelete(zipPath);
      throw InstallException(InstallFailureReason.network, e);
    } on TimeoutException catch (e) {
      await _safeDelete(zipPath);
      throw InstallException(InstallFailureReason.timeout, e);
    } on HttpException catch (e) {
      await _safeDelete(zipPath);
      throw InstallException(InstallFailureReason.server, e);
    } catch (e) {
      await _safeDelete(zipPath);
      throw InstallException(
        _looksLikeDiskFull(e)
            ? InstallFailureReason.diskFull
            : InstallFailureReason.unknown,
        e,
      );
    }
  }

  // ── 解壓 + 驗證 ───────────────────────────────────────────

  /// 解壓 zip、清理多餘檔案、驗證關鍵檔案,全部通過後才刪除 zip。
  ///
  /// 實作為「單一 isolate + 檔案串流」:bz2 先串流解成暫存 tar 檔,
  /// 再逐項串流寫盤,記憶體峰值僅為緩衝區大小,與模型大小無關
  /// (舊實作會把整包解壓內容全部載入記憶體,低階裝置有 OOM 風險)。
  ///
  /// - [onProgress] 回報「檔案寫入」階段的 0.0~1.0(BZip2 解碼階段
  ///   無法取得真實進度,解碼完成時會先回報 0.0,由 UI 層自行處理估算進度)。
  /// - 失敗處理:磁碟空間不足或使用者取消 → 保留 zip(可只重試解壓);
  ///   zip 損毀或驗證失敗 → 刪除 zip(需重新下載)。
  Future<void> unzipAndVerify(
    String modelName, {
    void Function(double progress)? onProgress,
    bool Function()? isCancelled,
  }) async {
    final zipPath = (await ModelPaths.archiveFile(modelName)).path;
    final destinationRoot = (await ModelPaths.root()).path;
    final tempTarPath = '$zipPath.tar';

    try {
      if (isCancelled?.call() ?? false) {
        throw UserCancelledException();
      }

      // 跳過清單:清理表裡「解壓後本來就要刪掉」的檔案,直接不寫入磁碟
      final modelRootName = basenameWithoutExtension(
        basenameWithoutExtension(zipPath),
      );
      final skipPaths = deleteListFor(
        modelName,
      ).map((rel) => normalize(join(modelRootName, rel))).toList();

      await _runUnzipIsolate(
        zipPath: zipPath,
        destinationRoot: destinationRoot,
        tempTarPath: tempTarPath,
        skipPaths: skipPaths,
        onProgress: onProgress,
        isCancelled: isCancelled,
      );

      // 清理多餘檔案。跳過清單已讓這些檔案不存在,此呼叫通常無事可做,
      // 但萬一未來清單不同步仍能兜底。
      final modelRoot = join(destinationRoot, modelRootName);
      await deleteSpecificFilesForModel(
        modelName: modelName,
        modelRoot: modelRoot,
        dryRun: false,
      );

      // 最終驗證:關鍵模型檔案必須齊全,才能宣告安裝成功
      final isComplete = await modelFilesComplete(modelName);
      if (!isComplete) {
        await _safeDelete(zipPath); // 驗證失敗 → zip 不可信,重新下載
        throw InstallException(InstallFailureReason.verificationFailed);
      }

      // 全部通過才刪 zip
      await _safeDelete(zipPath);
    } on UserCancelledException {
      rethrow; // 取消解壓 → zip 保留,之後可直接再解壓,不用重新下載
    } on InstallException {
      rethrow; // 已分類(worker 回報或驗證失敗),不再包一層
    } catch (e) {
      if (_looksLikeDiskFull(e)) {
        // 空間不足 → zip 保留,清出空間後可只重試解壓
        throw InstallException(InstallFailureReason.diskFull, e);
      }
      await _safeDelete(zipPath); // zip 損毀 → 刪除後需重新下載
      throw InstallException(InstallFailureReason.corruptedArchive, e);
    } finally {
      await _safeDelete(tempTarPath); // 暫存 tar 一律清掉(成功時 worker 已自刪)
    }
  }

  /// 啟動解壓 isolate 並轉送進度;取消時直接終止 isolate(zip 保留)。
  Future<void> _runUnzipIsolate({
    required String zipPath,
    required String destinationRoot,
    required String tempTarPath,
    required List<String> skipPaths,
    void Function(double progress)? onProgress,
    bool Function()? isCancelled,
  }) async {
    final receivePort = ReceivePort();
    final isolate = await Isolate.spawn(
      _unzipWorker,
      _UnzipWorkerArgs(
        sendPort: receivePort.sendPort,
        zipPath: zipPath,
        destinationRoot: destinationRoot,
        tempTarPath: tempTarPath,
        skipPaths: skipPaths,
      ),
    );

    try {
      await for (final message in receivePort) {
        if (isCancelled?.call() ?? false) {
          isolate.kill(priority: Isolate.immediate);
          throw UserCancelledException();
        }
        final m = message as List<Object?>;
        switch (m[0] as String) {
          case 'progress':
            onProgress?.call(m[1]! as double);
          case 'done':
            return;
          case 'error':
            final diskFull = m[1]! as bool;
            final description = m[2]! as String;
            if (diskFull) {
              throw InstallException(
                InstallFailureReason.diskFull,
                description,
              );
            }
            throw InstallException(
              InstallFailureReason.corruptedArchive,
              description,
            );
        }
      }
      // port 意外關閉(isolate 崩潰)→ 視為壓縮檔損毀
      throw InstallException(InstallFailureReason.corruptedArchive);
    } finally {
      receivePort.close();
    }
  }

  // ── 內部工具 ─────────────────────────────────────────────

  static Future<void> _safeDelete(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  /// 磁碟空間是否不足(事後判斷:讀系統回傳的錯誤訊息字串)。
  static bool _looksLikeDiskFull(Object e) {
    if (e is FileSystemException) {
      final msg = (e.osError?.message ?? e.message).toLowerCase();
      return msg.contains('no space left') || msg.contains('enospc');
    }
    // Android 有時候訊息會不同,可再擴充
    return false;
  }
}

// ═══════════════════════════ 解壓 isolate(串流實作) ═══════════════════════════
// 全程只在單一 isolate 內進行,透過 SendPort 回報進度:
//   ['progress', double]  ['done']  ['error', bool isDiskFull, String message]

class _UnzipWorkerArgs {
  final SendPort sendPort;
  final String zipPath;
  final String destinationRoot;
  final String tempTarPath;
  final List<String> skipPaths; // normalize 過的相對路徑

  _UnzipWorkerArgs({
    required this.sendPort,
    required this.zipPath,
    required this.destinationRoot,
    required this.tempTarPath,
    required this.skipPaths,
  });
}

Future<void> _unzipWorker(_UnzipWorkerArgs args) async {
  final send = args.sendPort;
  try {
    // ── 1) bz2 → 暫存 tar(串流,記憶體僅緩衝區大小) ──
    final bz2Input = InputFileStream(args.zipPath);
    final tarOutput = OutputFileStream(args.tempTarPath);
    try {
      BZip2Decoder().decodeStream(bz2Input, tarOutput);
    } finally {
      await bz2Input.close();
      await tarOutput.close();
    }
    send.send(['progress', 0.0]); // 解碼完成,進入檔案寫入階段

    // ── 2) 讀 tar 目錄(內容惰性引用暫存檔,不載入記憶體) ──
    final tarInput = InputFileStream(args.tempTarPath);
    try {
      final archive = TarDecoder().decodeStream(tarInput);
      final skipSet = args.skipPaths.toSet();

      final entries = archive.files.where((f) {
        final name = normalize(f.name);
        if (skipSet.contains(name)) return false;
        // 防路徑跳脫:項目不得寫到目的資料夾之外
        final dest = normalize(join(args.destinationRoot, name));
        return isWithin(args.destinationRoot, dest);
      }).toList();

      final totalBytes = entries.fold<int>(
        0,
        (sum, f) => sum + (f.isFile ? f.size : 0),
      );
      int processedBytes = 0;

      // ── 3) 逐項串流寫盤 ──
      for (final entry in entries) {
        final destPath = normalize(join(args.destinationRoot, entry.name));
        if (!entry.isFile) {
          await Directory(destPath).create(recursive: true);
          continue;
        }
        await Directory(dirname(destPath)).create(recursive: true);
        final out = OutputFileStream(destPath);
        try {
          entry.writeContent(out); // 從暫存 tar 串流到目的檔
        } finally {
          await out.close();
        }
        processedBytes += entry.size;
        send.send([
          'progress',
          totalBytes > 0 ? processedBytes / totalBytes : 1.0,
        ]);
      }
      if (totalBytes == 0) send.send(['progress', 1.0]);
    } finally {
      await tarInput.close();
    }

    // 成功:自刪暫存 tar(主 isolate 的 finally 仍會兜底)
    try {
      await File(args.tempTarPath).delete();
    } catch (_) {}

    send.send(['done']);
  } catch (e) {
    bool diskFull = false;
    if (e is FileSystemException) {
      final msg = (e.osError?.message ?? e.message).toLowerCase();
      diskFull = msg.contains('no space left') || msg.contains('enospc');
    }
    send.send(['error', diskFull, e.toString()]);
  }
}
