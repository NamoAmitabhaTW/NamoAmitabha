// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get amitabha => '阿弥陀仏';

  @override
  String get chant => '念仏';

  @override
  String get records => '記録';

  @override
  String get settings => '設定';

  @override
  String get start => '開始';

  @override
  String get pause => '一時停止';

  @override
  String get save => '保存';

  @override
  String get total => '累計';

  @override
  String get days => '日';

  @override
  String get times => '回';

  @override
  String get noRecords => 'まだ記録がありません';

  @override
  String get logIn => 'ログイン';

  @override
  String get logOut => 'ログアウト';

  @override
  String get enableCloudSync => 'クラウド同期を有効にする';

  @override
  String get account => 'アカウント';

  @override
  String get accountStatus => 'ログイン状態';

  @override
  String get statusSignedIn => 'ログイン済み';

  @override
  String get statusSignedOut => '未ログイン';

  @override
  String get language => '言語';

  @override
  String currentLanguage(String lang) {
    return '現在の言語：$lang';
  }

  @override
  String get langZhHant => '繁體中文';

  @override
  String get langEn => 'English';

  @override
  String get langJa => '日本語';

  @override
  String get langKo => '한국어';

  @override
  String get langVi => 'Tiếng Việt';

  @override
  String get langDe => 'Deutsch';

  @override
  String get langFr => 'Français';

  @override
  String get feedback => 'フィードバック';

  @override
  String get deleteAccount => 'アカウントを削除';

  @override
  String get confirm => '確認';

  @override
  String get cancel => 'キャンセル';

  @override
  String get done => '完了';

  @override
  String get confirmDeleteAccount => 'アカウントとデータを削除してもよろしいですか？この操作は取り消せません。';

  @override
  String get pleaseWait => 'お待ちください';

  @override
  String get downloading => 'ダウンロード中';

  @override
  String get unzipping => 'インストール中';

  @override
  String get completed => '完了';

  @override
  String get preparing => '準備中';

  @override
  String get preparingPleaseWait => '準備中です。お待ちください…';

  @override
  String doNotOperateDuring(String phase) {
    return '「$phase」中はこの画面のままにしてください。\nアプリの切り替えや画面のオフなどの操作は行わないでください。';
  }

  @override
  String get ok => 'OK';

  @override
  String get downloadRequiredTitle => 'ダウンロードが必要';

  @override
  String downloadRequiredBody(String modelName) {
    return '音声認識モデル（$modelName）が端末にありません。\n今すぐダウンロードしますか？';
  }

  @override
  String get download => 'ダウンロード';

  @override
  String get downloadFailedTitle => 'ダウンロード失敗';

  @override
  String downloadFailedBody(String error) {
    return 'モデルのダウンロードに失敗しました：$error';
  }

  @override
  String get successTitle => '成功';

  @override
  String get successBody => 'モデルのインストールが完了しました。';

  @override
  String get unzipFailedTitle => '解凍に失敗';

  @override
  String get unzipFailedLowSpaceBody =>
      'ストレージ容量不足のため解凍に失敗しました。空き容量を確保してから「再解凍」をタップしてください。ダウンロード済みのファイルは保持されるため、再ダウンロードは不要です。';

  @override
  String get close => '閉じる';

  @override
  String get retryUnzip => '解凍を再試行';

  @override
  String get downloadFailedShort => 'モデルのダウンロードに失敗しました。後でもう一度お試しください。';

  @override
  String get modelPrepareFailed =>
      '音声認識モデルのインストールに失敗しました。デバイスの空き容量が十分にあることを確認してから、もう一度お試しください。';

  @override
  String get retry => '再試行';

  @override
  String get feedbackOpenMailAppFailed => 'メールアプリを開けませんでした';

  @override
  String get appName => '念仏日和';

  @override
  String feedbackEmailSubject(String app) {
    return '[$app] フィードバック';
  }

  @override
  String get feedbackEmailBody => '問題・ご提案：\n\n（スクリーンショットを添付できます）';

  @override
  String get micPermissionTitle => 'マイクの許可が必要です';

  @override
  String get micPermissionRationale =>
      '念仏の回数を数えるため、システムの「設定」>「念仏」>「マイク」で許可を有効にしてください。';

  @override
  String get openSettings => '設定を開く';

  @override
  String get microphonePermissionDenied => 'マイクの許可が得られていません。';

  @override
  String get bgScreenTitle => '念仏の背景';

  @override
  String get bgUse => '使用';

  @override
  String get bgUpdate => '更新';

  @override
  String get bgDelete => '削除';

  @override
  String get bgInUse => '使用中';

  @override
  String get bgDefault => 'デフォルト';

  @override
  String get bgTypeVideo => '動画';

  @override
  String get bgTypeImage => '画像';

  @override
  String get bgDeleteTitle => '背景を削除';

  @override
  String bgDeleteConfirm(String name) {
    return '「$name」を削除しますか？\n削除後もいつでも再ダウンロードできます。';
  }

  @override
  String bgClearedTitle(String name) {
    return '背景「$name」がシステムによって削除されました';
  }

  @override
  String get bgClearedBody =>
      'ストレージの空き容量が不足したり、アプリのキャッシュを消去すると、システムが空き容量を確保するためにダウンロード済みの背景を削除することがあります。現在はデフォルトに戻しています。必要なときに再ダウンロードできます。';

  @override
  String get bgOfflineTitle => 'オフラインです';

  @override
  String get bgOfflineBody => 'インターネットに接続すると背景をダウンロードできます。';

  @override
  String get bgDownloadErrorNetwork => 'インターネットに接続されていないため、背景をダウンロードできません。';

  @override
  String get bgDownloadErrorGeneric => 'ダウンロードに失敗しました。後でもう一度お試しください。';

  @override
  String get bgDownloadErrorNotAvailable =>
      'この背景は現在ダウンロードできません。提供終了または差し替えの可能性があります。';

  @override
  String get bgSettingSubtitle => '念仏の背景をカスタマイズ';

  @override
  String get langFollowSystem => 'システムに従う';

  @override
  String langFollowSystemWith(String name) {
    return 'システムに従う（$name）';
  }

  @override
  String get cancelling => 'キャンセル中…';

  @override
  String get networkErrorBody => 'ネットワーク接続に問題があります。接続状況をご確認のうえ、もう一度お試しください。';

  @override
  String get timeoutErrorBody =>
      '接続がタイムアウトしました。ネットワークが不安定か、サーバーが一時的に応答していない可能性があります。しばらくしてからもう一度お試しください。';

  @override
  String get serverErrorBody => 'サーバーの応答に問題があります。しばらくしてからもう一度お試しください。';

  @override
  String get downloadFailedLowSpaceTitle => 'ストレージ容量不足';

  @override
  String get downloadFailedLowSpaceBody =>
      '端末のストレージ容量が不足しているため、インストールを完了できません。空き容量を確保してから「再試行」をタップしてください。';

  @override
  String get retryAfterFreeSpace => '空き容量を確保して再試行';

  @override
  String get retryUnzipAfterFreeSpace => '空き容量を確保して再解凍';

  @override
  String get retryUnzipNote => '容量不足のため、解凍を再試行しています';

  @override
  String get dedicationTitle => '回向偈';

  @override
  String get dedicationButton => '回向';

  @override
  String get dedicationEdit => '回向偈を編集';

  @override
  String get announcementsTitle => 'お知らせ';

  @override
  String get announcementsSubtitle => '最新情報を見る';

  @override
  String get announcementsEmpty => 'お知らせはまだありません';

  @override
  String get announcementsLinkCopied => 'リンクをコピーしました';

  @override
  String get rateTitle => 'レビューで応援';

  @override
  String get rateSubtitle => 'ストアで評価する';

  @override
  String get shareTitle => 'アプリを共有';

  @override
  String get shareSubtitle => '友だちや家族にすすめる';

  @override
  String get shareSubject => '念仏日和 — 無料の念仏カウンターアプリ';

  @override
  String get shareMessage =>
      '「念仏日和」は無料の念仏カウンターアプリです。\nあなたの念仏の声を聞き取り、称えた数を自動で数えます。\n念仏に専念して、カウントは「念仏日和」におまかせ！';

  @override
  String get storeActionFailed => 'ストアを開けませんでした。しばらくしてからもう一度お試しください。';
}
