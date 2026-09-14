// test/features/asr/data/legacy_schema_compat_test.dart
// 既有使用者升級後不掉念佛記錄，用真的舊格式檔案跑一遍，而不是靠推論。
// 涵蓋架上的 1.x 與開發機的 2.0.0；寫回時升為 schemaVersion 2、
// 清掉登入殘留欄位，但數字原封不動。

import 'dart:convert';
import 'dart:io';
import 'package:amitabha/features/asr/asr.dart';
import 'package:amitabha/features/asr/data/chanting_paths.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import '../../../helpers/fake_path_provider.dart';

Map<String, dynamic> _dailyV1({required String date, required int count}) => {
  'schemaVersion': 1,
  'date': date,
  'userId': 'local',
  'userName': '使用者',
  'amitabhaCount': count,
};

Map<String, dynamic> _dailyV2Legacy({
  required String date,
  required int count,
  List<String> sessionIds = const [],
}) => {..._dailyV1(date: date, count: count), 'sessionIds': sessionIds};

Map<String, dynamic> _legacySnapshot({
  required String sessionId,
  required int count,
}) => {
  'schemaVersion': 1,
  'sessionId': sessionId,
  'userId': 'local',
  'userName': '使用者',
  'startedAt': '2026-08-08T01:00:00.000Z',
  'lastAt': '2026-08-08T01:30:00.000Z',
  'amitabhaCount': count,
};

Future<void> _writeRaw(File file, Map<String, dynamic> json) async {
  await file.parent.create(recursive: true);
  await file.writeAsString(
    const JsonEncoder.withIndent('  ').convert(json),
    flush: true,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempRoot;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('legacy_schema_test_');
    PathProviderPlatform.instance = FakePathProviderPlatform(tempRoot);
  });

  tearDown(() async {
    if (await tempRoot.exists()) {
      await tempRoot.delete(recursive: true);
    }
  });

  // 1.x 的 daily 檔沒有 sessionIds，缺鍵必須視為空清單。
  group('升級自 1.x（目前架上的版本）', () {
    test('日結讀得出來，佛號數不變；缺少的 sessionIds 視為空清單', () async {
      await _writeRaw(
        await ChantingPaths.daily('20260808'),
        _dailyV1(date: '20260808', count: 10800),
      );

      final days = await const FileDailyRepository().readAll();

      expect(days, hasLength(1));
      expect(days.single.yyyymmdd, '20260808');
      expect(days.single.amitabhaCount, 10800);
      expect(days.single.sessionIds, isEmpty);
    });

    test('在 1.x 舊檔上繼續累加，既有計數不會被蓋掉', () async {
      await _writeRaw(
        await ChantingPaths.daily('20260808'),
        _dailyV1(date: '20260808', count: 10800),
      );

      await const FileDailyRepository().addCount('20260808', 108);

      final days = await const FileDailyRepository().readAll();
      expect(days.single.amitabhaCount, 10908);
    });

    test('升級後第一次念佛，去重機制從空清單正常接上', () async {
      await _writeRaw(
        await ChantingPaths.daily('20260808'),
        _dailyV1(date: '20260808', count: 10800),
      );

      const repo = FileDailyRepository();
      await repo.addCountForSession('20260808', 108, 'sess-new');
      await repo.addCountForSession('20260808', 108, 'sess-new');

      final days = await repo.readAll();
      expect(days.single.amitabhaCount, 10908);
      expect(days.single.sessionIds, ['sess-new']);
    });

    test('多天的舊記錄一次讀出，並由新到舊排序', () async {
      for (final day in [
        ('20260806', 300),
        ('20260807', 12345),
        ('20260808', 88),
      ]) {
        await _writeRaw(
          await ChantingPaths.daily(day.$1),
          _dailyV1(date: day.$1, count: day.$2),
        );
      }

      final days = await const FileDailyRepository().readAll();

      expect(days.map((d) => d.yyyymmdd), ['20260808', '20260807', '20260806']);
      expect(days.fold<int>(0, (s, d) => s + d.amitabhaCount), 12733);
    });

    test('工作階段結算讀得出來', () async {
      await _writeRaw(
        await ChantingPaths.sessionSnapshot('sess-legacy'),
        _legacySnapshot(sessionId: 'sess-legacy', count: 432),
      );

      final snap = await const FileSessionRepository().readSnapshot(
        'sess-legacy',
      );

      expect(snap, isNotNull);
      expect(snap!.sessionId, 'sess-legacy');
      expect(snap.amitabhaCount, 432);
      expect(snap.startedAt, DateTime.utc(2026, 8, 8, 1, 0));
    });
  });

  // 2.0.0 多了 sessionIds 與 pending 暫存，兩者都要能接上。
  group('升級自 2.0.0（未上架，僅開發機）', () {
    test('帶 sessionIds 的日結，去重仍然有效', () async {
      await _writeRaw(
        await ChantingPaths.daily('20260808'),
        _dailyV2Legacy(
          date: '20260808',
          count: 500,
          sessionIds: const ['sess-a'],
        ),
      );

      await const FileDailyRepository().addCountForSession(
        '20260808',
        500,
        'sess-a',
      );

      final days = await const FileDailyRepository().readAll();
      expect(days.single.amitabhaCount, 500);
      expect(days.single.sessionIds, ['sess-a']);
    });

    test('升級當下未寫入的暫存結算（pending）不會遺失', () async {
      await _writeRaw(await ChantingPaths.pendingCommit('sess-pending'), {
        'schemaVersion': 1,
        'ymd': '20260808',
        'snapshot': _legacySnapshot(sessionId: 'sess-pending', count: 1080),
      });

      final pending = await const FilePendingCommitStore().list();

      expect(pending, hasLength(1));
      expect(pending.single.ymd, '20260808');
      expect(pending.single.snapshot.amitabhaCount, 1080);
      expect(pending.single.snapshot.sessionId, 'sess-pending');
    });
  });

  // schemaVersion 升為 2 並移除登入殘留欄位，但數字原封不動。
  group('寫回：新版覆寫舊檔之後', () {
    test('升級為 schemaVersion 2 並移除登入殘留欄位，但數字原封不動', () async {
      final file = await ChantingPaths.daily('20260808');
      await _writeRaw(file, _dailyV1(date: '20260808', count: 10800));

      await const FileDailyRepository().addCount('20260808', 8);

      final written =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;

      expect(written['schemaVersion'], 2);
      expect(written.containsKey('userId'), isFalse);
      expect(written.containsKey('userName'), isFalse);

      expect(written['date'], '20260808');
      expect(written['amitabhaCount'], 10808);
    });
  });
}
