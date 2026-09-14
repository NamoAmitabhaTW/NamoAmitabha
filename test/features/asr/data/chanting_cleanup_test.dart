// test/features/asr/data/chanting_cleanup_test.dart
// 這支清理程式會永久刪除使用者裝置上的檔案，所以兩個方向都要守：舊版留下的
// 流水帳（sessions/*-hits-N.ndjson，含編號不連續的孤兒）要刪乾淨，同目錄的
// 工作階段快照、daily 與設定一個都不能碰。

import 'dart:io';

import 'package:amitabha/core/infrastructure/json_prefs_file.dart';
import 'package:amitabha/features/asr/asr.dart';
import 'package:amitabha/features/asr/data/chanting_paths.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import '../../../helpers/fake_path_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempRoot;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('namo_cleanup_');
    PathProviderPlatform.instance = FakePathProviderPlatform(tempRoot);
  });

  tearDown(() async {
    if (await tempRoot.exists()) {
      await tempRoot.delete(recursive: true);
    }
  });

  Future<File> touch(String name) async {
    final dir = await ChantingPaths.sessionsDir();
    if (!await dir.exists()) await dir.create(recursive: true);
    final f = File(p.join(dir.path, name));
    await f.writeAsString('x');
    return f;
  }

  Future<List<String>> sessionFiles() async {
    final dir = await ChantingPaths.sessionsDir();
    if (!await dir.exists()) return const [];
    final names = await dir
        .list()
        .where((e) => e is File)
        .map((f) => p.basename(f.path))
        .toList();
    names.sort();
    return names;
  }

  test('刪光流水帳（含非連續編號），保留工作階段快照', () async {
    await touch('1700000000000-hits-1.ndjson');
    await touch('1700000000000-hits-2.ndjson');
    // 編號中間缺 3——舊的 FileHitLog 是靠「下一個 part 存不存在」往上走的，
    // 照那個邏輯刪會在這裡停住，留下 hits-4 這個永遠刪不到的孤兒。
    await touch('1700000000000-hits-4.ndjson');
    await touch('1700000000000.json');
    await touch('1700000000001.json');

    await purgeLegacyHitLogs();

    expect(await sessionFiles(), ['1700000000000.json', '1700000000001.json']);
  });

  test('第二次執行是 no-op：標記生效，不再掃描', () async {
    await touch('1700000000000-hits-1.ndjson');
    await purgeLegacyHitLogs();

    final marker = await JsonPrefsFile('storage_cleanup').read();
    expect(marker?['purgeVersion'], 1);

    // 標記已經寫下，就算再放一個進來也不該被碰——證明它真的靠標記跳過，
    // 而不是每次都重掃一遍。
    await touch('1700000000002-hits-1.ndjson');
    await purgeLegacyHitLogs();

    expect(await sessionFiles(), ['1700000000002-hits-1.ndjson']);
  });

  test('sessions/ 不存在時不拋錯，而且照樣寫下標記', () async {
    final dir = await ChantingPaths.sessionsDir();
    expect(await dir.exists(), isFalse, reason: '前置條件：目錄還沒被建立');

    await purgeLegacyHitLogs();

    final marker = await JsonPrefsFile('storage_cleanup').read();
    expect(marker?['purgeVersion'], 1);
  });

  test('只碰念佛的 sessions/，不碰 daily 與 settings', () async {
    await touch('1700000000000-hits-1.ndjson');
    final daily = await ChantingPaths.daily('20260914');
    await daily.writeAsString('{}');
    await JsonPrefsFile('locale').write({'locale': 'zh_TW'});

    await purgeLegacyHitLogs();

    expect(await daily.exists(), isTrue);
    expect((await JsonPrefsFile('locale').read())?['locale'], 'zh_TW');
    expect(await sessionFiles(), isEmpty);
  });
}
