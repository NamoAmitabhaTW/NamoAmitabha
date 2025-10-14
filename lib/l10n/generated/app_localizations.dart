import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale.fromSubtags(
      languageCode: 'zh',
      countryCode: 'TW',
      scriptCode: 'Hant',
    ),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
    Locale('zh', 'TW'),
  ];

  /// App title / Buddha name label
  ///
  /// In en, this message translates to:
  /// **'Amitabha'**
  String get amitabha;

  /// Can be used for bottom tab label and screen title
  ///
  /// In en, this message translates to:
  /// **'Chant'**
  String get chant;

  /// Bottom nav: Records tab
  ///
  /// In en, this message translates to:
  /// **'Records'**
  String get records;

  /// Bottom nav: Settings tab
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Start button
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// Pause button
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// Save current session count
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Stats: total accumulated count
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// Stats: number of practice days (unique dates from records)
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get days;

  /// Unit text for counts
  ///
  /// In en, this message translates to:
  /// **'times'**
  String get times;

  /// Records page empty state
  ///
  /// In en, this message translates to:
  /// **'No records'**
  String get noRecords;

  /// General login label (use enableCloudSync for the cloud-sync CTA)
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get logIn;

  /// Sign-out button
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logOut;

  /// Enable backup & sync (lazily initialize Firebase)
  ///
  /// In en, this message translates to:
  /// **'Enable Cloud Sync'**
  String get enableCloudSync;

  /// Settings: account section title
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// Settings: sign-in status label
  ///
  /// In en, this message translates to:
  /// **'Sign-in status'**
  String get accountStatus;

  /// Signed-in state label
  ///
  /// In en, this message translates to:
  /// **'Signed in'**
  String get statusSignedIn;

  /// Signed-out state label
  ///
  /// In en, this message translates to:
  /// **'Not signed in'**
  String get statusSignedOut;

  /// Settings: language switch
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Display the currently active language name
  ///
  /// In en, this message translates to:
  /// **'Current language: {lang}'**
  String currentLanguage(String lang);

  /// Language option: Traditional Chinese
  ///
  /// In en, this message translates to:
  /// **'Chinese (Traditional)'**
  String get langZhHant;

  /// Language option: English
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get langEn;

  /// Settings: feedback item
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback;

  /// Settings: delete account
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// Dialog title: confirm
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// Dialog button: cancel
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Generic completion toast
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// Delete account confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account and data? This action cannot be undone.'**
  String get confirmDeleteAccount;

  /// No description provided for @pleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Please wait'**
  String get pleaseWait;

  /// No description provided for @downloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading'**
  String get downloading;

  /// No description provided for @unzipping.
  ///
  /// In en, this message translates to:
  /// **'Unzipping'**
  String get unzipping;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @preparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing'**
  String get preparing;

  /// No description provided for @preparingPleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Preparing, please wait…'**
  String get preparingPleaseWait;

  /// No description provided for @doNotOperateDuring.
  ///
  /// In en, this message translates to:
  /// **'Do not operate during {phase}'**
  String doNotOperateDuring(String phase);

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @downloadRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Download Required'**
  String get downloadRequiredTitle;

  /// No description provided for @downloadRequiredBody.
  ///
  /// In en, this message translates to:
  /// **'The speech recognition model ({modelName}) is not available locally. Do you want to download it?'**
  String downloadRequiredBody(String modelName);

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @downloadFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Download Failed'**
  String get downloadFailedTitle;

  /// No description provided for @downloadFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Failed to download the model: {error}'**
  String downloadFailedBody(String error);

  /// No description provided for @successTitle.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get successTitle;

  /// No description provided for @successBody.
  ///
  /// In en, this message translates to:
  /// **'The model has been downloaded and extracted successfully.'**
  String get successBody;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hant':
            return AppLocalizationsZhHant();
        }
        break;
      }
  }

  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.countryCode) {
          case 'TW':
            return AppLocalizationsZhTw();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
