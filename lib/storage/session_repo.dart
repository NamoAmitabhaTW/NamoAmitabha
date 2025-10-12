//amitabha/lib/storage/session_repo.dart
import 'atomic_io.dart';
import 'app_paths.dart';
import 'models.dart';
import 'single_writer.dart';

class SessionRepository {
  Future<void> upsertSnapshot(SessionSnapshot s) async {
    final file = await AppPaths.sessionSnapshot(s.sessionId);
    await singleWriter.run(() => atomicWriteJson(file, s.toJson()));
  }

  Future<SessionSnapshot?> readSnapshot(String sessionId) async {
    final file = await AppPaths.sessionSnapshot(sessionId);
    if (!await file.exists()) return null;
    final j = await readJsonOrEmpty(file);
    if (j.isEmpty) return null;
    return SessionSnapshot.fromJson(j);
  }
}