// lib/core/localization/locale_controller.dart
import 'package:flutter/material.dart';
import 'locale_prefs.dart';

// lib/core/localization/locale_controller.dart
class LocaleController extends ChangeNotifier {
  Locale? _locale; // null = 跟隨系統
  Locale? get locale => _locale;

  LocaleController() {
    restore();
  }

  Future<void> restore() async {
    final code =
        await LocalePrefs.load(); // 可能為 null / 'system' / 'en' / 'zh-TW' / 舊格式
    if (code == null || code == 'system') {
      _locale = null; // 跟隨系統
      notifyListeners();
      return;
    }
    _locale = _toLocale(code);
    notifyListeners();
  }

  Future<void> useTraditionalChinese() async => _setAndPersist('zh-TW');
  Future<void> useEnglish() async => _setAndPersist('en');
  Future<void> useSystem() async {
    _locale = null; // 交給系統
    notifyListeners();
    await LocalePrefs.save('system');
  }

  Future<void> _setAndPersist(String code) async {
    final next = _toLocale(code);
    final changed = _locale != next;
    _locale = next;
    if (changed) notifyListeners();
    await LocalePrefs.save(code);
  }

  Locale? _toLocale(String code) {
    switch (code) {
      case 'zh-TW':
      case 'zh_TW':
      case 'zh-Hant':
      case 'zh_Hant':
      case 'zh-Hant-TW':
      case 'zh_Hant_TW':
        return const Locale('zh', 'TW');
      case 'en':
        return const Locale('en');
      default:
        return null; // ← 不認得就跟系統
    }
  }
}
