import 'dart:convert';
import 'dart:io';
import 'app_paths.dart';
import 'package:amitabha/utils.dart';

class HitLogger {
  final String sessionId;
  int _part = 1;
  int _lines = 0;
  final int rotateEvery; 

  HitLogger(this.sessionId, {this.rotateEvery = 5000});

  Future<void> appendMany(Iterable<DateTime> hitsUtc) async {
    var file = await AppPaths.sessionHits(sessionId, part: _part);
    var sink = file.openWrite(mode: FileMode.append);
    final encoder = JsonEncoder();

    try {
      for (final t in hitsUtc) {
        sink.writeln(encoder.convert({'t': t.toIso8601String()}));
        _lines++;
        if (_lines >= rotateEvery) {
          await sink.flush();
          await sink.close();
          _part++; _lines = 0;
          file = await AppPaths.sessionHits(sessionId, part: _part);
          sink = file.openWrite(mode: FileMode.append);
        }
      }
    } finally {
      await sink.flush();
      await sink.close();
    }
  }

  Future<void> initFromDisk() async {
    var part = 1;
    while (await AppPaths.sessionHits(sessionId, part: part + 1)
        .then((f) => f.exists())) {
      part++;
    }
    _part = part;

    final file = await AppPaths.sessionHits(sessionId, part: _part);
    if (await file.exists()) {
      final lines = await file.openRead()
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .length;
      _lines = lines;
    } else {
      _lines = 0;
    }
  }
  static String todayYmdLocal() => nowYmdLocal();
}
