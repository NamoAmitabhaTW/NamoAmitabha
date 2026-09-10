// lib/features/asr/data/file_hit_log.dart
import 'dart:convert';
import 'dart:io';
import 'package:amitabha/features/asr/data/chanting_paths.dart';
import 'package:amitabha/features/asr/domain/chanting_repositories.dart';

class FileHitLog implements HitLog {
  FileHitLog(this.sessionId, {this.rotateEvery = 5000});

  final String sessionId;

  final int rotateEvery;

  int _part = 1;
  int _lines = 0;

  @override
  Future<void> initFromDisk() async {
    var part = 1;
    while (await ChantingPaths.sessionHits(
      sessionId,
      part: part + 1,
    ).then((f) => f.exists())) {
      part++;
    }
    _part = part;

    final file = await ChantingPaths.sessionHits(sessionId, part: _part);
    _lines = await file.exists()
        ? await file
              .openRead()
              .transform(utf8.decoder)
              .transform(const LineSplitter())
              .length
        : 0;
  }

  @override
  Future<void> appendMany(Iterable<DateTime> hitsUtc) async {
    var file = await ChantingPaths.sessionHits(sessionId, part: _part);
    var sink = file.openWrite(mode: FileMode.append);
    const encoder = JsonEncoder();

    try {
      for (final t in hitsUtc) {
        sink.writeln(encoder.convert({'t': t.toIso8601String()}));
        _lines++;
        if (_lines >= rotateEvery) {
          await sink.flush();
          await sink.close();
          _part++;
          _lines = 0;
          file = await ChantingPaths.sessionHits(sessionId, part: _part);
          sink = file.openWrite(mode: FileMode.append);
        }
      }
    } finally {
      await sink.flush();
      await sink.close();
    }
  }
}
