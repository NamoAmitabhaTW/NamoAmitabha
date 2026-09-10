// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

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
      'To count chants, please enable Microphone in System Settings > Amitabha Buddha.';

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
