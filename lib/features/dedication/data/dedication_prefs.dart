// lib/features/dedication/data/dedication_prefs.dart
import 'package:amitabha/core/infrastructure/json_prefs_file.dart';
import 'package:amitabha/features/dedication/domain/dedication_preferences.dart';

class FileDedicationPreferences implements DedicationPreferences {
  const FileDedicationPreferences();

  static final _file = JsonPrefsFile('dedication');

  @override
  Future<Map<String, String>> loadOverrides() async {
    final j = await _file.read();
    if (j == null) return {};

    final ov = j['overrides'];
    if (ov is Map) {
      final result = <String, String>{};
      ov.forEach((k, v) {
        if (v is String) result[k.toString()] = v;
      });
      return result;
    }

    final legacy = j['text'];
    if (legacy is String && legacy.trim().isNotEmpty) {
      return {'zh': legacy};
    }
    return {};
  }

  @override
  Future<void> saveOverrides(Map<String, String> overrides) =>
      _file.write({'overrides': overrides});
}
