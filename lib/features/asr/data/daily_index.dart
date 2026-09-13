// lib/features/asr/data/daily_index.dart

import 'dart:convert';

import 'package:amitabha/core/infrastructure/atomic_io.dart';
import 'package:amitabha/features/asr/data/chanting_paths.dart';
import 'package:amitabha/features/asr/domain/daily_summary.dart';

class DailyIndex {
  const DailyIndex._();

  static const int schemaVersion = 1;

  static Future<List<DailySummary>?> read() async {
    final file = await ChantingPaths.dailyIndex();
    if (!await file.exists()) return null;

    try {
      final text = await file.readAsString();
      if (text.isEmpty) return null;

      final decoded = jsonDecode(text);
      if (decoded is! Map<String, dynamic>) return null;
      if (decoded['schemaVersion'] != schemaVersion) return null;

      final days = decoded['days'];
      if (days is! List) return null;

      return days
          .map((e) => DailySummary.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    } on Object {
      return null;
    }
  }

  static Future<void> write(List<DailySummary> days) async {
    final file = await ChantingPaths.dailyIndex();
    await atomicWriteJson(file, {
      'schemaVersion': schemaVersion,
      'days': days.map((d) => d.toJson()).toList(growable: false),
    }, pretty: false);
  }
}
