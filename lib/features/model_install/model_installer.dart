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

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';

import 'package:amitabha/storage/model_paths.dart';
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
  /// - [onProgress] 回報「檔案寫入」階段的 0.0~1.0(BZip2/Tar 解碼階段
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

    try {
      final files = await compute(
        _decompressInIsolate,
        _UnzipParams(zipPath, destinationRoot),
      );

      onProgress?.call(0.0); // 解碼完成,進入檔案寫入階段

      // 跳過清單:清理表裡「解壓後本來就要刪掉」的檔案,
      // 直接不寫入磁碟,省下跨 isolate 複製 + 閃存寫入的時間。
      final modelRootName = basenameWithoutExtension(
        basenameWithoutExtension(zipPath),
      );
      final skipPaths = deleteListFor(
        modelName,
      ).map((rel) => normalize(join(modelRootName, rel))).toSet();

      final filesToWrite = files.where((f) {
        return !skipPaths.contains(normalize(f.name));
      }).toList();

      // 位元組加權進度以「實際要寫入的檔案」計算
      final totalBytes = filesToWrite.fold<int>(
        0,
        (sum, f) => sum + (f.isFile ? f.size : 0),
      );
      int processedBytes = 0;

      for (final file in filesToWrite) {
        if (isCancelled?.call() ?? false) {
          throw UserCancelledException();
        }
        await compute(_extractFileInIsolate, {
          'file': file,
          'destinationPath': destinationRoot,
        });

        processedBytes += file.isFile ? file.size : 0;
        onProgress?.call(totalBytes > 0 ? processedBytes / totalBytes : 1.0);
      }

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
        throw const FileSystemException(
          'Required model files missing after extraction',
        );
      }

      // 全部通過才刪 zip
      await _safeDelete(zipPath);
    } on UserCancelledException {
      rethrow; // 取消解壓 → zip 保留,之後可直接再解壓,不用重新下載
    } catch (e) {
      if (_looksLikeDiskFull(e)) {
        // 空間不足 → zip 保留,清出空間後可只重試解壓
        throw InstallException(InstallFailureReason.diskFull, e);
      }
      // zip 損毀或驗證失敗 → zip 不可信,刪除後需重新下載
      final verificationFailed = await modelFilesComplete(modelName) == false &&
          e is FileSystemException &&
          e.message.contains('missing after extraction');
      await _safeDelete(zipPath);
      throw InstallException(
        verificationFailed
            ? InstallFailureReason.verificationFailed
            : InstallFailureReason.corruptedArchive,
        e,
      );
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

// ═══════════════════════════ isolate 工作函式 ═══════════════════════════
// P5 預定改為單一 isolate 串流解壓;目前維持原本 compute 實作。

class _UnzipParams {
  final String zipFilePath;
  final String destinationPath;
  _UnzipParams(this.zipFilePath, this.destinationPath);
}

Future<List<ArchiveFile>> _decompressInIsolate(_UnzipParams params) async {
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
