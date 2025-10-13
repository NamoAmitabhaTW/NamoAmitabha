// lib/core/localization/locale_controller.dart
import 'package:flutter/material.dart';
import 'locale_prefs.dart';

/// 語系控制器：
/// - null 代表「跟隨系統」
/// - 僅提供「繁中 / 英文」兩個 UI 選項
/// - 內部仍保留 useSystem() 以便未來需要時切回跟隨系統
class LocaleController extends ChangeNotifier {
  Locale? _locale; // null = 跟隨系統
  Locale? get locale => _locale;

  LocaleController() {
    restore(); // 啟動時嘗試讀取偏好；沒有就維持 null
  }

  /// 啟動還原：若沒有偏好（或讀不到），維持 null = 跟隨系統
  Future<void> restore() async {
    final code =
        await LocalePrefs.load(); // 可能是：'en' / 'zh-Hant' / 'zh-TW' / 'system' / null
    if (code == null || code == 'system') {
      _locale = null; // 跟隨系統
      notifyListeners();
      return;
    }
    _locale = _toLocale(code); // 還原為使用者偏好
    notifyListeners();
  }

  /// UI：切繁體（建議用 zh-Hant；若你專案採 zh-TW 也可改）
  Future<void> useTraditionalChinese() async {
    await _setAndPersist('zh-TW');
  }

  /// UI：切英文
  Future<void> useEnglish() async {
    await _setAndPersist('en');
  }

  /// 內部保留：切回跟隨系統（UI 不露出）
  Future<void> useSystem() async {
    _locale = null; // MaterialApp(locale: null) → 交給 Flutter 依系統匹配
    notifyListeners();
    await LocalePrefs.save('system');
  }

  /// 統一入口：更新 _locale 並持久化（避免外部先改 _locale 造成「相等早退、沒有存檔」）
  Future<void> _setAndPersist(String code) async {
    final next = _toLocale(code);
    final changed = _locale != next;
    _locale = next;
    if (changed) notifyListeners();
    await LocalePrefs.save(code);
  }

  Locale _toLocale(String code) {
    switch (code) {
      case 'zh-TW':
      case 'zh_TW': // 允許底線寫法
        return const Locale('zh', 'TW');

      // 相容舊值：之前可能存過 zh-Hant / zh-Hant-TW / zh_Hant_TW
      case 'zh-Hant':
      case 'zh_Hant':
      case 'zh-Hant-TW':
      case 'zh_Hant_TW':
        return const Locale('zh', 'TW');

      case 'en':
        return const Locale('en');

      default:
        // 看你需求，也可以回傳 null 跟隨系統
        return const Locale('en');
    }
  }
}
