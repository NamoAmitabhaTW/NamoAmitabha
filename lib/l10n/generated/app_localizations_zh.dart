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

  @override
  String get pleaseWait => 'Please wait';

  @override
  String get downloading => 'Downloading';

  @override
  String get unzipping => 'Unzipping';

  @override
  String get completed => 'Completed';

  @override
  String get preparing => 'Preparing';

  @override
  String get preparingPleaseWait => 'Preparing, please wait…';

  @override
  String doNotOperateDuring(String phase) {
    return 'Please stay on this screen during \"$phase\". Do not switch apps or turn off the screen.';
  }

  @override
  String get ok => 'OK';

  @override
  String get downloadRequiredTitle => 'Download Required';

  @override
  String downloadRequiredBody(String modelName) {
    return 'The speech recognition model ($modelName) is not available locally. Do you want to download it?';
  }

  @override
  String get download => 'Download';

  @override
  String get downloadFailedTitle => 'Download Failed';

  @override
  String downloadFailedBody(String error) {
    return 'Failed to download the model: $error';
  }

  @override
  String get successTitle => 'Success';

  @override
  String get successBody => 'The model has been installed successfully.';

  @override
  String get unzipFailedTitle => 'Unzip failed';

  @override
  String get unzipFailedLowSpaceBody =>
      'Likely due to low storage space. Please free up some space and try unzipping again.';

  @override
  String get close => 'Close';

  @override
  String get retryUnzip => 'Retry unzip';

  @override
  String get downloadFailedShort =>
      'Model download failed. Please try again later.';

  @override
  String get retry => 'Retry';

  @override
  String get feedbackOpenMailAppFailed => 'Could not open mail app';

  @override
  String get appName => 'Amitabha Buddha';

  @override
  String feedbackEmailSubject(String app) {
    return '[$app] Feedback';
  }

  @override
  String get feedbackEmailBody =>
      'Issue/Suggestion:\n\n(You may attach a screenshot)';

  @override
  String get micPermissionTitle => 'Microphone Permission Required';

  @override
  String get micPermissionRationale =>
      'To count chants, please enable Microphone in System Settings > Amitabha.';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get microphonePermissionDenied => 'Microphone permission not granted.';

  @override
  String get bgScreenTitle => 'Chanting Background';

  @override
  String get bgUse => 'Use';

  @override
  String get bgUpdate => 'Update';

  @override
  String get bgDelete => 'Delete';

  @override
  String get bgInUse => 'In use';

  @override
  String get bgDefault => 'Default';

  @override
  String get bgTypeVideo => 'Video';

  @override
  String get bgTypeImage => 'Image';

  @override
  String get bgDeleteTitle => 'Delete background';

  @override
  String bgDeleteConfirm(String name) {
    return 'Delete \"$name\"? You can download it again anytime.';
  }

  @override
  String bgClearedTitle(String name) {
    return 'Background \"$name\" was cleared by the system';
  }

  @override
  String get bgClearedBody =>
      'When storage runs low, or you clear the app\'s cache, the system may remove downloaded backgrounds to free up space. We\'ve switched back to the default for now — you can re-download anytime.';

  @override
  String get bgOfflineTitle => 'You\'re offline';

  @override
  String get bgOfflineBody =>
      'Connect to the internet to download backgrounds.';

  @override
  String get bgDownloadErrorNetwork =>
      'No internet connection. Can\'t download the background.';

  @override
  String get bgDownloadErrorGeneric =>
      'Download failed. Please try again later.';

  @override
  String get bgSettingSubtitle => 'Customize chanting background';

  @override
  String get langFollowSystem => 'Follow system';

  @override
  String langFollowSystemWith(String name) {
    return 'Follow system ($name)';
  }
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizationsZh {
  AppLocalizationsZhHant() : super('zh_Hant');
}

/// The translations for Chinese, as used in Taiwan (`zh_TW`).
class AppLocalizationsZhTw extends AppLocalizationsZh {
  AppLocalizationsZhTw() : super('zh_TW');

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

  @override
  String get pleaseWait => '請稍候';

  @override
  String get downloading => '下載中';

  @override
  String get unzipping => '解壓縮中';

  @override
  String get completed => '完成';

  @override
  String get preparing => '準備中';

  @override
  String get preparingPleaseWait => '正在準備，請稍候…';

  @override
  String doNotOperateDuring(String phase) {
    return '「$phase」過程請保持在此畫面，\n請勿進行切換 App、關閉螢幕等任何操作。';
  }

  @override
  String get ok => '確定';

  @override
  String get downloadRequiredTitle => '需要下載';

  @override
  String downloadRequiredBody(String modelName) {
    return '語音辨識模型（$modelName）目前不在本機。\n是否要立刻下載？';
  }

  @override
  String get download => '下載';

  @override
  String get downloadFailedTitle => '下載失敗';

  @override
  String downloadFailedBody(String error) {
    return '模型下載失敗：$error';
  }

  @override
  String get successTitle => '成功';

  @override
  String get successBody => '模型已安裝完成。';

  @override
  String get unzipFailedTitle => '解壓縮失敗';

  @override
  String get unzipFailedLowSpaceBody => '可能是儲存空間不足，請清出空間後再嘗試解壓。';

  @override
  String get close => '關閉';

  @override
  String get retryUnzip => '重試解壓';

  @override
  String get downloadFailedShort => '模型下載失敗，請稍後再試或重試。';

  @override
  String get retry => '重試';

  @override
  String get feedbackOpenMailAppFailed => '無法開啟郵件 App';

  @override
  String get appName => '念佛';

  @override
  String feedbackEmailSubject(String app) {
    return '[$app] 意見回饋';
  }

  @override
  String get feedbackEmailBody => '描述問題/建議：\n\n（可附上截圖）';

  @override
  String get micPermissionTitle => '需要麥克風權限';

  @override
  String get micPermissionRationale => '語音辨識計算佛號數量，請前往系統「設定」>「念佛」>「麥克風」將權限開啟。';

  @override
  String get openSettings => '前往設定';

  @override
  String get microphonePermissionDenied => '未取得麥克風權限。';

  @override
  String get bgScreenTitle => '念佛背景';

  @override
  String get bgUse => '使用';

  @override
  String get bgUpdate => '更新';

  @override
  String get bgDelete => '刪除';

  @override
  String get bgInUse => '使用中';

  @override
  String get bgDefault => '預設背景';

  @override
  String get bgTypeVideo => '影片';

  @override
  String get bgTypeImage => '圖片';

  @override
  String get bgDeleteTitle => '刪除背景';

  @override
  String bgDeleteConfirm(String name) {
    return '確定要刪除「$name」嗎？\n刪除後，仍可重新下載。';
  }

  @override
  String bgClearedTitle(String name) {
    return '背景「$name」已被系統清除';
  }

  @override
  String get bgClearedBody =>
      '當手機儲存空間不足，或你清除了 App 暫存，系統可能會清掉先前下載的背景以釋放空間。已暫時切回預設背景，需要時可重新下載。';

  @override
  String get bgOfflineTitle => '目前處於離線狀態';

  @override
  String get bgOfflineBody => '連接網路，即可下載背景素材。';

  @override
  String get bgDownloadErrorNetwork => '網路未連線，無法下載背景。';

  @override
  String get bgDownloadErrorGeneric => '下載失敗，請稍後再試。';

  @override
  String get bgSettingSubtitle => '自訂頁面背景';

  @override
  String get langFollowSystem => '跟隨系統';

  @override
  String langFollowSystemWith(String name) {
    return '跟隨系統（$name）';
  }
}
