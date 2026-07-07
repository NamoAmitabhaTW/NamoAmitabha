//amitabha/lib/storage/daily_repo.dart
import 'atomic_io.dart';
import 'app_paths.dart';
import 'models.dart';
import 'single_writer.dart';

class DailyRepository {
  Future<void> addCount(String yyyymmdd, String userId, String userName, int delta) async {
    await _add(yyyymmdd, userId, userName, delta, sessionId: null);
  }

  /// 以 sessionId 幂等的加總:同一個 sessionId 只會累計一次,
  /// journal 重放時即使重複執行也不會重複計數。
  Future<void> addCountForSession(
    String yyyymmdd,
    String userId,
    String userName,
    int delta,
    String sessionId,
  ) async {
    await _add(yyyymmdd, userId, userName, delta, sessionId: sessionId);
  }

  Future<void> _add(
    String yyyymmdd,
    String userId,
    String userName,
    int delta, {
    required String? sessionId,
  }) async {
    final file = await AppPaths.daily(yyyymmdd);
    await singleWriter.run(() async {
      final j = await readJsonOrEmpty(file);
      if (j.isEmpty) {
        final d = DailySummary(
          yyyymmdd: yyyymmdd,
          userId: userId,
          userName: userName,
          amitabhaCount: delta,
          sessionIds: sessionId == null ? const [] : [sessionId],
        );
        await atomicWriteJson(file, d.toJson());
      } else {
        final d = DailySummary.fromJson(j);
        if (sessionId != null && d.sessionIds.contains(sessionId)) {
          return; // 這個 session 已累計過 → 幂等跳過
        }
        final updated = DailySummary(
          yyyymmdd: d.yyyymmdd,
          userId: d.userId,
          userName: d.userName,
          amitabhaCount: d.amitabhaCount + delta,
          sessionIds: sessionId == null
              ? d.sessionIds
              : [...d.sessionIds, sessionId],
        );
        await atomicWriteJson(file, updated.toJson());
      }
    });
  }
}
