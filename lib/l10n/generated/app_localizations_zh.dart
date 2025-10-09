// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get amitabha => 'Amitabha';

  @override
  String get start => 'Start';

  @override
  String get pause => 'Pause';

  @override
  String get save => 'Save';

  @override
  String get logIn => 'Log in';

  @override
  String get logOut => 'Log Out';

  @override
  String get total => 'Total';

  @override
  String totalCount(int count) {
    return 'Total count: $count';
  }
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizationsZh {
  AppLocalizationsZhHant() : super('zh_Hant');
}

/// The translations for Chinese, as used in Taiwan, using the Han script (`zh_Hant_TW`).
class AppLocalizationsZhHantTw extends AppLocalizationsZh {
  AppLocalizationsZhHantTw() : super('zh_Hant_TW');

  @override
  String get amitabha => '阿彌陀佛';

  @override
  String get start => '開始';

  @override
  String get pause => '暫停';

  @override
  String get save => '儲存';

  @override
  String get logIn => '登入';

  @override
  String get logOut => '登出';

  @override
  String get total => '累計';

  @override
  String totalCount(int count) {
    return '累計次數：$count';
  }
}
