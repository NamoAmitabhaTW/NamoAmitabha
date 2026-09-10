// lib/features/asr/data/file_session_repository.dart
import 'package:amitabha/core/infrastructure/atomic_io.dart';
import 'package:amitabha/core/infrastructure/single_writer.dart';
import 'package:amitabha/features/asr/data/chanting_paths.dart';
import 'package:amitabha/features/asr/domain/chanting_repositories.dart';
import 'package:amitabha/features/asr/domain/session_snapshot.dart';

class FileSessionRepository implements SessionRepository {
  const FileSessionRepository();

  @override
  Future<void> upsertSnapshot(SessionSnapshot snapshot) async {
    final file = await ChantingPaths.sessionSnapshot(snapshot.sessionId);
    await singleWriter.run(() => atomicWriteJson(file, snapshot.toJson()));
  }

  @override
  Future<SessionSnapshot?> readSnapshot(String sessionId) async {
    final file = await ChantingPaths.sessionSnapshot(sessionId);
    if (!await file.exists()) return null;
    final j = await readJsonOrEmpty(file);
    if (j.isEmpty) return null;
    return SessionSnapshot.fromJson(j);
  }
}
