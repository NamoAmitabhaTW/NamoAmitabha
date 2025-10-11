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
