// lib/features/records/domain/chanting_statistics.dart
import 'package:amitabha/features/asr/asr.dart';

class ChantingStatistics {
  const ChantingStatistics({
    required this.days,
    required this.total,
    required this.practiceDays,
  });

  final List<DailySummary> days;

  final int total;

  final int practiceDays;

  static const ChantingStatistics empty = ChantingStatistics(
    days: [],
    total: 0,
    practiceDays: 0,
  );

  factory ChantingStatistics.from(List<DailySummary> days) {
    final sorted = [...days]..sort((a, b) => b.yyyymmdd.compareTo(a.yyyymmdd));
    return ChantingStatistics(
      days: sorted,
      total: sorted.fold<int>(0, (sum, d) => sum + d.amitabhaCount),
      practiceDays: sorted.where((d) => d.amitabhaCount > 0).length,
    );
  }

  bool get isEmpty => days.isEmpty;
}
