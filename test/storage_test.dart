import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:amitabha/storage/app_paths.dart';
import 'package:amitabha/storage/atomic_io.dart';
import 'package:amitabha/storage/daily_repo.dart';
import 'package:amitabha/storage/hit_logger.dart';
import 'package:amitabha/storage/models.dart';
import 'package:amitabha/storage/session_repo.dart';

String _nowYmdLocal() {
  final n = DateTime.now();
  return '${n.year.toString().padLeft(4, '0')}'
         '${n.month.toString().padLeft(2, '0')}'
         '${n.day.toString().padLeft(2, '0')}';
}

/// Mock path_provider
class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.docs);
  final Directory docs;
  @override
  Future<String?> getApplicationDocumentsPath() async => docs.path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempRoot;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('namo_test_');
    PathProviderPlatform.instance = _FakePathProvider(tempRoot);
  });

  tearDown(() async {
    if (await tempRoot.exists()) {
      await tempRoot.delete(recursive: true);
    }
  });

  test('DailyRepository.addCount 累加成功', () async {
    final repo = DailyRepository();
    final ymd = _nowYmdLocal();

    await repo.addCount(ymd, 'u1', '使用者', 3);
    await repo.addCount(ymd, 'u1', '使用者', 2);

    final file = await AppPaths.daily(ymd);
    final j = await readJsonOrEmpty(file);

    expect(j['date'], ymd);
    expect(j['amitabhaCount'], 5);
  });

  test('SessionRepository upsert / read 往返', () async {
    final repo = SessionRepository();
    final s = SessionSnapshot(
      sessionId: 's1',
      userId: 'u1',
      userName: '使用者',
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

  test('HitLogger.appendMany 會寫出 NDJSON 且可輪檔', () async {
    final logger = HitLogger('sessA', rotateEvery: 2);

    await logger.appendMany([
      DateTime.now().toUtc(),
      DateTime.now().toUtc(),
      DateTime.now().toUtc(),
    ]);

    final f1 = await AppPaths.sessionHits('sessA', part: 1);
    final f2 = await AppPaths.sessionHits('sessA', part: 2);

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
}