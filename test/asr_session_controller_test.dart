
import 'dart:io';
import 'package:amitabha/core/utils/date_format.dart';
import 'package:amitabha/features/asr/application/asr_session_controller.dart';
import 'package:amitabha/storage/app_paths.dart';
import 'package:amitabha/storage/atomic_io.dart';
import 'package:amitabha/storage/daily_repo.dart';
import 'package:amitabha/storage/pending_commits.dart';
import 'package:amitabha/storage/session_repo.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'helpers/fake_path_provider.dart';

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

class _FailingDailyRepo extends DailyRepository {
  @override
  Future<void> addCountForSession(
    String yyyymmdd,
    String userId,
    String userName,
    int delta,
    String sessionId,
  ) async {
    throw const FileSystemException('simulated disk failure');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempRoot;
  late _FakeSource source;

  AsrSessionController makeController({DailyRepository? dailyRepo}) {
    return AsrSessionController(
      sourceFactory: () => source,
      dailyRepo: dailyRepo,
      setWakelock: (_) async {},
    );
  }

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


    final got = await SessionRepository().readSnapshot(sessionId);
    expect(got, isNotNull);
    expect(got!.amitabhaCount, 2);

  
    final daily = await readJsonOrEmpty(await AppPaths.daily(nowYmdLocal()));
    expect(daily['amitabhaCount'], 2);
    expect((daily['sessionIds'] as List).contains(sessionId), isTrue);

    
    expect(await PendingCommitStore().list(), isEmpty);


    final hits = await AppPaths.sessionHits(sessionId);
    expect(await hits.exists(), isTrue);
    expect((await hits.readAsLines()).length, 2);

    c.dispose();
  });

  test('save:計數為 0 → 不做任何事', () async {
    final c = makeController();
    await c.start();
    final versionBefore = c.dataVersion;

    await c.save();

    expect(c.sessionState, SessionState.recording);  
    expect(c.dataVersion, versionBefore);
    expect(await PendingCommitStore().list(), isEmpty);

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
    final pendingAfterFail = await PendingCommitStore().list();
    expect(pendingAfterFail, hasLength(1));
    expect(pendingAfterFail.first.snapshot.amitabhaCount, 3);
    broken.dispose();


    final healthy = makeController();
    await healthy.replayPending();

    final daily = await readJsonOrEmpty(await AppPaths.daily(nowYmdLocal()));
    expect(daily['amitabhaCount'], 3);
    expect(await PendingCommitStore().list(), isEmpty);


    final store = PendingCommitStore();
    await store.add(pendingAfterFail.first); 
    await healthy.replayPending();
    final daily2 = await readJsonOrEmpty(await AppPaths.daily(nowYmdLocal()));
    expect(daily2['amitabhaCount'], 3); 
    expect(await PendingCommitStore().list(), isEmpty);

    expect(sessionId, isNotEmpty);
    healthy.dispose();
  });

  test('addCountForSession 幂等:同 sessionId 重複呼叫只累計一次', () async {
    final repo = DailyRepository();
    const ymd = '20260707';

    await repo.addCountForSession(ymd, 'u', 'n', 5, 'sess-1');
    await repo.addCountForSession(ymd, 'u', 'n', 5, 'sess-1'); 
    await repo.addCountForSession(ymd, 'u', 'n', 2, 'sess-2'); 

    final daily = await readJsonOrEmpty(await AppPaths.daily(ymd));
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
    while ((await PendingCommitStore().list()).isEmpty) {
      if (DateTime.now().isAfter(deadline)) fail('draft not written in time');
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    final draft = (await PendingCommitStore().list()).single;
    expect(draft.snapshot.sessionId, sessionId);
    expect(draft.snapshot.amitabhaCount, 2);
    expect(c.sessionCount, 2); 
    c.dispose();


    final relaunched = makeController();
    await relaunched.replayPending();

    final daily = await readJsonOrEmpty(await AppPaths.daily(nowYmdLocal()));
    expect(daily['amitabhaCount'], 2);
    expect(await PendingCommitStore().list(), isEmpty);
    relaunched.dispose();
  });

  test('草稿後回前景繼續念、正常儲存 → 以最終數字覆蓋,不重複計數', () async {
    final c = makeController();
    await c.start();
    source.emit('阿彌陀佛'); 

  
    c.didChangeAppLifecycleState(AppLifecycleState.paused);
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while ((await PendingCommitStore().list()).isEmpty) {
      if (DateTime.now().isAfter(deadline)) fail('draft not written in time');
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }

    
    await c.start();
    source.emit('阿彌陀佛阿彌陀佛'); 
    await c.save();


    final daily = await readJsonOrEmpty(await AppPaths.daily(nowYmdLocal()));
    expect(daily['amitabhaCount'], 3);
    expect(await PendingCommitStore().list(), isEmpty);

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
    final got = await SessionRepository().readSnapshot(sessionId);
    expect(got?.amitabhaCount, 1);

    c.dispose();
  });
}
