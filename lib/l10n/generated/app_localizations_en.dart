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
  String get noRecords => 'No records';

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
}
