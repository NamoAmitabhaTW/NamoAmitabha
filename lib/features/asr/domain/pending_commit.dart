// lib/features/asr/domain/pending_commit.dart
import 'package:amitabha/features/asr/domain/session_snapshot.dart';

class PendingCommit {
  const PendingCommit({required this.snapshot, required this.ymd});

  final SessionSnapshot snapshot;

  final String ymd;

  Map<String, dynamic> toJson() => {
    'schemaVersion': 2,
    'ymd': ymd,
    'snapshot': snapshot.toJson(),
  };

  static PendingCommit fromJson(Map<String, dynamic> j) => PendingCommit(
    snapshot: SessionSnapshot.fromJson(j['snapshot'] as Map<String, dynamic>),
    ymd: j['ymd'] as String,
  );
}
