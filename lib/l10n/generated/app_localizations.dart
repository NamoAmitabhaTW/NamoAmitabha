import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_vi.dart';
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
    Locale('de'),
    Locale('fr'),
    Locale('ja'),
    Locale('ko'),
    Locale('vi'),
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
  /// **'No records yet'**
  String get noRecords;

  /// Settings: language switch
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Dialog button: cancel
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

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
  /// **'Installing'**
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

  /// Shown like: Please do not perform any operations during Downloading/Unzipping
  ///
  /// In en, this message translates to:
  /// **'Please stay on this screen during \"{phase}\". Do not switch apps or turn off the screen.'**
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

  /// No description provided for @successTitle.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get successTitle;

  /// No description provided for @successBody.
  ///
  /// In en, this message translates to:
  /// **'The model has been installed successfully.'**
  String get successBody;

  /// No description provided for @unzipFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Unzip failed'**
  String get unzipFailedTitle;

  /// No description provided for @unzipFailedLowSpaceBody.
  ///
  /// In en, this message translates to:
  /// **'Extraction failed due to insufficient storage. Please free up space, then tap \"Extract Again\". The downloaded file is kept, so no re-download is needed.'**
  String get unzipFailedLowSpaceBody;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @downloadFailedShort.
  ///
  /// In en, this message translates to:
  /// **'Model download failed. Please try again later.'**
  String get downloadFailedShort;

  /// No description provided for @modelPrepareFailed.
  ///
  /// In en, this message translates to:
  /// **'Speech recognition model installation failed. Please make sure your device has enough storage space and try again.'**
  String get modelPrepareFailed;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @micPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Microphone Permission Required'**
  String get micPermissionTitle;

  /// No description provided for @micPermissionRationale.
  ///
  /// In en, this message translates to:
  /// **'To count chants, please enable Microphone in System Settings > Amitabha Buddha.'**
  String get micPermissionRationale;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @bgScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Chanting Background'**
  String get bgScreenTitle;

  /// No description provided for @bgUse.
  ///
  /// In en, this message translates to:
  /// **'Use'**
  String get bgUse;

  /// No description provided for @bgUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get bgUpdate;

  /// No description provided for @bgDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get bgDelete;

  /// No description provided for @bgInUse.
  ///
  /// In en, this message translates to:
  /// **'In use'**
  String get bgInUse;

  /// No description provided for @bgDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get bgDefault;

  /// No description provided for @bgTypeVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get bgTypeVideo;

  /// No description provided for @bgTypeImage.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get bgTypeImage;

  /// No description provided for @bgDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete background'**
  String get bgDeleteTitle;

  /// No description provided for @bgDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"? You can download it again anytime.'**
  String bgDeleteConfirm(String name);

  /// No description provided for @bgClearedTitle.
  ///
  /// In en, this message translates to:
  /// **'Background \"{name}\" was cleared by the system'**
  String bgClearedTitle(String name);

  /// No description provided for @bgClearedBody.
  ///
  /// In en, this message translates to:
  /// **'When storage runs low, or you clear the app\'s cache, the system may remove downloaded backgrounds to free up space. We\'ve switched back to the default for now — you can re-download anytime.'**
  String get bgClearedBody;

  /// No description provided for @bgOfflineTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline'**
  String get bgOfflineTitle;

  /// No description provided for @bgOfflineBody.
  ///
  /// In en, this message translates to:
  /// **'Connect to the internet to download backgrounds.'**
  String get bgOfflineBody;

  /// No description provided for @bgDownloadErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Can\'t download the background.'**
  String get bgDownloadErrorNetwork;

  /// No description provided for @bgDownloadErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Download failed. Please try again later.'**
  String get bgDownloadErrorGeneric;

  /// No description provided for @bgDownloadErrorNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'This background can\'t be downloaded right now. It may have been removed or replaced.'**
  String get bgDownloadErrorNotAvailable;

  /// No description provided for @langFollowSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get langFollowSystem;

  /// No description provided for @cancelling.
  ///
  /// In en, this message translates to:
  /// **'Cancelling…'**
  String get cancelling;

  /// No description provided for @networkErrorBody.
  ///
  /// In en, this message translates to:
  /// **'Network connection error. Please check your connection and try again.'**
  String get networkErrorBody;

  /// No description provided for @timeoutErrorBody.
  ///
  /// In en, this message translates to:
  /// **'Connection timed out. Your network may be unstable or the server is temporarily unresponsive. Please try again later.'**
  String get timeoutErrorBody;

  /// No description provided for @serverErrorBody.
  ///
  /// In en, this message translates to:
  /// **'The server returned an error. Please try again later.'**
  String get serverErrorBody;

  /// No description provided for @downloadFailedLowSpaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Insufficient Storage'**
  String get downloadFailedLowSpaceTitle;

  /// No description provided for @downloadFailedLowSpaceBody.
  ///
  /// In en, this message translates to:
  /// **'There is not enough storage space on your device to complete the installation. Please free up space, then tap \"Try Again\".'**
  String get downloadFailedLowSpaceBody;

  /// No description provided for @retryAfterFreeSpace.
  ///
  /// In en, this message translates to:
  /// **'Space freed, try again'**
  String get retryAfterFreeSpace;

  /// No description provided for @retryUnzipAfterFreeSpace.
  ///
  /// In en, this message translates to:
  /// **'Space freed, extract again'**
  String get retryUnzipAfterFreeSpace;

  /// No description provided for @retryUnzipNote.
  ///
  /// In en, this message translates to:
  /// **'Retrying extraction after insufficient storage'**
  String get retryUnzipNote;

  /// Title of the dedication-verse full-screen page and settings item
  ///
  /// In en, this message translates to:
  /// **'Dedication of Merit'**
  String get dedicationTitle;

  /// Button on the dedication page; enabled after the verse finishes animating
  ///
  /// In en, this message translates to:
  /// **'Dedicate'**
  String get dedicationButton;

  /// Settings subtitle / editor screen title for editing the dedication verse
  ///
  /// In en, this message translates to:
  /// **'Edit dedication verse'**
  String get dedicationEdit;

  /// Settings entry and screen title for announcements
  ///
  /// In en, this message translates to:
  /// **'Announcements'**
  String get announcementsTitle;

  /// Shown when there are no announcements or content is unavailable
  ///
  /// In en, this message translates to:
  /// **'No announcements yet'**
  String get announcementsEmpty;

  /// Snackbar shown after tapping a link in an announcement
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get announcementsLinkCopied;

  /// Settings entry: opens the app store rating/review page
  ///
  /// In en, this message translates to:
  /// **'Support with a Review'**
  String get rateTitle;

  /// Settings entry: opens the system share sheet
  ///
  /// In en, this message translates to:
  /// **'Share App'**
  String get shareTitle;

  /// Subject line used when the share is sent as an email
  ///
  /// In en, this message translates to:
  /// **'Amitabha Buddha — a free Buddha-name chanting counter'**
  String get shareSubject;

  /// Intro paragraph in the share sheet; download links are appended after it
  ///
  /// In en, this message translates to:
  /// **'\"Amitabha Buddha\" is a free Buddha-name chanting counter.\nThe app listens to your recitations and counts them automatically.\nJust focus on chanting — leave the counting to \"Amitabha Buddha\"!'**
  String get shareMessage;

  /// Snackbar shown when opening the store listing fails
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the store, please try again later.'**
  String get storeActionFailed;

  /// The app's display name as it appears on the device home screen
  ///
  /// In en, this message translates to:
  /// **'Amitabha Buddha'**
  String get appDisplayName;

  /// Headline on the full-screen update prompt
  ///
  /// In en, this message translates to:
  /// **'A New Version Is Here'**
  String get updateTitle;

  /// Body text on the full-screen update prompt
  ///
  /// In en, this message translates to:
  /// **'Please update the Amitabha Buddha app and help it keep getting better.'**
  String get updateBody;

  /// Primary button that opens the app's store listing
  ///
  /// In en, this message translates to:
  /// **'Update Now'**
  String get updateButton;

  /// Tooltip and accessibility label for the close (X) button
  ///
  /// In en, this message translates to:
  /// **'Maybe later'**
  String get updateLater;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'fr',
    'ja',
    'ko',
    'vi',
    'zh',
  ].contains(locale.languageCode);

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
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'vi':
      return AppLocalizationsVi();
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
