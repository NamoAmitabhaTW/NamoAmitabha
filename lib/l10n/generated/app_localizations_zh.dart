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
  String get language => 'Language';

  @override
  String get cancel => 'Cancel';

  @override
  String get pleaseWait => 'Please wait';

  @override
  String get downloading => 'Downloading';

  @override
  String get unzipping => 'Installing';

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
  String get successTitle => 'Success';

  @override
  String get successBody => 'The model has been installed successfully.';

  @override
  String get unzipFailedTitle => 'Unzip failed';

  @override
  String get unzipFailedLowSpaceBody =>
      'Extraction failed due to insufficient storage. Please free up space, then tap \"Extract Again\". The downloaded file is kept, so no re-download is needed.';

  @override
  String get close => 'Close';

  @override
  String get downloadFailedShort =>
      'Model download failed. Please try again later.';

  @override
  String get modelPrepareFailed =>
      'Speech recognition model installation failed. Please make sure your device has enough storage space and try again.';

  @override
  String get retry => 'Retry';

  @override
  String get micPermissionTitle => 'Microphone Permission Required';

  @override
  String get micPermissionRationale =>
      'To count chants, please enable Microphone in System Settings > Amitabha.';

  @override
  String get openSettings => 'Open Settings';

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
  String get bgDownloadErrorNotAvailable =>
      'This background can\'t be downloaded right now. It may have been removed or replaced.';

  @override
  String get langFollowSystem => 'Follow system';

  @override
  String get cancelling => 'Cancelling…';

  @override
  String get networkErrorBody =>
      'Network connection error. Please check your connection and try again.';

  @override
  String get timeoutErrorBody =>
      'Connection timed out. Your network may be unstable or the server is temporarily unresponsive. Please try again later.';

  @override
  String get serverErrorBody =>
      'The server returned an error. Please try again later.';

  @override
  String get downloadFailedLowSpaceTitle => 'Insufficient Storage';

  @override
  String get downloadFailedLowSpaceBody =>
      'There is not enough storage space on your device to complete the installation. Please free up space, then tap \"Try Again\".';

  @override
  String get retryAfterFreeSpace => 'Space freed, try again';

  @override
  String get retryUnzipAfterFreeSpace => 'Space freed, extract again';

  @override
  String get retryUnzipNote => 'Retrying extraction after insufficient storage';

  @override
  String get dedicationTitle => 'Dedication of Merit';

  @override
  String get dedicationButton => 'Dedicate';

  @override
  String get dedicationEdit => 'Edit dedication verse';

  @override
  String get announcementsTitle => 'Announcements';

  @override
  String get announcementsEmpty => 'No announcements yet';

  @override
  String get announcementsLinkCopied => 'Link copied';

  @override
  String get rateTitle => 'Support with a Review';

  @override
  String get shareTitle => 'Share App';

  @override
  String get shareSubject =>
      'Amitabha Buddha — a free Buddha-name chanting counter';

  @override
  String get shareMessage =>
      '\"Amitabha Buddha\" is a free Buddha-name chanting counter.\nThe app listens to your recitations and counts them automatically.\nJust focus on chanting — leave the counting to \"Amitabha Buddha\"!';

  @override
  String get storeActionFailed =>
      'Couldn\'t open the store, please try again later.';

  @override
  String get appDisplayName => 'Amitabha Buddha';

  @override
  String get updateTitle => 'A New Version Is Here';

  @override
  String get updateBody =>
      'Please update the Amitabha Buddha app and help it keep getting better.';

  @override
  String get updateButton => 'Update Now';

  @override
  String get updateLater => 'Maybe later';
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
  String get times => '聲';

  @override
  String get noRecords => '目前沒有記錄';

  @override
  String get language => '語言';

  @override
  String get cancel => '取消';

  @override
  String get pleaseWait => '請稍候';

  @override
  String get downloading => '下載中';

  @override
  String get unzipping => '安裝中';

  @override
  String get completed => '完成';

  @override
  String get preparing => '準備中';

  @override
  String get preparingPleaseWait => '正在準備，請稍候…';

  @override
  String doNotOperateDuring(String phase) {
    return '「$phase」過程請保持在此畫面，\n請勿切換 App、關閉螢幕等任何操作。';
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
  String get successTitle => '成功';

  @override
  String get successBody => '模型已安裝完成。';

  @override
  String get unzipFailedTitle => '解壓縮失敗';

  @override
  String get unzipFailedLowSpaceBody =>
      '解壓縮失敗，裝置儲存空間不足。請先清出足夠空間，再點擊「重新解壓縮」。已下載的檔案會保留，不需要重新下載。';

  @override
  String get close => '關閉';

  @override
  String get downloadFailedShort => '模型下載失敗，請稍後再試或重試。';

  @override
  String get modelPrepareFailed => '語音辨識模型安裝失敗，請確認裝置儲存空間足夠後再試。';

  @override
  String get retry => '重試';

  @override
  String get micPermissionTitle => '需要麥克風權限';

  @override
  String get micPermissionRationale => '語音辨識計算佛號數量，請前往系統「設定」>「念佛」>「麥克風」將權限開啟。';

  @override
  String get openSettings => '前往設定';

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
  String get bgDownloadErrorNotAvailable => '此背景目前無法下載，可能已下架或更換。';

  @override
  String get langFollowSystem => '跟隨系統';

  @override
  String get cancelling => '取消中…';

  @override
  String get networkErrorBody => '網路連線異常，請確認網路狀態後重試。';

  @override
  String get timeoutErrorBody => '連線逾時，可能是網路不穩或伺服器暫時無回應，請稍後重試。';

  @override
  String get serverErrorBody => '伺服器回應異常，請稍後再試。';

  @override
  String get downloadFailedLowSpaceTitle => '儲存空間不足';

  @override
  String get downloadFailedLowSpaceBody =>
      '裝置儲存空間不足，無法完成安裝。請先清出足夠空間，再點擊「重新嘗試」。';

  @override
  String get retryAfterFreeSpace => '已清出空間，重新嘗試';

  @override
  String get retryUnzipAfterFreeSpace => '已清出空間，重新解壓縮';

  @override
  String get retryUnzipNote => '因儲存空間不足，重新嘗試解壓縮中';

  @override
  String get dedicationTitle => '迴向偈';

  @override
  String get dedicationButton => '迴向';

  @override
  String get dedicationEdit => '編輯迴向偈';

  @override
  String get announcementsTitle => '公告';

  @override
  String get announcementsEmpty => '目前沒有公告';

  @override
  String get announcementsLinkCopied => '已複製連結';

  @override
  String get rateTitle => '留言鼓勵';

  @override
  String get shareTitle => '分享 App';

  @override
  String get shareSubject => '好好念佛 — 免費的念佛計數 App';

  @override
  String get shareMessage =>
      '「好好念佛」是一款免費的念佛計數 App，會聆聽您的佛號聲並自動統計出佛號數量。專心念佛，計數就交給「好好念佛」！';

  @override
  String get storeActionFailed => '無法開啟商店，請稍後再試。';

  @override
  String get appDisplayName => '好好念佛';

  @override
  String get updateTitle => '新版本已發布';

  @override
  String get updateBody => '請更新 App，\n讓《好好念佛》一起變更好。';

  @override
  String get updateButton => '前往更新';

  @override
  String get updateLater => '稍後再說';
}
