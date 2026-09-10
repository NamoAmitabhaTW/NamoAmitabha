// lib/features/asr/domain/session_snapshot.dart
class SessionSnapshot {
  const SessionSnapshot({
    required this.sessionId,
    required this.startedAt,
    required this.lastAt,
    required this.amitabhaCount,
  });

  final String sessionId;
  final DateTime startedAt;
  final DateTime lastAt;
  final int amitabhaCount;

  Map<String, dynamic> toJson() => {
    'schemaVersion': 2,
    'sessionId': sessionId,
    'startedAt': startedAt.toUtc().toIso8601String(),
    'lastAt': lastAt.toUtc().toIso8601String(),
    'amitabhaCount': amitabhaCount,
  };

  static SessionSnapshot fromJson(Map<String, dynamic> j) => SessionSnapshot(
    sessionId: j['sessionId'] as String,
    startedAt: DateTime.parse(j['startedAt'] as String).toUtc(),
    lastAt: DateTime.parse(j['lastAt'] as String).toUtc(),
    amitabhaCount: (j['amitabhaCount'] as int?) ?? 0,
  );
}
