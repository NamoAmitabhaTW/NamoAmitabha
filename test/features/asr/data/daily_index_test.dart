// test/features/asr/data/daily_index_test.dart
//
// 索引是衍生資料，不是真相。這裡守的是兩件事：讀得到索引時真的走索引（快），
// 以及任何一種對不上的情況都能自己從 daily/ 重建（正確）。
//
// 「重建」這條路徑同時也是升級用的遷移，所以它壞掉的話，既有使用者升級後記錄
// 頁會直接空白——這些測試主要是在防那個。

import 'dart:convert';
import 'dart:io';

import 'package:amitabha/core/infrastructure/atomic_io.dart';
import 'package:amitabha/features/asr/asr.dart';
import 'package:amitabha/features/asr/data/chanting_paths.dart';
import 'package:amitabha/features/asr/data/daily_index.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import '../../../helpers/fake_path_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const repo = FileDailyRepository();
  late Directory tempRoot;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('namo_index_');
    PathProviderPlatform.instance = FakePathProviderPlatform(tempRoot);
  });

  tearDown(() async {
    if (await tempRoot.exists()) {
      await tempRoot.delete(recursive: true);
    }
  });

  /// 直接寫一個日結檔，繞過 repository。
  Future<void> writeDaily(
    String ymd,
    int count, {
    List<String> sessionIds = const [],
  }) async {
    final f = await ChantingPaths.daily(ymd);
    await atomicWriteJson(
      f,
      DailySummary(
        yyyymmdd: ymd,
        amitabhaCount: count,
        sessionIds: sessionIds,
      ).toJson(),
    );
  }

  test('索引不存在 → 從 daily/ 重建，並把索引寫出來', () async {
    await writeDaily('20260901', 100);
    await writeDaily('20260902', 200);

    final index = await ChantingPaths.dailyIndex();
    expect(await index.exists(), isFalse, reason: '前置條件：索引還不存在');

    final days = await repo.readAll();

    expect(days.map((d) => d.yyyymmdd), ['20260902', '20260901']);
    expect(days.map((d) => d.amitabhaCount), [200, 100]);
    expect(await index.exists(), isTrue, reason: '重建後應該把索引寫出來');
  });

  test('索引有效時真的走索引，不是每次重掃 daily/', () async {
    await writeDaily('20260901', 100);
    await repo.readAll(); // 建出索引

    // 檔案數不變，只改內容。走索引的話會拿到舊值。
    await writeDaily('20260901', 999);

    final days = await repo.readAll();
    expect(
      days.single.amitabhaCount,
      100,
      reason: '拿到 999 代表它重掃了 daily/，索引形同虛設',
    );
  });

  test('索引內容損毀 → 重建，不拋錯也不回空', () async {
    await writeDaily('20260901', 100);
    await repo.readAll();

    final index = await ChantingPaths.dailyIndex();
    await index.writeAsString('{壞掉的 json');

    final days = await repo.readAll();
    expect(days.single.amitabhaCount, 100);
  });

  test('schemaVersion 不符 → 視為無效並重建', () async {
    await writeDaily('20260901', 100);

    final index = await ChantingPaths.dailyIndex();
    await index.writeAsString(jsonEncode({'schemaVersion': 999, 'days': []}));

    final days = await repo.readAll();
    expect(days.single.amitabhaCount, 100);
  });

  test('筆數與 daily/ 對不上 → 重建並反映新檔', () async {
    await writeDaily('20260901', 100);
    await repo.readAll(); // 索引此時只有 1 筆

    // 繞過 repository 直接多塞一天，模擬索引寫入前當機的情況。
    await writeDaily('20260902', 200);

    final days = await repo.readAll();
    expect(days, hasLength(2));
    expect(days.first.yyyymmdd, '20260902');
  });

  test('addCountForSession 之後，索引與 daily/ 內容一致', () async {
    await repo.addCountForSession('20260901', 50, 'sess-a');
    await repo.readAll(); // 建出索引
    await repo.addCountForSession('20260901', 30, 'sess-b');

    final indexed = await DailyIndex.read();
    final onDisk = await readJsonOrEmpty(await ChantingPaths.daily('20260901'));

    expect(indexed, isNotNull);
    expect(indexed!.single.amitabhaCount, 80);
    expect(onDisk['amitabhaCount'], 80);
    expect(indexed.single.sessionIds, ['sess-a', 'sess-b']);
  });

  test('同一天多次累加 → 索引是最終值，不是累加錯誤', () async {
    await repo.addCount('20260901', 10);
    await repo.readAll();
    await repo.addCount('20260901', 10);
    await repo.addCount('20260901', 10);

    final days = await repo.readAll();
    expect(days.single.amitabhaCount, 30);
  });

  test('索引檔不在 daily/ 目錄內', () async {
    final index = await ChantingPaths.dailyIndex();
    final dailyDir = await ChantingPaths.dailyDir();

    expect(
      index.parent.path,
      isNot(dailyDir.path),
      reason: '放進 daily/ 的話，重建時的 dir.list() 會把它當成日結檔',
    );
  });

  test('壞掉的單日檔 → 重建時跳過那天，其餘照常', () async {
    await writeDaily('20260901', 100);
    await writeDaily('20260902', 200);

    final broken = await ChantingPaths.daily('20260903');
    await broken.writeAsString('{半截的 json');

    final days = await repo.readAll();
    expect(days.map((d) => d.yyyymmdd), ['20260902', '20260901']);
  });

  test('重建結果由新到舊排序', () async {
    await writeDaily('20260901', 1);
    await writeDaily('20260903', 3);
    await writeDaily('20260902', 2);

    final days = await repo.readAll();
    expect(
      days.map((d) => d.yyyymmdd),
      ['20260903', '20260902', '20260901'],
    );
  });
}
