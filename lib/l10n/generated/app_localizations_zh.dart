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
  String get chant => 'Chant';

  @override
  String get records => 'Records';

  @override
  String get settings => 'Settings';

  @override
  String get start => 'Start';

  @override
  String get pause => 'Pause';

  @override
  String get save => 'Save';

  @override
  String get total => 'Total';

  @override
  String get days => 'Days';

  @override
  String get times => 'times';

  @override
  String get noRecords => 'No records yet';

  @override
  String get logIn => 'Log in';

  @override
  String get logOut => 'Log out';

  @override
  String get enableCloudSync => 'Enable Cloud Sync';

  @override
  String get account => 'Account';

  @override
  String get accountStatus => 'Sign-in status';

  @override
  String get statusSignedIn => 'Signed in';

  @override
  String get statusSignedOut => 'Not signed in';

  @override
  String get language => 'Language';

  @override
  String currentLanguage(String lang) {
    return 'Current language: $lang';
  }

  @override
  String get langZhHant => 'Chinese (Traditional)';

  @override
  String get langEn => 'English';

  @override
  String get feedback => 'Feedback';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get confirm => 'Confirm';

  @override
  String get cancel => 'Cancel';

  @override
  String get done => 'Done';

  @override
  String get confirmDeleteAccount =>
      'Are you sure you want to delete your account and data? This action cannot be undone.';
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
  String get chant => '念佛';

  @override
  String get records => '記錄';

  @override
  String get settings => '設定';

  @override
  String get start => '開始';

  @override
  String get pause => '暫停';

  @override
  String get save => '儲存';

  @override
  String get total => '總累計';

  @override
  String get days => '天';

  @override
  String get times => '次';

  @override
  String get noRecords => '目前沒有記錄';

  @override
  String get logIn => '登入';

  @override
  String get logOut => '登出';

  @override
  String get enableCloudSync => '開啟同步雲端';

  @override
  String get account => '帳號';

  @override
  String get accountStatus => '登入狀態';

  @override
  String get statusSignedIn => '已登入';

  @override
  String get statusSignedOut => '尚未登入';

  @override
  String get language => '語言';

  @override
  String currentLanguage(String lang) {
    return '目前語言：$lang';
  }

  @override
  String get langZhHant => '繁體中文';

  @override
  String get langEn => 'English';

  @override
  String get feedback => '意見回饋';

  @override
  String get deleteAccount => '刪除帳號';

  @override
  String get confirm => '確認';

  @override
  String get cancel => '取消';

  @override
  String get done => '已完成';

  @override
  String get confirmDeleteAccount => '確定要刪除帳號與資料？此動作無法復原。';
}
