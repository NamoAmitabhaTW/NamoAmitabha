// AsrSessionController 的單元測試:
// 狀態機、佛號計數、session 提交、journal 防丟計數與重放幂等、App 生命週期。
// 語音來源以 FakeSource 注入,不碰麥克風/sherpa;儲存層走真實檔案(假 path_provider)。
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:amitabha/features/asr/application/asr_session_controller.dart';
import 'package:amitabha/storage/app_paths.dart';
import 'package:amitabha/storage/atomic_io.dart';
import 'package:amitabha/storage/daily_repo.dart';
import 'package:amitabha/storage/pending_commits.dart';
import 'package:amitabha/storage/session_repo.dart';
import 'package:amitabha/core/utils/date_format.dart';

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

  /// 模擬辨識出一段語句。
  void emit(String text) => _onSegment?.call(text);
}

/// 模擬 daily 寫入失敗(磁碟錯誤)。
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
    // dispose() 裡的 buffer flush 是 fire-and-forget,可能還在寫檔;
    // 刪除失敗(Directory not empty)就稍等重試,避免與收尾寫入賽跑。
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
    // 多次重試仍失敗 → 放棄;殘留在系統暫存區的目錄無害
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

    await c.start(); // 續錄:不開新 session
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

    source.emit('南無觀世音菩薩'); // 不符合 → 不動
    expect(c.sessionCount, 2);

    source.emit('阿弥陀佛'); // 簡體也算
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

    // snapshot 落盤
    final got = await SessionRepository().readSnapshot(sessionId);
    expect(got, isNotNull);
    expect(got!.amitabhaCount, 2);

    // daily 累計
    final daily = await readJsonOrEmpty(await AppPaths.daily(nowYmdLocal()));
    expect(daily['amitabhaCount'], 2);
    expect((daily['sessionIds'] as List).contains(sessionId), isTrue);

    // journal 已清空
    expect(await PendingCommitStore().list(), isEmpty);

    // hit NDJSON 已寫出(buffer 於 commit 時 flush)
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

    expect(c.sessionState, SessionState.recording); // 沒被打斷
    expect(c.dataVersion, versionBefore);
    expect(await PendingCommitStore().list(), isEmpty);

    c.dispose();
  });

  test('daily 寫入失敗 → 計數保留在 journal,重放後補寫成功且不重複', () async {
    // 第一階段:daily 壞掉,save 之後 journal 應保留
    final broken = makeController(dailyRepo: _FailingDailyRepo());
    await broken.start();
    source.emit('阿彌陀佛');
    source.emit('阿彌陀佛');
    source.emit('阿彌陀佛');
    final sessionId = broken.currentSessionId!;

    await broken.save();

    expect(broken.sessionCount, 0); // UI 照樣歸零(資料已安全落在 journal)
    final pendingAfterFail = await PendingCommitStore().list();
    expect(pendingAfterFail, hasLength(1));
    expect(pendingAfterFail.first.snapshot.amitabhaCount, 3);
    broken.dispose();

    // 第二階段:修好的 repo 重放 → daily 補寫、journal 清空
    final healthy = makeController();
    await healthy.replayPending();

    final daily = await readJsonOrEmpty(await AppPaths.daily(nowYmdLocal()));
    expect(daily['amitabhaCount'], 3);
    expect(await PendingCommitStore().list(), isEmpty);

    // 幂等:再重放一次(模擬重複執行)不會重複累計
    final store = PendingCommitStore();
    await store.add(pendingAfterFail.first); // 假裝 journal 沒刪成功
    await healthy.replayPending();
    final daily2 = await readJsonOrEmpty(await AppPaths.daily(nowYmdLocal()));
    expect(daily2['amitabhaCount'], 3); // 同 sessionId → 跳過
    expect(await PendingCommitStore().list(), isEmpty);

    expect(sessionId, isNotEmpty);
    healthy.dispose();
  });

  test('addCountForSession 幂等:同 sessionId 重複呼叫只累計一次', () async {
    final repo = DailyRepository();
    const ymd = '20260707';

    await repo.addCountForSession(ymd, 'u', 'n', 5, 'sess-1');
    await repo.addCountForSession(ymd, 'u', 'n', 5, 'sess-1'); // 重複
    await repo.addCountForSession(ymd, 'u', 'n', 2, 'sess-2'); // 新 session

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

    // 進背景 → 草稿非同步寫入,輪詢等它落盤
    c.didChangeAppLifecycleState(AppLifecycleState.paused);
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while ((await PendingCommitStore().list()).isEmpty) {
      if (DateTime.now().isAfter(deadline)) fail('draft not written in time');
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    final draft = (await PendingCommitStore().list()).single;
    expect(draft.snapshot.sessionId, sessionId);
    expect(draft.snapshot.amitabhaCount, 2);
    expect(c.sessionCount, 2); // 草稿不影響進行中的 session
    c.dispose();

    // 模擬 App 被殺後重啟:新 controller 重放草稿
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
    source.emit('阿彌陀佛'); // 1

    // 進背景寫草稿(1 聲)
    c.didChangeAppLifecycleState(AppLifecycleState.paused);
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while ((await PendingCommitStore().list()).isEmpty) {
      if (DateTime.now().isAfter(deadline)) fail('draft not written in time');
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }

    // 回前景續錄 → 再念 2 聲 → 正常儲存
    await c.start();
    source.emit('阿彌陀佛阿彌陀佛'); // 共 3
    await c.save();

    // daily 應是最終的 3(不是草稿 1 + 最終 3)
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

    // 提交是非同步的:輪詢 dataVersion(資料成功落盤才會 +1),避免固定延遲的 flaky
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
