//amitabha/lib/storage/daily_repo.dart
import 'atomic_io.dart';
import 'app_paths.dart';
import 'models.dart';
import 'single_writer.dart';

class DailyRepository {
  Future<void> addCount(String yyyymmdd, String userId, String userName, int delta) async {
    final file = await AppPaths.daily(yyyymmdd);
    await singleWriter.run(() async {
      final j = await readJsonOrEmpty(file);
      if (j.isEmpty) {
        final d = DailySummary(
          yyyymmdd: yyyymmdd,
          userId: userId,
          userName: userName,
          amitabhaCount: delta,
        );
        await atomicWriteJson(file, d.toJson());
      } else {
        final d = DailySummary.fromJson(j);
        final updated = DailySummary(
          yyyymmdd: d.yyyymmdd,
          userId: d.userId,
          userName: d.userName,
          amitabhaCount: d.amitabhaCount + delta,
        );
        await atomicWriteJson(file, updated.toJson());
      }
    });
  }
}