// lib/app/di/app_dependencies.dart
import 'package:amitabha/features/announcements/announcements.dart';
import 'package:amitabha/features/app_update/app_update.dart';
import 'package:amitabha/features/asr/asr.dart';
import 'package:amitabha/features/background/background.dart';
import 'package:amitabha/features/dedication/dedication.dart';
import 'package:amitabha/features/records/records.dart';
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

  static RecordsController createRecordsController() =>
      const RecordsController(FileDailyRepository());

  static BackgroundController createBackgroundController() =>
      BackgroundController(
        HttpBackgroundRepository(),
        const FileBackgroundPreferences(),
      );

  static DedicationController createDedicationController() =>
      DedicationController(const FileDedicationPreferences());

  static AnnouncementController createAnnouncementController() =>
      AnnouncementController(
        const GithubAnnouncementRepository(),
        const FileAnnouncementPreferences(),
      );

  static AppUpdateController createAppUpdateController() => AppUpdateController(
    const HttpLatestVersionSource(),
    const FileAppUpdatePreferences(),
  );

  static Future<void> setWakelock(bool keepAwake) =>
      keepAwake ? WakelockPlus.enable() : WakelockPlus.disable();
}
