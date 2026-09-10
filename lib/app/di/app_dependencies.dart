// lib/app/di/app_dependencies.dart
import 'package:amitabha/features/asr/asr.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class AppDependencies {
  const AppDependencies._();

  static AsrSessionController createAsrSessionController() =>
      AsrSessionController(
        sessionRepo: const FileSessionRepository(),
        dailyRepo: const FileDailyRepository(),
        pendingStore: const FilePendingCommitStore(),
        hitLogFactory: FileHitLog.new,
        setWakelock: setWakelock,
        sourceFactory: () => SherpaMicSource(),
      );

  static Future<void> setWakelock(bool keepAwake) =>
      keepAwake ? WakelockPlus.enable() : WakelockPlus.disable();
}
