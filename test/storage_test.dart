import 'dart:convert';
import 'dart:io';
import 'package:amitabha/core/infrastructure/atomic_io.dart';
import 'package:amitabha/core/infrastructure/json_prefs_file.dart';
import 'package:amitabha/features/asr/asr.dart';
import 'package:amitabha/features/asr/data/chanting_paths.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'helpers/fake_path_provider.dart';

String _nowYmdLocal() {
  final n = DateTime.now();
  return '${n.year.toString().padLeft(4, '0')}'
      '${n.month.toString().padLeft(2, '0')}'
      '${n.day.toString().padLeft(2, '0')}';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempRoot;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('namo_test_');
    PathProviderPlatform.instance = FakePathProviderPlatform(tempRoot);
  });

  tearDown(() async {
    if (await tempRoot.exists()) {
      await tempRoot.delete(recursive: true);
    }
  });

  test('FileDailyRepository.addCount 累加成功', () async {
    const repo = FileDailyRepository();
    final ymd = _nowYmdLocal();

    await repo.addCount(ymd, 3);
    await repo.addCount(ymd, 2);

    final file = await ChantingPaths.daily(ymd);
    final j = await readJsonOrEmpty(file);

    expect(j['date'], ymd);
    expect(j['amitabhaCount'], 5);
  });

  test('FileSessionRepository upsert / read 往返', () async {
    const repo = FileSessionRepository();
    final s = SessionSnapshot(
      sessionId: 's1',
      startedAt: DateTime.now().toUtc(),
      lastAt: DateTime.now().toUtc(),
      amitabhaCount: 42,
    );

    await repo.upsertSnapshot(s);
    final got = await repo.readSnapshot('s1');

    expect(got, isNotNull);
    expect(got!.sessionId, 's1');
    expect(got.amitabhaCount, 42);
  });

  test('FileHitLog.appendMany 會寫出 NDJSON 且可輪檔', () async {
    final logger = FileHitLog('sessA', rotateEvery: 2);

    await logger.appendMany([
      DateTime.now().toUtc(),
      DateTime.now().toUtc(),
      DateTime.now().toUtc(),
    ]);

    final f1 = await ChantingPaths.sessionHits('sessA', part: 1);
    final f2 = await ChantingPaths.sessionHits('sessA', part: 2);

    expect(await f1.exists(), isTrue);
    expect(await f2.exists(), isTrue);

    final l1 = await f1.readAsLines();
    final l2 = await f2.readAsLines();

    expect(l1.length, 2);
    expect(l2.length, 1);

    final obj = jsonDecode(l1.first);
    expect(obj, contains('t'));
  });

  test('atomicWriteJson 原子寫入成功', () async {
    final file = File(p.join(tempRoot.path, 'namo', 'data', 'x.json'));
    await atomicWriteJson(file, {'a': 1});
    final j = await readJsonOrEmpty(file);
    expect(j['a'], 1);
  });

  test('JsonPrefsFile 寫入/讀回往返', () async {
    final prefs = JsonPrefsFile('test_prefs');
    expect(await prefs.read(), isNull);

    await prefs.write({'theme_style': 'zenWood', 'n': 3});
    final j = await prefs.read();
    expect(j?['theme_style'], 'zenWood');
    expect(j?['n'], 3);
  });

  test('JsonPrefsFile 檔案損毀 → 回 null 不拋錯', () async {
    final prefs = JsonPrefsFile('broken_prefs');
    final f = await prefs.file();
    await f.writeAsString('{oops not json');
    expect(await prefs.read(), isNull);
  });
}
