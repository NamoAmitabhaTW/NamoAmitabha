// lib/features/asr/data/file_daily_repository.dart
import 'dart:io';
import 'package:amitabha/core/infrastructure/atomic_io.dart';
import 'package:amitabha/core/infrastructure/single_writer.dart';
import 'package:amitabha/features/asr/data/chanting_paths.dart';
import 'package:amitabha/features/asr/domain/chanting_repositories.dart';
import 'package:amitabha/features/asr/domain/daily_summary.dart';

class FileDailyRepository implements DailyRepository {
  const FileDailyRepository();

  @override
  Future<void> addCount(String yyyymmdd, int delta) =>
      _add(yyyymmdd, delta, sessionId: null);

  @override
  Future<void> addCountForSession(
    String yyyymmdd,
    int delta,
    String sessionId,
  ) => _add(yyyymmdd, delta, sessionId: sessionId);

  @override
  Future<List<DailySummary>> readAll() async {
    final dir = await ChantingPaths.dailyDir();
    if (!await dir.exists()) return const [];

    final files = await dir
        .list()
        .where((e) => e is File && e.path.endsWith('.json'))
        .cast<File>()
        .toList();

    final result = <DailySummary>[];
    for (final f in files) {
      final j = await readJsonOrEmpty(f);
      if (j.isEmpty) continue;
      try {
        result.add(DailySummary.fromJson(j));
      } on Object {
        continue;
      }
    }
    result.sort((a, b) => b.yyyymmdd.compareTo(a.yyyymmdd));
    return result;
  }

  Future<void> _add(
    String yyyymmdd,
    int delta, {
    required String? sessionId,
  }) async {
    final file = await ChantingPaths.daily(yyyymmdd);
    await singleWriter.run(() async {
      final j = await readJsonOrEmpty(file);
      if (j.isEmpty) {
        final d = DailySummary(
          yyyymmdd: yyyymmdd,
          amitabhaCount: delta,
          sessionIds: sessionId == null ? const [] : [sessionId],
        );
        await atomicWriteJson(file, d.toJson());
        return;
      }

      final d = DailySummary.fromJson(j);

      if (sessionId != null && d.sessionIds.contains(sessionId)) return;

      final updated = DailySummary(
        yyyymmdd: d.yyyymmdd,
        amitabhaCount: d.amitabhaCount + delta,
        sessionIds: sessionId == null
            ? d.sessionIds
            : [...d.sessionIds, sessionId],
      );
      await atomicWriteJson(file, updated.toJson());
    });
  }
}
