// lib/features/asr/data/file_pending_commit_store.dart
import 'dart:io';
import 'package:amitabha/core/infrastructure/atomic_io.dart';
import 'package:amitabha/core/infrastructure/single_writer.dart';
import 'package:amitabha/features/asr/data/chanting_paths.dart';
import 'package:amitabha/features/asr/domain/chanting_repositories.dart';
import 'package:amitabha/features/asr/domain/pending_commit.dart';

class FilePendingCommitStore implements PendingCommitStore {
  const FilePendingCommitStore();

  @override
  Future<void> add(PendingCommit commit) async {
    final file = await ChantingPaths.pendingCommit(commit.snapshot.sessionId);
    await singleWriter.run(() => atomicWriteJson(file, commit.toJson()));
  }

  @override
  Future<void> remove(String sessionId) async {
    final file = await ChantingPaths.pendingCommit(sessionId);
    try {
      if (await file.exists()) await file.delete();
    } on Object catch (_) {}
  }

  @override
  Future<List<PendingCommit>> list() async {
    final dir = await ChantingPaths.pendingDir();
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
      } on Object {
        continue;
      }
    }
    return result;
  }
}
