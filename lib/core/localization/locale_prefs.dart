//語系持久化
// lib/core/localization/locale_prefs.dart
import 'package:amitabha/storage/json_prefs_file.dart';

class LocalePrefs {
  static final _file = JsonPrefsFile('locale');

  static Future<void> save(String localeCode) =>
      _file.write({'locale': localeCode});

  static Future<String?> load() async =>
      (await _file.read())?['locale'] as String?;
}
