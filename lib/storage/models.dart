//amitabha/lib/storage/models.dart
class SessionSnapshot {
  final String sessionId;
  final String userId;
  final String userName;
  final DateTime startedAt;
  final DateTime lastAt;
  final int amitabhaCount;

  SessionSnapshot({
    required this.sessionId,
    required this.userId,
    required this.userName,
    required this.startedAt,
    required this.lastAt,
    required this.amitabhaCount,
  });

  Map<String, dynamic> toJson() => {
    'schemaVersion': 1,
    'sessionId': sessionId,
    'userId': userId,
    'userName': userName,
    'startedAt': startedAt.toUtc().toIso8601String(),
    'lastAt': lastAt.toUtc().toIso8601String(),
    'amitabhaCount': amitabhaCount,
  };

  static SessionSnapshot fromJson(Map<String, dynamic> j) => SessionSnapshot(
    sessionId: j['sessionId'],
    userId: j['userId'],
    userName: j['userName'],
    startedAt: DateTime.parse(j['startedAt']).toUtc(),
    lastAt: DateTime.parse(j['lastAt']).toUtc(),
    amitabhaCount: j['amitabhaCount'] ?? 0,
  );
}

class DailySummary {
  final String yyyymmdd;
  final String userId;
  final String userName;
  final int amitabhaCount;

  DailySummary({
    required this.yyyymmdd,
    required this.userId,
    required this.userName,
    required this.amitabhaCount,
  });

  Map<String, dynamic> toJson() => {
    'schemaVersion': 1,
    'date': yyyymmdd,
    'userId': userId,
    'userName': userName,
    'amitabhaCount': amitabhaCount,
  };

  static DailySummary fromJson(Map<String, dynamic> j) => DailySummary(
    yyyymmdd: j['date'],
    userId: j['userId'],
    userName: j['userName'],
    amitabhaCount: j['amitabhaCount'] ?? 0,
  );
}