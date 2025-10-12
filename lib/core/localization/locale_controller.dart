// lib/core/localization/locale_controller.dart
import 'package:flutter/material.dart';

class LocaleController extends ChangeNotifier {
  /// null = 跟隨系統（預設）
  Locale? _locale;
  Locale? get locale => _locale;

  /// 切到英文
  void useEnglish() {
    _locale = const Locale('en');
    notifyListeners();
  }

  /// 切到繁體（和 gen-l10n 產生的 supportedLocales 一致）
  void useTraditionalChinese() {
    // 如果你的 AppLocalizations.supportedLocales 裡是用 scriptCode=Hant：
    _locale = const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'TW');
    // 若你採用地區碼版本，可改：_locale = const Locale('zh', 'TW');
    notifyListeners();
  }

  /// 回到系統語系
  void useSystem() {
    _locale = null;
    notifyListeners();
  }
}
