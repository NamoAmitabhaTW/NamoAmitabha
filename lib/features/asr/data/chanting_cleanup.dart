// lib/features/asr/data/chanting_cleanup.dart

import 'dart:io';

import 'package:amitabha/core/infrastructure/json_prefs_file.dart';
import 'package:amitabha/features/asr/data/chanting_paths.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

const int _purgeVersion = 1;

final JsonPrefsFile _marker = JsonPrefsFile('storage_cleanup');

Future<void> purgeLegacyHitLogs() async {
  try {
    final done = (await _marker.read())?['purgeVersion'];
    if (done is int && done >= _purgeVersion) return;
  } on Object catch (_) {}

  final Directory dir;
  try {
    dir = await ChantingPaths.sessionsDir();
  } on Object {
    return;
  }

  var deleted = 0;
  var failed = 0;

  if (await dir.exists()) {
    await for (final entry in dir.list()) {
      if (entry is! File) continue;
      final name = p.basename(entry.path);
      if (!name.contains('-hits-') || !name.endsWith('.ndjson')) continue;

      try {
        await entry.delete();
        deleted++;
      } on Object {
        failed++;
      }
    }
  }

  if (kDebugMode && deleted > 0) {
    debugPrint('[cleanup] purged $deleted legacy hit log(s)');
  }

  if (failed > 0) return;

  try {
    await _marker.write({'purgeVersion': _purgeVersion});
  } on Object catch (_) {}
}
