// lib/features/app_update/data/app_update_prefs.dart
import 'package:amitabha/core/infrastructure/json_prefs_file.dart';
import 'package:amitabha/features/app_update/domain/app_update_ports.dart';

class FileAppUpdatePreferences implements AppUpdatePreferences {
  const FileAppUpdatePreferences();

  static final _file = JsonPrefsFile('app_update_dismissed');

  @override
  Future<({String? version, DateTime? at})> load() async {
    final j = await _file.read();
    if (j == null) return (version: null, at: null);
    final version = j['version'];
    final at = j['at'];
    return (
      version: version is String ? version : null,
      at: at is num ? DateTime.fromMillisecondsSinceEpoch(at.toInt()) : null,
    );
  }

  @override
  Future<void> saveDismissed(String version) => _file.write({
    'version': version,
    'at': DateTime.now().millisecondsSinceEpoch,
  });
}
