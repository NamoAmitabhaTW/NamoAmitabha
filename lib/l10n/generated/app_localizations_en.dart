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
