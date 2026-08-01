// amitabha/lib/features/dedication/dedication_controller.dart
import 'package:amitabha/features/dedication/dedication_gatha.dart';
import 'package:amitabha/features/dedication/dedication_prefs.dart';
import 'package:flutter/foundation.dart';

/// 保存各語系的迴向偈內容，供念佛頁的迴向動畫與設定頁的編輯器共用。
/// 每個語系各自獨立：未編輯時使用該語系的預設偈，編輯後只覆寫該語系。
class DedicationController extends ChangeNotifier {
  final Map<String, String> _overrides = {};

  bool _loaded = false;
  bool get loaded => _loaded;

  Future<void> load() async {
    try {
      final m = await DedicationPrefs.loadOverrides();
      _overrides
        ..clear()
        ..addAll(m);
    } catch (e) {
      debugPrint('[dedication] load failed: $e');
    }
    _loaded = true;
    notifyListeners();
  }

  /// 取得指定語系目前要顯示的迴向偈（覆寫優先，否則用預設）。
  String textFor(String languageCode) {
    final ov = _overrides[languageCode];
    if (ov != null && ov.trim().isNotEmpty) return ov;
    return defaultDedicationGatha(languageCode);
  }

  /// 儲存指定語系的編輯內容。
  /// 若清空或與預設相同，則移除覆寫（回到預設，並隨未來預設更新）。
  Future<void> saveFor(String languageCode, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || trimmed == defaultDedicationGatha(languageCode).trim()) {
      if (!_overrides.containsKey(languageCode)) return;
      _overrides.remove(languageCode);
    } else {
      if (_overrides[languageCode] == trimmed) return;
      _overrides[languageCode] = trimmed;
    }
    notifyListeners();
    try {
      await DedicationPrefs.saveOverrides(_overrides);
    } catch (e) {
      debugPrint('[dedication] save failed: $e');
    }
  }
}
