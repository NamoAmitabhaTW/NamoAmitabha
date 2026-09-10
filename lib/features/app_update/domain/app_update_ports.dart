// lib/features/app_update/domain/app_update_ports.dart
abstract class LatestVersionSource {
  Future<String?> fetchLatest();
}

abstract class AppUpdatePreferences {
  Future<({String? version, DateTime? at})> load();

  Future<void> saveDismissed(String version);
}
