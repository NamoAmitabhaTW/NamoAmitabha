// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get amitabha => 'Amitabha';

  @override
  String get chant => 'Rezitation';

  @override
  String get records => 'Verlauf';

  @override
  String get settings => 'Einstellungen';

  @override
  String get start => 'Start';

  @override
  String get pause => 'Pause';

  @override
  String get save => 'Speichern';

  @override
  String get total => 'Gesamt';

  @override
  String get days => 'Tage';

  @override
  String get times => 'Mal';

  @override
  String get noRecords => 'Noch keine Einträge';

  @override
  String get language => 'Sprache';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get pleaseWait => 'Bitte warten';

  @override
  String get downloading => 'Wird heruntergeladen';

  @override
  String get unzipping => 'Wird installiert';

  @override
  String get completed => 'Abgeschlossen';

  @override
  String get preparing => 'Wird vorbereitet';

  @override
  String get preparingPleaseWait => 'Wird vorbereitet, bitte warten…';

  @override
  String doNotOperateDuring(String phase) {
    return 'Bitte bleiben Sie während \"$phase\" auf diesem Bildschirm.\nWechseln Sie nicht die App und schalten Sie den Bildschirm nicht aus.';
  }

  @override
  String get ok => 'OK';

  @override
  String get downloadRequiredTitle => 'Download erforderlich';

  @override
  String downloadRequiredBody(String modelName) {
    return 'Das Spracherkennungsmodell ($modelName) ist nicht lokal verfügbar.\nMöchten Sie es herunterladen?';
  }

  @override
  String get download => 'Herunterladen';

  @override
  String get downloadFailedTitle => 'Download fehlgeschlagen';

  @override
  String get successTitle => 'Erfolg';

  @override
  String get successBody => 'Das Modell wurde erfolgreich installiert.';

  @override
  String get unzipFailedTitle => 'Entpacken fehlgeschlagen';

  @override
  String get unzipFailedLowSpaceBody =>
      'Das Entpacken ist wegen unzureichenden Speicherplatzes fehlgeschlagen. Bitte geben Sie Speicherplatz frei und tippen Sie dann auf „Erneut entpacken“. Die heruntergeladene Datei bleibt erhalten – ein erneuter Download ist nicht nötig.';

  @override
  String get close => 'Schließen';

  @override
  String get downloadFailedShort =>
      'Modell-Download fehlgeschlagen. Bitte versuchen Sie es später erneut.';

  @override
  String get modelPrepareFailed =>
      'Installation des Spracherkennungsmodells fehlgeschlagen. Bitte stellen Sie sicher, dass genügend Speicherplatz auf dem Gerät vorhanden ist, und versuchen Sie es erneut.';

  @override
  String get retry => 'Wiederholen';

  @override
  String get micPermissionTitle => 'Mikrofonberechtigung erforderlich';

  @override
  String get micPermissionRationale =>
      'Um Rezitationen zu zählen, aktivieren Sie das Mikrofon in den Systemeinstellungen > Amitabha.';

  @override
  String get openSettings => 'Einstellungen öffnen';

  @override
  String get bgScreenTitle => 'Rezitations-Hintergrund';

  @override
  String get bgUse => 'Verwenden';

  @override
  String get bgUpdate => 'Aktualisieren';

  @override
  String get bgDelete => 'Löschen';

  @override
  String get bgInUse => 'In Verwendung';

  @override
  String get bgDefault => 'Standard';

  @override
  String get bgTypeVideo => 'Video';

  @override
  String get bgTypeImage => 'Bild';

  @override
  String get bgDeleteTitle => 'Hintergrund löschen';

  @override
  String bgDeleteConfirm(String name) {
    return '„$name“ löschen? Sie können es jederzeit erneut herunterladen.';
  }

  @override
  String bgClearedTitle(String name) {
    return 'Hintergrund „$name“ wurde vom System entfernt';
  }

  @override
  String get bgClearedBody =>
      'Bei wenig Speicherplatz oder wenn Sie den App-Cache leeren, kann das System heruntergeladene Hintergründe entfernen, um Speicher freizugeben. Wir haben vorerst zum Standard zurückgewechselt — Sie können jederzeit erneut herunterladen.';

  @override
  String get bgOfflineTitle => 'Sie sind offline';

  @override
  String get bgOfflineBody =>
      'Stellen Sie eine Internetverbindung her, um Hintergründe herunterzuladen.';

  @override
  String get bgDownloadErrorNetwork =>
      'Keine Internetverbindung. Hintergrund kann nicht heruntergeladen werden.';

  @override
  String get bgDownloadErrorGeneric =>
      'Download fehlgeschlagen. Bitte versuchen Sie es später erneut.';

  @override
  String get bgDownloadErrorNotAvailable =>
      'Dieser Hintergrund kann derzeit nicht heruntergeladen werden. Er wurde möglicherweise entfernt oder ersetzt.';

  @override
  String get langFollowSystem => 'System folgen';

  @override
  String get cancelling => 'Wird abgebrochen …';

  @override
  String get networkErrorBody =>
      'Netzwerkverbindungsfehler. Bitte überprüfen Sie Ihre Verbindung und versuchen Sie es erneut.';

  @override
  String get timeoutErrorBody =>
      'Zeitüberschreitung der Verbindung. Das Netzwerk ist möglicherweise instabil oder der Server antwortet vorübergehend nicht. Bitte versuchen Sie es später erneut.';

  @override
  String get serverErrorBody =>
      'Der Server hat einen Fehler zurückgegeben. Bitte versuchen Sie es später erneut.';

  @override
  String get downloadFailedLowSpaceTitle => 'Nicht genügend Speicherplatz';

  @override
  String get downloadFailedLowSpaceBody =>
      'Der Speicherplatz auf Ihrem Gerät reicht nicht aus, um die Installation abzuschließen. Bitte geben Sie Speicherplatz frei und tippen Sie dann auf „Erneut versuchen“.';

  @override
  String get retryAfterFreeSpace => 'Speicher freigegeben, erneut versuchen';

  @override
  String get retryUnzipAfterFreeSpace =>
      'Speicher freigegeben, erneut entpacken';

  @override
  String get retryUnzipNote =>
      'Entpacken wird wegen Speichermangels erneut versucht';

  @override
  String get dedicationTitle => 'Widmung der Verdienste';

  @override
  String get dedicationButton => 'Widmen';

  @override
  String get dedicationEdit => 'Widmungsvers bearbeiten';

  @override
  String get announcementsTitle => 'Ankündigungen';

  @override
  String get announcementsEmpty => 'Noch keine Ankündigungen';

  @override
  String get announcementsLinkCopied => 'Link kopiert';

  @override
  String get rateTitle => 'Mit einer Rezension unterstützen';

  @override
  String get shareTitle => 'App teilen';

  @override
  String get shareSubject =>
      'Amitabha Buddha — kostenloser Zähler für die Buddha-Anrufung';

  @override
  String get shareMessage =>
      '„Amitabha Buddha“ ist ein kostenloser Zähler für die Buddha-Anrufung.\nDie App hört deine Rezitationen und zählt sie automatisch.\nKonzentriere dich ganz aufs Rezitieren – das Zählen übernimmt „Amitabha Buddha“!';

  @override
  String get storeActionFailed =>
      'Store konnte nicht geöffnet werden. Bitte versuche es später erneut.';

  @override
  String get appDisplayName => 'Amitabha Buddha';

  @override
  String get updateTitle => 'Eine neue Version ist erschienen';

  @override
  String get updateBody =>
      'Aktualisiere die App, damit „Amitabha Buddha“ immer besser wird.';

  @override
  String get updateButton => 'Jetzt aktualisieren';

  @override
  String get updateLater => 'Später';
}
