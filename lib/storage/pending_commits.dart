// lib/storage/pending_commits.dart
// 提交 journal:session 結果先寫到 data/pending/,成功寫入
// session/daily 檔後才移除。App 中途被殺或寫入失敗都不會丟計數。
import 'dart:io';

import 'app_paths.dart';
import 'atomic_io.dart';
import 'models.dart';
import 'single_writer.dart';

class PendingCommit {
  final SessionSnapshot snapshot;

  /// 提交當下的本地日期(yyyyMMdd),重放時沿用,不會因跨日跑到隔天。
  final String ymd;

  PendingCommit({required this.snapshot, required this.ymd});

  Map<String, dynamic> toJson() => {
    'schemaVersion': 1,
    'ymd': ymd,
    'snapshot': snapshot.toJson(),
  };

  static PendingCommit fromJson(Map<String, dynamic> j) => PendingCommit(
    snapshot: SessionSnapshot.fromJson(j['snapshot'] as Map<String, dynamic>),
    ymd: j['ymd'] as String,
  );
}

class PendingCommitStore {
  Future<void> add(PendingCommit commit) async {
    final file = await AppPaths.pendingCommit(commit.snapshot.sessionId);
    await singleWriter.run(() => atomicWriteJson(file, commit.toJson()));
  }

  Future<void> remove(String sessionId) async {
    final file = await AppPaths.pendingCommit(sessionId);
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  /// 依 sessionId 順序(≈時間序)回傳所有待重放的提交;壞檔直接略過。
  Future<List<PendingCommit>> list() async {
    final dir = await AppPaths.pendingDir();
    if (!await dir.exists()) return const [];

    final files =
        await dir
            .list()
            .where((e) => e is File && e.path.endsWith('.json'))
            .cast<File>()
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));

    final result = <PendingCommit>[];
    for (final f in files) {
      final j = await readJsonOrEmpty(f);
      if (j.isEmpty) continue;
      try {
        result.add(PendingCommit.fromJson(j));
      } catch (_) {
        // 壞檔忽略,不讓一筆壞資料卡死整個重放
      }
    }
    return result;
  }
}
