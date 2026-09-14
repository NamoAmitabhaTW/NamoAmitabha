// test/features/asr/application/asr_session_controller_test.dart
// 念佛工作階段的狀態機，以及計數在 App 被中斷時不會消失。
// 進背景與 detached 各自落地，連回呼都來不及跑就靠錄音中的定時草稿；
// 計數先寫成 pending 暫存再重放，重放以 sessionId 去重，失敗留在原地等下次。

import 'dart:io';
import 'package:amitabha/core/infrastructure/atomic_io.dart';
import 'package:amitabha/core/utils/date_format.dart';
import 'package:amitabha/features/asr/asr.dart';
import 'package:amitabha/features/asr/data/chanting_paths.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import '../../../helpers/asr_controller.dart';
import '../../../helpers/fake_path_provider.dart';

class _FakeSource implements SpeechSegmentSource {
  void Function(String)? _onSegment;
  int startCalls = 0;
  int stopCalls = 0;
  bool disposed = false;
  bool permission = true;

  @override
  Future<bool> hasPermission() async => permission;

  @override
  Future<void> start({required void Function(String text) onSegment}) async {
    startCalls++;
    _onSegment = onSegment;
  }

  @override
  Future<void> stop() async {
    stopCalls++;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
  }

  void emit(String text) => _onSegment?.call(text);
}

class _FailingDailyRepo implements DailyRepository {
  final DailyRepository _inner = const FileDailyRepository();

  @override
  Future<void> addCount(String yyyymmdd, int delta) =>
      _inner.addCount(yyyymmdd, delta);

  @override
  Future<void> addCountForSession(
    String yyyymmdd,
    int delta,
    String sessionId,
  ) async {
    throw const FileSystemException('simulated disk failure');
  }

  @override
  Future<List<DailySummary>> readAll() => _inner.readAll();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempRoot;
  late _FakeSource source;

  AsrSessionController makeController({
    DailyRepository? dailyRepo,
    Duration? draftEvery,
  }) => fileBackedAsrController(
    sourceFactory: () => source,
    dailyRepo: dailyRepo,
    draftEvery: draftEvery,
  );

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('asr_ctrl_test_');
    PathProviderPlatform.instance = FakePathProviderPlatform(tempRoot);
    source = _FakeSource();
  });

  tearDown(() async {
    for (var attempt = 0; attempt < 5; attempt++) {
      try {
        if (await tempRoot.exists()) {
          await tempRoot.delete(recursive: true);
        }
        return;
      } on FileSystemException {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    }
  });

  test('狀態機:idle → recording → paused → save 後回 idle', () async {
    final c = makeController();
    expect(c.sessionState, SessionState.idle);

    await c.start();
    expect(c.sessionState, SessionState.recording);
    expect(c.isRecording, isTrue);
    expect(source.startCalls, 1);

    await c.stop();
    expect(c.sessionState, SessionState.paused);
    expect(source.stopCalls, 1);

    await c.start();
    expect(c.sessionState, SessionState.recording);

    source.emit('阿彌陀佛');
    await c.save();
    expect(c.sessionState, SessionState.idle);
    expect(c.sessionCount, 0);

    c.dispose();
  });

  test('命中累計:符合的語句累計、不符合的忽略', () async {
    final c = makeController();
    await c.start();

    source.emit('阿彌陀佛阿彌陀佛');
    expect(c.sessionCount, 2);
    expect(c.lastHitAt, isNotNull);

    source.emit('南無觀世音菩薩');
    expect(c.sessionCount, 2);

    source.emit('阿弥陀佛');
    expect(c.sessionCount, 3);

    c.dispose();
  });

  test('save:寫入 snapshot 與 daily、歸零、dataVersion+1、journal 清空', () async {
    final c = makeController();
    await c.start();
    source.emit('阿彌陀佛');
    source.emit('阿彌陀佛');
    final sessionId = c.currentSessionId!;
    final versionBefore = c.dataVersion;

    await c.save();

    expect(c.sessionCount, 0);
    expect(c.dataVersion, versionBefore + 1);

    final got = await const FileSessionRepository().readSnapshot(sessionId);
    expect(got, isNotNull);
    expect(got!.amitabhaCount, 2);

    final daily = await readJsonOrEmpty(
      await ChantingPaths.daily(nowYmdLocal()),
    );
    expect(daily['amitabhaCount'], 2);
    expect((daily['sessionIds'] as List).contains(sessionId), isTrue);

    expect(await const FilePendingCommitStore().list(), isEmpty);

    c.dispose();
  });

  test('save:計數為 0 → 不做任何事', () async {
    final c = makeController();
    await c.start();
    final versionBefore = c.dataVersion;

    await c.save();

    expect(c.sessionState, SessionState.recording);
    expect(c.dataVersion, versionBefore);
    expect(await const FilePendingCommitStore().list(), isEmpty);

    c.dispose();
  });

  test('daily 寫入失敗 → 計數保留在 journal,重放後補寫成功且不重複', () async {
    final broken = makeController(dailyRepo: _FailingDailyRepo());
    await broken.start();
    source.emit('阿彌陀佛');
    source.emit('阿彌陀佛');
    source.emit('阿彌陀佛');
    final sessionId = broken.currentSessionId!;

    await broken.save();

    expect(broken.sessionCount, 0);
    final pendingAfterFail = await const FilePendingCommitStore().list();
    expect(pendingAfterFail, hasLength(1));
    expect(pendingAfterFail.first.snapshot.amitabhaCount, 3);
    broken.dispose();

    final healthy = makeController();
    await healthy.replayPending();

    final daily = await readJsonOrEmpty(
      await ChantingPaths.daily(nowYmdLocal()),
    );
    expect(daily['amitabhaCount'], 3);
    expect(await const FilePendingCommitStore().list(), isEmpty);

    const store = FilePendingCommitStore();
    await store.add(pendingAfterFail.first);
    await healthy.replayPending();
    final daily2 = await readJsonOrEmpty(
      await ChantingPaths.daily(nowYmdLocal()),
    );
    expect(daily2['amitabhaCount'], 3);
    expect(await const FilePendingCommitStore().list(), isEmpty);

    expect(sessionId, isNotEmpty);
    healthy.dispose();
  });

  test('addCountForSession 幂等:同 sessionId 重複呼叫只累計一次', () async {
    const repo = FileDailyRepository();
    const ymd = '20260707';

    await repo.addCountForSession(ymd, 5, 'sess-1');
    await repo.addCountForSession(ymd, 5, 'sess-1');
    await repo.addCountForSession(ymd, 2, 'sess-2');

    final daily = await readJsonOrEmpty(await ChantingPaths.daily(ymd));
    expect(daily['amitabhaCount'], 7);
  });

  test('App 進背景(paused)→ 錄音中自動暫停', () async {
    final c = makeController();
    await c.start();
    expect(c.isRecording, isTrue);

    c.didChangeAppLifecycleState(AppLifecycleState.paused);
    await Future<void>.delayed(Duration.zero);

    expect(c.sessionState, SessionState.paused);
    expect(source.stopCalls, 1);

    c.dispose();
  });

  test('進背景寫入草稿;App 被殺後重啟重放,計數不丟', () async {
    final c = makeController();
    await c.start();
    source.emit('阿彌陀佛');
    source.emit('阿彌陀佛');
    final sessionId = c.currentSessionId!;

    c.didChangeAppLifecycleState(AppLifecycleState.paused);
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while ((await const FilePendingCommitStore().list()).isEmpty) {
      if (DateTime.now().isAfter(deadline)) fail('draft not written in time');
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    final draft = (await const FilePendingCommitStore().list()).single;
    expect(draft.snapshot.sessionId, sessionId);
    expect(draft.snapshot.amitabhaCount, 2);
    expect(c.sessionCount, 2);
    c.dispose();

    final relaunched = makeController();
    await relaunched.replayPending();

    final daily = await readJsonOrEmpty(
      await ChantingPaths.daily(nowYmdLocal()),
    );
    expect(daily['amitabhaCount'], 2);
    expect(await const FilePendingCommitStore().list(), isEmpty);
    relaunched.dispose();
  });

  test('草稿後回前景繼續念、正常儲存 → 以最終數字覆蓋,不重複計數', () async {
    final c = makeController();
    await c.start();
    source.emit('阿彌陀佛');

    c.didChangeAppLifecycleState(AppLifecycleState.paused);
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while ((await const FilePendingCommitStore().list()).isEmpty) {
      if (DateTime.now().isAfter(deadline)) fail('draft not written in time');
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }

    await c.start();
    source.emit('阿彌陀佛阿彌陀佛');
    await c.save();

    final daily = await readJsonOrEmpty(
      await ChantingPaths.daily(nowYmdLocal()),
    );
    expect(daily['amitabhaCount'], 3);
    expect(await const FilePendingCommitStore().list(), isEmpty);

    c.dispose();
  });

  test('App 被殺(detached)→ 未儲存的計數自動提交', () async {
    final c = makeController();
    await c.start();
    source.emit('阿彌陀佛');
    final sessionId = c.currentSessionId!;
    final versionBefore = c.dataVersion;

    c.didChangeAppLifecycleState(AppLifecycleState.detached);

    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (c.dataVersion == versionBefore) {
      if (DateTime.now().isAfter(deadline)) {
        fail('detached commit did not complete in time');
      }
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }

    expect(c.sessionCount, 0);
    final got = await const FileSessionRepository().readSnapshot(sessionId);
    expect(got?.amitabhaCount, 1);

    c.dispose();
  });

  group('定時草稿', () {
    const store = FilePendingCommitStore();
    const tick = Duration(milliseconds: 20);

    /// 輪詢等待，比固定 sleep 穩定：計時器與寫檔都是非同步的。
    Future<void> waitUntil(
      Future<bool> Function() ready, {
      Duration timeout = const Duration(seconds: 3),
    }) async {
      final sw = Stopwatch()..start();
      while (sw.elapsed < timeout) {
        if (await ready()) return;
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      fail('等待逾時');
    }

    test('錄音中計時器到點 → 寫出草稿，內容是當下的累計數', () async {
      final c = makeController(draftEvery: tick);
      addTearDown(c.dispose);

      await c.start();
      source.emit('阿彌陀佛阿彌陀佛');

      await waitUntil(() async => (await store.list()).isNotEmpty);

      final pending = await store.list();
      expect(pending.single.snapshot.amitabhaCount, 2);
    });

    test('連續兩次草稿 → 仍只有一個檔，且是較新的總數（覆寫而非累加）', () async {
      final c = makeController(draftEvery: tick);
      addTearDown(c.dispose);

      await c.start();
      source.emit('阿彌陀佛');
      await waitUntil(() async => (await store.list()).isNotEmpty);

      source.emit('阿彌陀佛阿彌陀佛');
      await waitUntil(
        () async => (await store.list()).single.snapshot.amitabhaCount == 3,
      );

      // 草稿以 sessionId 命名、存的是累計總數，所以寫幾次都只有一個檔。
      expect(await store.list(), hasLength(1));
    });

    test('草稿之後程序被殺 → 重新啟動時把計數補回 daily', () async {
      final c = makeController(draftEvery: tick);
      await c.start();
      source.emit('阿彌陀佛阿彌陀佛');
      await waitUntil(() async => (await store.list()).isNotEmpty);

      // 不呼叫 save()，直接丟掉——模擬 native crash 或被系統殺掉。
      c.dispose();

      final relaunched = makeController();
      addTearDown(relaunched.dispose);
      await relaunched.replayPending();

      final days = await const FileDailyRepository().readAll();
      expect(days.single.amitabhaCount, 2);
      expect(await store.list(), isEmpty, reason: '補寫成功後草稿要清掉');
    });

    test('還沒念佛時計時器到點 → 不產生草稿檔', () async {
      final c = makeController(draftEvery: tick);
      addTearDown(c.dispose);

      await c.start();
      await Future<void>.delayed(const Duration(milliseconds: 120));

      expect(await store.list(), isEmpty);
    });

    test('stop() 之後計時器不再觸發', () async {
      final c = makeController(draftEvery: tick);
      addTearDown(c.dispose);

      await c.start();
      source.emit('阿彌陀佛');
      await waitUntil(() async => (await store.list()).isNotEmpty);

      await c.stop();
      await store.remove(c.currentSessionId!);
      await Future<void>.delayed(const Duration(milliseconds: 120));

      expect(await store.list(), isEmpty, reason: '暫停後不該再寫草稿');
    });

    test('dispose() 之後計時器不再觸發', () async {
      final c = makeController(draftEvery: tick);
      await c.start();
      source.emit('阿彌陀佛');
      await waitUntil(() async => (await store.list()).isNotEmpty);

      final sessionId = c.currentSessionId!;
      c.dispose();
      await store.remove(sessionId);
      await Future<void>.delayed(const Duration(milliseconds: 120));

      expect(await store.list(), isEmpty, reason: '釋放後不該再寫草稿');
    });
  });
}
