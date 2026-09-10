// lib/features/asr/domain/daily_summary.dart
class DailySummary {
  const DailySummary({
    required this.yyyymmdd,
    required this.amitabhaCount,
    this.sessionIds = const [],
  });

  final String yyyymmdd;
  final int amitabhaCount;
  final List<String> sessionIds;

  Map<String, dynamic> toJson() => {
    'schemaVersion': 2,
    'date': yyyymmdd,
    'amitabhaCount': amitabhaCount,
    'sessionIds': sessionIds,
  };

  static DailySummary fromJson(Map<String, dynamic> j) => DailySummary(
    yyyymmdd: j['date'] as String,
    amitabhaCount: (j['amitabhaCount'] as int?) ?? 0,
    sessionIds: (j['sessionIds'] as List?)?.cast<String>() ?? const [],
  );
}
