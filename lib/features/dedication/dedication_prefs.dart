// amitabha/lib/features/dedication/dedication_prefs.dart
import 'package:amitabha/storage/json_prefs_file.dart';

/// 迴向偈的本機儲存：以語系代碼為 key 的覆寫內容 map。
/// 檔案格式：{ "overrides": { "zh": "...", "en": "..." } }
class DedicationPrefs {
  static final _file = JsonPrefsFile('dedication');

  static Future<Map<String, String>> loadOverrides() async {
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

    // 舊格式相容：早期以單一 { "text": "..." } 儲存，視為繁中的覆寫。
    final legacy = j['text'];
    if (legacy is String && legacy.trim().isNotEmpty) {
      return {'zh': legacy};
    }
    return {};
  }

  static Future<void> saveOverrides(Map<String, String> overrides) =>
      _file.write({'overrides': overrides});
}
