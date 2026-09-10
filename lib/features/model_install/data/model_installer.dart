// lib/features/model_install/data/model_installer.dart

// This file is modified based on the open-source project:
// Flutter-EasySpeechRecognition (https://github.com/Jason-chen-coder/Flutter-EasySpeechRecognition)
// Original copyright (c) 2024 Xiaomi Corporation
import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:amitabha/features/model_install/data/model_cleanup.dart';
import 'package:amitabha/storage/model_paths.dart';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';

enum InstallStatus { ready, needsDownload, needsUnzip, incompleteNeedsDownload }

enum InstallFailureReason {
  network,
  timeout,
  server,
  diskFull,
  corruptedArchive,
  verificationFailed,
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

class UserCancelledException implements Exception {}

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

  final Duration connectTimeout;

  final Duration stallTimeout;

  final String channel;

  final Map<String, List<List<String>>> _requiredFiles;

  String downloadUrlFor(String modelName) {
    final fileName = ModelPaths.archiveFileName(modelName);
    return 'https://github.com/k2-fsa/sherpa-onnx/releases/download/$channel/$fileName';
  }

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
      await _safeDelete(zipPath);
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

      final modelRoot = join(destinationRoot, modelRootName);
      await deleteSpecificFilesForModel(
        modelName: modelName,
        modelRoot: modelRoot,
        dryRun: false,
      );

      final isComplete = await modelFilesComplete(modelName);
      if (!isComplete) {
        await _safeDelete(zipPath);
        throw InstallException(InstallFailureReason.verificationFailed);
      }

      await _safeDelete(zipPath);
    } on UserCancelledException {
      rethrow;
    } on InstallException {
      rethrow;
    } catch (e) {
      if (_looksLikeDiskFull(e)) {
        throw InstallException(InstallFailureReason.diskFull, e);
      }
      await _safeDelete(zipPath);
      throw InstallException(InstallFailureReason.corruptedArchive, e);
    } finally {
      await _safeDelete(tempTarPath);
    }
  }

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
      throw InstallException(InstallFailureReason.corruptedArchive);
    } finally {
      receivePort.close();
    }
  }

  static Future<void> _safeDelete(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  static bool _looksLikeDiskFull(Object e) {
    if (e is FileSystemException) {
      final msg = (e.osError?.message ?? e.message).toLowerCase();
      return msg.contains('no space left') || msg.contains('enospc');
    }
    return false;
  }
}

class _UnzipWorkerArgs {
  final SendPort sendPort;
  final String zipPath;
  final String destinationRoot;
  final String tempTarPath;
  final List<String> skipPaths;

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
    final bz2Input = InputFileStream(args.zipPath);
    final tarOutput = OutputFileStream(args.tempTarPath);
    try {
      BZip2Decoder().decodeStream(bz2Input, tarOutput);
    } finally {
      await bz2Input.close();
      await tarOutput.close();
    }
    send.send(['progress', 0.0]);

    final tarInput = InputFileStream(args.tempTarPath);
    try {
      final archive = TarDecoder().decodeStream(tarInput);
      final skipSet = args.skipPaths.toSet();

      final entries = archive.files.where((f) {
        final name = normalize(f.name);
        if (skipSet.contains(name)) return false;
        final dest = normalize(join(args.destinationRoot, name));
        return isWithin(args.destinationRoot, dest);
      }).toList();

      final totalBytes = entries.fold<int>(
        0,
        (sum, f) => sum + (f.isFile ? f.size : 0),
      );
      int processedBytes = 0;

      for (final entry in entries) {
        final destPath = normalize(join(args.destinationRoot, entry.name));
        if (!entry.isFile) {
          await Directory(destPath).create(recursive: true);
          continue;
        }
        await Directory(dirname(destPath)).create(recursive: true);
        final out = OutputFileStream(destPath);
        try {
          entry.writeContent(out);
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
