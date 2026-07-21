// lib/storage/pending_commits.dart

import 'dart:io';

import 'app_paths.dart';
import 'atomic_io.dart';
import 'models.dart';
import 'single_writer.dart';

class PendingCommit {
  final SessionSnapshot snapshot;

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
      
      }
    }
    return result;
  }
}
