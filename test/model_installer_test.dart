// ModelInstaller 純邏輯層的單元測試:
// 狀態判定、必要檔案驗證、下載(成功/取消/各類失敗)、解壓+驗證。
// 全程使用假 path_provider(temp dir)與 mock http client,不碰網路。
import 'dart:async';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:amitabha/features/model_install/model_installer.dart';
import 'package:amitabha/storage/model_paths.dart';

import 'helpers/fake_path_provider.dart';

/// 測試用模型:必要檔案只有 tokens.txt(透過 requiredFilesOverride 註冊)。
const _testModel = 'test-model';
const _testRequired = {
  _testModel: [
    ['tokens.txt'],
  ],
};

/// 真實模型名(用它驗證 int8/float 擇一的規則)。
const _realModel = 'sherpa-onnx-streaming-zipformer-bilingual-zh-en-2023-02-20';

ModelInstaller _testInstaller({http.Client Function()? clientFactory}) =>
    ModelInstaller(
      httpClientFactory: clientFactory,
      requiredFilesOverride: _testRequired,
    );

/// 在假的 support 目錄下建立模型資料夾與(空)檔案。
Future<Directory> _makeModelDir(String modelName, List<String> files) async {
  final root = await ModelPaths.root();
  final dir = Directory(p.join(root.path, modelName));
  await dir.create(recursive: true);
  for (final rel in files) {
    final f = File(p.join(dir.path, rel));
    await f.parent.create(recursive: true);
    await f.writeAsString('dummy');
  }
  return dir;
}

/// 產生內含 [entries](路徑→內容)的 tar.bz2,寫到模型的暫存壓縮檔位置。
Future<File> _makeArchive(String modelName, Map<String, String> entries) async {
  final archive = Archive();
  for (final e in entries.entries) {
    archive.addFile(ArchiveFile.string(e.key, e.value));
  }
  final tarBytes = TarEncoder().encode(archive);
  final bz2 = BZip2Encoder().encodeBytes(tarBytes);
  final zip = await ModelPaths.archiveFile(modelName);
  await zip.writeAsBytes(bz2, flush: true);
  return zip;
}

/// 回傳固定回應的 mock client 工廠。
http.Client Function() _mockResponse({
  required int statusCode,
  List<List<int>> chunks = const [],
  int? contentLength,
}) {
  return () => MockClient.streaming((request, bodyStream) async {
        return http.StreamedResponse(
          Stream.fromIterable(chunks),
          statusCode,
          contentLength: contentLength,
        );
      });
}

class _ThrowingClient extends http.BaseClient {
  _ThrowingClient(this.error);
  final Object error;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    throw error;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempRoot;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('installer_test_');
    PathProviderPlatform.instance = FakePathProviderPlatform(tempRoot);
  });

  tearDown(() async {
    if (await tempRoot.exists()) {
      await tempRoot.delete(recursive: true);
    }
  });

  group('status()', () {
    test('無資料夾也無 zip → needsDownload', () async {
      expect(
        await _testInstaller().status(_testModel),
        InstallStatus.needsDownload,
      );
    });

    test('只有 zip → needsUnzip', () async {
      await _makeArchive(_testModel, {'$_testModel/tokens.txt': 'x'});
      expect(
        await _testInstaller().status(_testModel),
        InstallStatus.needsUnzip,
      );
    });

    test('資料夾齊全 → ready', () async {
      await _makeModelDir(_testModel, ['tokens.txt']);
      expect(await _testInstaller().status(_testModel), InstallStatus.ready);
    });

    test('資料夾缺檔 + zip 在 → needsUnzip(不用重新下載)', () async {
      await _makeModelDir(_testModel, ['other.txt']);
      await _makeArchive(_testModel, {'$_testModel/tokens.txt': 'x'});
      expect(
        await _testInstaller().status(_testModel),
        InstallStatus.needsUnzip,
      );
    });

    test('資料夾缺檔 + zip 不在 → incompleteNeedsDownload', () async {
      await _makeModelDir(_testModel, ['other.txt']);
      expect(
        await _testInstaller().status(_testModel),
        InstallStatus.incompleteNeedsDownload,
      );
    });
  });

  group('modelFilesComplete()', () {
    test('int8/float 擇一:只有 float 版也算齊全', () async {
      await _makeModelDir(_realModel, [
        'encoder-epoch-99-avg-1.onnx', // float 版(清單第二選項)
        'decoder-epoch-99-avg-1.onnx',
        'joiner-epoch-99-avg-1.onnx',
        'tokens.txt',
      ]);
      expect(await ModelInstaller().modelFilesComplete(_realModel), isTrue);
    });

    test('缺 joiner → 不齊全', () async {
      await _makeModelDir(_realModel, [
        'encoder-epoch-99-avg-1.int8.onnx',
        'decoder-epoch-99-avg-1.onnx',
        'tokens.txt',
      ]);
      expect(await ModelInstaller().modelFilesComplete(_realModel), isFalse);
    });

    test('未登錄的模型不做驗證 → 視為齊全', () async {
      expect(
        await ModelInstaller().modelFilesComplete('some-unknown-model'),
        isTrue,
      );
    });
  });

  group('download()', () {
    test('成功:寫出完整檔案並回報進度到 1.0', () async {
      final chunks = [
        List.filled(30, 1),
        List.filled(70, 2),
      ];
      final installer = _testInstaller(
        clientFactory: _mockResponse(
          statusCode: 200,
          chunks: chunks,
          contentLength: 100,
        ),
      );

      final progresses = <double>[];
      await installer.download(_testModel, onProgress: progresses.add);

      final zip = await ModelPaths.archiveFile(_testModel);
      expect(await zip.length(), 100);
      expect(progresses.last, 1.0);
    });

    test('404 → InstallException(server),殘檔刪除', () async {
      final installer = _testInstaller(
        clientFactory: _mockResponse(statusCode: 404),
      );

      await expectLater(
        installer.download(_testModel),
        throwsA(
          isA<InstallException>().having(
            (e) => e.reason,
            'reason',
            InstallFailureReason.server,
          ),
        ),
      );
      expect(await (await ModelPaths.archiveFile(_testModel)).exists(), false);
    });

    test('SocketException → InstallException(network)', () async {
      final installer = _testInstaller(
        clientFactory: () => _ThrowingClient(const SocketException('no net')),
      );

      await expectLater(
        installer.download(_testModel),
        throwsA(
          isA<InstallException>().having(
            (e) => e.reason,
            'reason',
            InstallFailureReason.network,
          ),
        ),
      );
    });

    test('TimeoutException → InstallException(timeout)', () async {
      final installer = _testInstaller(
        clientFactory: () => _ThrowingClient(TimeoutException('stalled')),
      );

      await expectLater(
        installer.download(_testModel),
        throwsA(
          isA<InstallException>().having(
            (e) => e.reason,
            'reason',
            InstallFailureReason.timeout,
          ),
        ),
      );
    });

    test('使用者取消 → UserCancelledException,殘檔刪除', () async {
      final installer = _testInstaller(
        clientFactory: _mockResponse(
          statusCode: 200,
          chunks: [List.filled(10, 1), List.filled(10, 2)],
          contentLength: 20,
        ),
      );

      await expectLater(
        installer.download(_testModel, isCancelled: () => true),
        throwsA(isA<UserCancelledException>()),
      );
      expect(await (await ModelPaths.archiveFile(_testModel)).exists(), false);
    });

    test('實際大小與宣告不符 → InstallException(unknown),殘檔刪除', () async {
      final installer = _testInstaller(
        clientFactory: _mockResponse(
          statusCode: 200,
          chunks: [List.filled(10, 1)],
          contentLength: 100, // 宣告 100,實收 10
        ),
      );

      await expectLater(
        installer.download(_testModel),
        throwsA(
          isA<InstallException>().having(
            (e) => e.reason,
            'reason',
            InstallFailureReason.unknown,
          ),
        ),
      );
      expect(await (await ModelPaths.archiveFile(_testModel)).exists(), false);
    });
  });

  group('unzipAndVerify()', () {
    test('成功:解出檔案、驗證通過、刪除 zip、回報進度', () async {
      await _makeArchive(_testModel, {
        '$_testModel/tokens.txt': 'token-data',
        '$_testModel/extra/readme.md': 'hello',
      });
      final installer = _testInstaller();

      final progresses = <double>[];
      await installer.unzipAndVerify(_testModel, onProgress: progresses.add);

      final root = await ModelPaths.root();
      final tokens = File(p.join(root.path, _testModel, 'tokens.txt'));
      expect(await tokens.readAsString(), 'token-data');
      expect(await installer.status(_testModel), InstallStatus.ready);
      expect(await (await ModelPaths.archiveFile(_testModel)).exists(), false);
      expect(progresses.first, 0.0); // 解碼完成訊號
      expect(progresses.last, 1.0);
    });

    test('zip 損毀 → InstallException(需重新下載),zip 刪除', () async {
      final zip = await ModelPaths.archiveFile(_testModel);
      await zip.writeAsBytes(List.filled(64, 42)); // 垃圾位元組
      final installer = _testInstaller();

      // archive 套件對垃圾位元組可能拋錯(corruptedArchive)或回傳空檔案清單
      // (最後被驗證攔下 → verificationFailed);兩者 UI 處理相同:刪 zip 重新下載。
      await expectLater(
        installer.unzipAndVerify(_testModel),
        throwsA(
          isA<InstallException>().having(
            (e) => e.reason,
            'reason',
            isIn([
              InstallFailureReason.corruptedArchive,
              InstallFailureReason.verificationFailed,
            ]),
          ),
        ),
      );
      expect(await zip.exists(), false);
    });

    test('解壓成功但缺關鍵檔案 → verificationFailed,zip 刪除', () async {
      // zip 裡只有 other.txt,但驗證要求 tokens.txt
      await _makeArchive(_testModel, {'$_testModel/other.txt': 'x'});
      final installer = _testInstaller();

      await expectLater(
        installer.unzipAndVerify(_testModel),
        throwsA(
          isA<InstallException>().having(
            (e) => e.reason,
            'reason',
            InstallFailureReason.verificationFailed,
          ),
        ),
      );
      expect(await (await ModelPaths.archiveFile(_testModel)).exists(), false);
    });

    test('使用者取消 → UserCancelledException,zip 保留', () async {
      final zip = await _makeArchive(_testModel, {
        '$_testModel/tokens.txt': 'x',
      });
      final installer = _testInstaller();

      await expectLater(
        installer.unzipAndVerify(_testModel, isCancelled: () => true),
        throwsA(isA<UserCancelledException>()),
      );
      expect(await zip.exists(), true); // 之後可只重試解壓,不用重新下載
    });
  });
}
