// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get amitabha => 'Amitabha';

  @override
  String get chant => 'Récitation';

  @override
  String get records => 'Historique';

  @override
  String get settings => 'Réglages';

  @override
  String get start => 'Démarrer';

  @override
  String get pause => 'Pause';

  @override
  String get save => 'Enregistrer';

  @override
  String get total => 'Total';

  @override
  String get days => 'Jours';

  @override
  String get times => 'fois';

  @override
  String get noRecords => 'Aucun enregistrement';

  @override
  String get logIn => 'Connexion';

  @override
  String get logOut => 'Déconnexion';

  @override
  String get enableCloudSync => 'Activer la synchro cloud';

  @override
  String get account => 'Compte';

  @override
  String get accountStatus => 'Statut de connexion';

  @override
  String get statusSignedIn => 'Connecté';

  @override
  String get statusSignedOut => 'Non connecté';

  @override
  String get language => 'Langue';

  @override
  String currentLanguage(String lang) {
    return 'Langue actuelle : $lang';
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
  String get feedback => 'Commentaires';

  @override
  String get deleteAccount => 'Supprimer le compte';

  @override
  String get confirm => 'Confirmer';

  @override
  String get cancel => 'Annuler';

  @override
  String get done => 'Terminé';

  @override
  String get confirmDeleteAccount =>
      'Voulez-vous vraiment supprimer votre compte et vos données ? Cette action est irréversible.';

  @override
  String get pleaseWait => 'Veuillez patienter';

  @override
  String get downloading => 'Téléchargement';

  @override
  String get unzipping => 'Décompression';

  @override
  String get completed => 'Terminé';

  @override
  String get preparing => 'Préparation';

  @override
  String get preparingPleaseWait => 'Préparation, veuillez patienter…';

  @override
  String doNotOperateDuring(String phase) {
    return 'Pendant « $phase », veuillez rester sur cet écran.\nNe changez pas d\'application et n\'éteignez pas l\'écran.';
  }

  @override
  String get ok => 'OK';

  @override
  String get downloadRequiredTitle => 'Téléchargement requis';

  @override
  String downloadRequiredBody(String modelName) {
    return 'Le modèle de reconnaissance vocale ($modelName) n\'est pas disponible localement.\nVoulez-vous le télécharger ?';
  }

  @override
  String get download => 'Télécharger';

  @override
  String get downloadFailedTitle => 'Échec du téléchargement';

  @override
  String downloadFailedBody(String error) {
    return 'Échec du téléchargement du modèle : $error';
  }

  @override
  String get successTitle => 'Réussi';

  @override
  String get successBody => 'Le modèle a été installé avec succès.';

  @override
  String get unzipFailedTitle => 'Échec de la décompression';

  @override
  String get unzipFailedLowSpaceBody =>
      'Échec de la décompression : espace de stockage insuffisant. Veuillez libérer de l\'espace, puis appuyez sur « Décompresser à nouveau ». Le fichier téléchargé est conservé, aucun nouveau téléchargement n\'est nécessaire.';

  @override
  String get close => 'Fermer';

  @override
  String get retryUnzip => 'Réessayer la décompression';

  @override
  String get downloadFailedShort =>
      'Échec du téléchargement du modèle. Veuillez réessayer plus tard.';

  @override
  String get retry => 'Réessayer';

  @override
  String get feedbackOpenMailAppFailed =>
      'Impossible d\'ouvrir l\'application e-mail';

  @override
  String get appName => 'Amitabha';

  @override
  String feedbackEmailSubject(String app) {
    return '[$app] Commentaires';
  }

  @override
  String get feedbackEmailBody =>
      'Problème/Suggestion :\n\n(Vous pouvez joindre une capture d\'écran)';

  @override
  String get micPermissionTitle => 'Autorisation du micro requise';

  @override
  String get micPermissionRationale =>
      'Pour compter les récitations, activez le micro dans Réglages système > Amitabha.';

  @override
  String get openSettings => 'Ouvrir les réglages';

  @override
  String get microphonePermissionDenied =>
      'Autorisation du micro non accordée.';

  @override
  String get bgScreenTitle => 'Arrière-plan de récitation';

  @override
  String get bgUse => 'Utiliser';

  @override
  String get bgUpdate => 'Mettre à jour';

  @override
  String get bgDelete => 'Supprimer';

  @override
  String get bgInUse => 'Utilisé';

  @override
  String get bgDefault => 'Par défaut';

  @override
  String get bgTypeVideo => 'Vidéo';

  @override
  String get bgTypeImage => 'Image';

  @override
  String get bgDeleteTitle => 'Supprimer l\'arrière-plan';

  @override
  String bgDeleteConfirm(String name) {
    return 'Supprimer « $name » ? Vous pourrez le télécharger à nouveau à tout moment.';
  }

  @override
  String bgClearedTitle(String name) {
    return 'L\'arrière-plan « $name » a été supprimé par le système';
  }

  @override
  String get bgClearedBody =>
      'Lorsque le stockage est faible ou que vous videz le cache de l\'app, le système peut supprimer les arrière-plans téléchargés pour libérer de l\'espace. Nous sommes revenus au réglage par défaut pour l\'instant — vous pouvez retélécharger à tout moment.';

  @override
  String get bgOfflineTitle => 'Vous êtes hors ligne';

  @override
  String get bgOfflineBody =>
      'Connectez-vous à Internet pour télécharger des arrière-plans.';

  @override
  String get bgDownloadErrorNetwork =>
      'Pas de connexion Internet. Impossible de télécharger l\'arrière-plan.';

  @override
  String get bgDownloadErrorGeneric =>
      'Échec du téléchargement. Veuillez réessayer plus tard.';

  @override
  String get bgSettingSubtitle => 'Personnaliser l\'arrière-plan de récitation';

  @override
  String get langFollowSystem => 'Suivre le système';

  @override
  String langFollowSystemWith(String name) {
    return 'Suivre le système ($name)';
  }

  @override
  String get cancelling => 'Annulation…';

  @override
  String get networkErrorBody =>
      'Problème de connexion réseau. Veuillez vérifier votre connexion puis réessayer.';

  @override
  String get timeoutErrorBody =>
      'Délai de connexion dépassé. Le réseau est peut-être instable ou le serveur ne répond temporairement pas. Veuillez réessayer plus tard.';

  @override
  String get serverErrorBody =>
      'Le serveur a renvoyé une erreur. Veuillez réessayer plus tard.';

  @override
  String get downloadFailedLowSpaceTitle => 'Espace de stockage insuffisant';

  @override
  String get downloadFailedLowSpaceBody =>
      'L\'espace de stockage de votre appareil est insuffisant pour terminer l\'installation. Veuillez libérer de l\'espace, puis appuyez sur « Réessayer ».';

  @override
  String get retryAfterFreeSpace => 'Espace libéré, réessayer';

  @override
  String get retryUnzipAfterFreeSpace =>
      'Espace libéré, décompresser à nouveau';

  @override
  String get retryUnzipNote =>
      'Nouvelle tentative de décompression suite au manque d\'espace';
}
