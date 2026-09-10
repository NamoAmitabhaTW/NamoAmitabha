// lib/features/app_update/data/app_update_prefs.dart
import 'package:amitabha/core/infrastructure/json_prefs_file.dart';

class AppUpdatePrefs {
  static final _file = JsonPrefsFile('app_update_dismissed');

  static Future<({String? version, DateTime? at})> load() async {
    final j = await _file.read();
    if (j == null) return (version: null, at: null);
    final version = j['version'];
    final at = j['at'];
    return (
      version: version is String ? version : null,
      at: at is num ? DateTime.fromMillisecondsSinceEpoch(at.toInt()) : null,
    );
  }

  static Future<void> saveDismissed(String version) => _file.write({
    'version': version,
    'at': DateTime.now().millisecondsSinceEpoch,
  });
}
