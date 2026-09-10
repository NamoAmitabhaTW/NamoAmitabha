// lib/features/asr/domain/chanting_repositories.dart
import 'package:amitabha/features/asr/domain/daily_summary.dart';
import 'package:amitabha/features/asr/domain/pending_commit.dart';
import 'package:amitabha/features/asr/domain/session_snapshot.dart';

abstract class SessionRepository {
  Future<void> upsertSnapshot(SessionSnapshot snapshot);

  Future<SessionSnapshot?> readSnapshot(String sessionId);
}

abstract class DailyRepository {
  Future<void> addCount(String yyyymmdd, int delta);

  Future<void> addCountForSession(String yyyymmdd, int delta, String sessionId);

  Future<List<DailySummary>> readAll();
}

abstract class PendingCommitStore {
  Future<void> add(PendingCommit commit);

  Future<void> remove(String sessionId);

  Future<List<PendingCommit>> list();
}

abstract class HitLog {
  Future<void> initFromDisk();

  Future<void> appendMany(Iterable<DateTime> hitsUtc);
}

typedef HitLogFactory = HitLog Function(String sessionId);
