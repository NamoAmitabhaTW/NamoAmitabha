// lib/core/localization/locale_controller.dart
import 'package:flutter/material.dart';
import 'locale_prefs.dart';

/// 一個可選語言的描述：持久化用的 code、要切換到的 Locale、選單顯示的自稱。
class AppLanguage {
  const AppLanguage(this.code, this.locale, this.endonym);

  /// 持久化字串（存進 LocalePrefs）
  final String code;

  /// 對應的 Flutter Locale
  final Locale locale;

  /// 選單顯示名稱（語言自稱，不隨 UI 語系翻譯）
  final String endonym;
}

class LocaleController extends ChangeNotifier {
  Locale? _locale; // null = 跟隨系統
  Locale? get locale => _locale;

  /// 支援的語言清單（順序即選單顯示順序）。
  /// 新增語言只要在這裡加一行 + 在 _toLocale 補 case 即可。
  static const List<AppLanguage> supportedLanguages = [
    AppLanguage('zh-TW', Locale('zh', 'TW'), '繁體中文'),
    AppLanguage('en', Locale('en'), 'English'),
    AppLanguage('ja', Locale('ja'), '日本語'),
    AppLanguage('ko', Locale('ko'), '한국어'),
    AppLanguage('vi', Locale('vi'), 'Tiếng Việt'),
    AppLanguage('de', Locale('de'), 'Deutsch'),
    AppLanguage('fr', Locale('fr'), 'Français'),
  ];

  LocaleController() {
    // 讓第一禎先畫，再非阻塞地做復原。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      restore();
    });
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

  /// 通用設定語言。傳入 supportedLanguages 裡的 code。
  Future<void> setLanguage(String code) async => _setAndPersist(code);

  Future<void> useSystem() async {
    _locale = null; // 交給系統
    notifyListeners();
    await LocalePrefs.save('system');
  }

  // 相容舊呼叫端（若他處仍引用）。新程式碼請改用 setLanguage()。
  Future<void> useTraditionalChinese() async => setLanguage('zh-TW');
  Future<void> useEnglish() async => setLanguage('en');

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
      case 'ja':
        return const Locale('ja');
      case 'ko':
        return const Locale('ko');
      case 'vi':
        return const Locale('vi');
      case 'de':
        return const Locale('de');
      case 'fr':
        return const Locale('fr');
      default:
        return null; // ← 不認得就跟系統
    }
  }
}