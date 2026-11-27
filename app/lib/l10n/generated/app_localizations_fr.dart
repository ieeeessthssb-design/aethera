// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'AETHERA';

  @override
  String get welcomeTitle => 'Cultivez plus intelligemment.';

  @override
  String get welcomeSubtitle => 'Votre compagnon agricole intelligent.';

  @override
  String get dashboardTitle => 'Votre exploitation en un coup d\'œil';

  @override
  String get dashboardSubtitle =>
      'Tout ce qu\'il vous faut pour cultiver sereinement.';

  @override
  String get greeting => 'Bon retour !';

  @override
  String get language => 'Langue';

  @override
  String get theme => 'Apparence';

  @override
  String get settings => 'Paramètres';

  @override
  String get light => 'Clair';

  @override
  String get dark => 'Sombre';

  @override
  String get system => 'Système';

  @override
  String get english => 'Anglais';

  @override
  String get french => 'Français';

  @override
  String get arabic => 'Arabe';

  @override
  String get assistant => 'Assistant IA';

  @override
  String get diagnosis => 'Diagnostic des cultures';

  @override
  String get irrigation => 'Irrigation intelligente';

  @override
  String get community => 'Communauté';

  @override
  String get profile => 'Mon profil';

  @override
  String get weather => 'Météo';

  @override
  String get soilMoisture => 'Humidité du sol';

  @override
  String get preferences => 'Préférences de l\'application';

  @override
  String get chooseLanguage => 'Choisissez votre langue';

  @override
  String get chooseTheme => 'Choisissez votre apparence';

  @override
  String get backToHome => 'Retour à l\'accueil';

  @override
  String get home => 'Accueil';

  @override
  String get farms => 'Exploitations';

  @override
  String get messages => 'Messages';

  @override
  String get collapseSidebar => 'Réduire la barre latérale';

  @override
  String get expandSidebar => 'Développer la barre latérale';

  @override
  String get openNavigation => 'Ouvrir la navigation';

  @override
  String get account => 'Compte';

  @override
  String get managePersonalDetails => 'Gérer vos informations personnelles';

  @override
  String get manageAccountPreferences =>
      'Gérez votre compte AETHERA et vos préférences.';

  @override
  String get farmerAccount => 'Compte agriculteur';

  @override
  String get personalInformation => 'Informations personnelles';

  @override
  String get personalInformationMessage =>
      'Les informations de votre compte agriculteur apparaîtront ici.';

  @override
  String get helpSupport => 'Aide et assistance';

  @override
  String get helpSupportMessage =>
      'Pour obtenir de l’aide sur AETHERA, contactez notre équipe.';

  @override
  String get logout => 'Se déconnecter';

  @override
  String get logoutQuestion => 'Se déconnecter ?';

  @override
  String get logoutConfirmation => 'Voulez-vous vraiment vous déconnecter ?';

  @override
  String get close => 'Fermer';

  @override
  String get cancel => 'Annuler';

  @override
  String get addFarm => 'Ajouter une exploitation';

  @override
  String get farmName => 'Nom de l’exploitation *';

  @override
  String get location => 'Emplacement *';

  @override
  String get areaHectares => 'Superficie en hectares';

  @override
  String get soilType => 'Type de sol';

  @override
  String get irrigationType => 'Type d’irrigation';

  @override
  String get saveFarm => 'Enregistrer l’exploitation';

  @override
  String get farmAdded => 'Exploitation ajoutée avec succès !';

  @override
  String get farmLoadError =>
      'Impossible de charger les exploitations. Vérifiez votre connexion.';

  @override
  String farmSaveError(String error) {
    return 'Impossible d’enregistrer l’exploitation : $error';
  }

  @override
  String get noFarms => 'Aucune exploitation pour le moment';

  @override
  String get addFirstFarm =>
      'Appuyez sur Ajouter une exploitation pour enregistrer votre première exploitation.';

  @override
  String get yourFarms => 'Vos exploitations';

  @override
  String get manageFarms => 'Gérez vos terres et vos activités agricoles.';

  @override
  String get tryAgain => 'Réessayer';

  @override
  String get enterTwoChars => 'Saisissez au moins 2 caractères.';

  @override
  String get enterPositiveNumber => 'Saisissez un nombre supérieur à zéro.';

  @override
  String get notSpecified => 'Non renseigné';

  @override
  String get area => 'Superficie';

  @override
  String get save => 'Enregistrer';

  @override
  String get chooseFarm => 'Choisir une exploitation';

  @override
  String get locationExample => 'ex. Sousse, Tunisie';

  @override
  String get areaExample => 'ex. 5,5';

  @override
  String get soilExample => 'ex. argileux, sableux, limoneux';

  @override
  String get irrigationExample => 'ex. goutte-à-goutte, aspersion';

  @override
  String get hectares => 'hectares';

  @override
  String get fieldIntelligence => 'INTELLIGENCE AGRICOLE AETHERA';

  @override
  String get fieldTagline => 'Chaque décision au champ compte.';

  @override
  String get fieldDescription =>
      'Posez vos questions sur l’irrigation, les cultures et les soins agricoles.';

  @override
  String get exploreTools => 'Explorer vos outils';

  @override
  String get talkToAethera => 'Parler à AETHERA';

  @override
  String get voiceAssistantDescription =>
      'Maintenez le microphone pour parler en derja tunisien.';

  @override
  String get voiceTitle => 'Assistant agricole';

  @override
  String get voiceListening => 'Écoute en cours… parlez maintenant';

  @override
  String get voiceSpeaking => 'AETHERA vous répond…';

  @override
  String get voiceWelcome => 'Bienvenue sur AETHERA';

  @override
  String get voiceListeningHint =>
      'Relâchez le microphone lorsque vous avez terminé.';

  @override
  String get voiceInstruction => 'Maintenez le microphone pour parler.';

  @override
  String get voicePressHold => 'MAINTENIR POUR PARLER';

  @override
  String get voiceInputHint => 'Ou écrivez votre question ici…';

  @override
  String get voiceAsk => 'Demander à AETHERA';

  @override
  String get voiceQuestion => 'Votre question';

  @override
  String get voiceNoQuestion => 'Aucune question enregistrée.';

  @override
  String get voiceAnswer => 'Réponse';

  @override
  String get voiceStopAudio => 'Arrêter la lecture';

  @override
  String get voiceListenAnswer => 'Écouter la réponse';

  @override
  String get voiceDisclaimer =>
      'Ces conseils sont préliminaires. En cas de maladie ou de ravageur non identifié, consultez un expert agricole avant tout traitement.';

  @override
  String get voiceSpeechUnavailable =>
      'La reconnaissance vocale est indisponible. Vous pouvez écrire votre question.';

  @override
  String get voiceMicError => 'Impossible de démarrer le microphone.';

  @override
  String get voiceAudioError =>
      'La lecture audio a échoué. Vous pouvez lire la réponse.';

  @override
  String get voiceAnswerWater =>
      'Vérifiez l’humidité du sol avant d’arroser. Évitez l’excès d’eau et tenez compte de la culture, du sol et de la météo.';

  @override
  String get voiceAnswerYellow =>
      'Le jaunissement des feuilles peut être causé par un excès ou un manque d’eau, ou une carence nutritive. Vérifiez l’humidité du sol et les feuilles touchées. Un diagnostic précis peut nécessiter une photo et l’avis d’un expert.';

  @override
  String get voiceAnswerPest =>
      'Si vous suspectez une maladie ou un insecte, photographiez la plante et les feuilles touchées. N’utilisez pas de pesticide avant d’identifier le problème. Demandez l’avis d’un expert agricole.';

  @override
  String get voiceAnswerTomato =>
      'Pour les tomates, surveillez l’humidité du sol et évitez l’excès d’eau. Examinez les feuilles et les fruits et consultez un expert en cas de symptômes.';

  @override
  String get voiceAnswerOlive =>
      'Pour les oliviers, surveillez les feuilles, le sol et la météo. Les besoins en eau dépendent de l’âge de l’arbre, du sol et du stade de croissance.';

  @override
  String get voiceAnswerGeneral =>
      'J’ai reçu votre question. Je peux donner des conseils généraux sur l’irrigation, les cultures et les symptômes courants. Des conseils personnalisés nécessitent un service d’IA connecté. Vous pouvez aussi contacter un expert agricole via la communauté.';

  @override
  String get weatherFarmTitle => 'Météo de votre exploitation';

  @override
  String get weatherSearchHint => 'Rechercher une ville ou une région';

  @override
  String get weatherChooseLocation =>
      'Choisissez l’emplacement de votre exploitation';

  @override
  String get weatherSearchDescription =>
      'Recherchez la ville ou la région de votre exploitation pour consulter les prévisions.';

  @override
  String get weatherFeelsLike => 'Ressenti';

  @override
  String get weatherNextHours => 'Prochaines heures';

  @override
  String get weatherOutlook => 'Prévisions sur 7 jours';

  @override
  String get weatherChanges => 'Changements notables';

  @override
  String get weatherNoChanges =>
      'Aucun changement notable prévu dans les prochaines 24 heures.';

  @override
  String get weatherSource =>
      'Données météo : Open-Meteo. Les prévisions sont des estimations.';

  @override
  String get weatherRain => 'Pluie';

  @override
  String get weatherHumidity => 'Humidité';

  @override
  String get weatherWind => 'Vent';

  @override
  String get weatherRainNow => 'Pluie actuelle';

  @override
  String get weatherWindDirection => 'Direction du vent';

  @override
  String get weatherSunrise => 'Lever du soleil';

  @override
  String get weatherSunset => 'Coucher du soleil';

  @override
  String get weatherUv => 'Indice UV max aujourd’hui';

  @override
  String get weatherSelectedLocation => 'Emplacement sélectionné';

  @override
  String get weatherLoadError =>
      'Impossible de charger la météo. Vérifiez la connexion API et l’emplacement.';

  @override
  String get weatherRainProbability => 'pluie';

  @override
  String get weatherOutlookSubtitle =>
      'Prévisions et évolution des conditions au champ.';

  @override
  String get diagnosisSubtitle =>
      'Prenez une photo de la culture pour analyse.';

  @override
  String get irrigationSubtitle =>
      'Consultez les commandes et programmes d’irrigation.';

  @override
  String get authGoogleError => 'Échec de la connexion Google. Réessayez.';

  @override
  String get authAcceptTerms =>
      'Veuillez accepter les conditions et la politique de confidentialité.';

  @override
  String get authEmailVerified => 'E-mail vérifié ! Veuillez vous connecter.';

  @override
  String get authCodeSent => 'Code de vérification envoyé à votre e-mail.';

  @override
  String get authNewCodeSent => 'Un nouveau code a été envoyé.';

  @override
  String get communityRefresh => 'Actualiser le fil';

  @override
  String get communitySearch => 'Rechercher par nom…';

  @override
  String get communityAsk => 'Demander';

  @override
  String get communityRemovePhoto => 'Supprimer la photo';

  @override
  String get communityAddPhoto => 'Ajouter une photo';

  @override
  String get communityAccept => 'Accepter';

  @override
  String get communityDecline => 'Refuser';

  @override
  String get communityRetry => 'Réessayer';

  @override
  String get communityConnectionSent => 'Demande de connexion envoyée à';

  @override
  String get communityImageError => 'Impossible de sélectionner l’image';

  @override
  String get communityPostTooLong =>
      'Les publications ne peuvent pas dépasser 5000 caractères.';

  @override
  String get communityPostPublished => 'Votre publication a été publiée.';

  @override
  String get messageTooLong =>
      'Les messages ne peuvent pas dépasser 5000 caractères.';

  @override
  String get messageHint => 'Écrire un message…';

  @override
  String get messageRetry => 'Réessayer';

  @override
  String get expertQueueTitle => 'File de révision des diagnostics';

  @override
  String get expertPhotoUnavailable => 'Photo indisponible';

  @override
  String get expertRefresh => 'Actualiser la file';

  @override
  String get expertCancel => 'Annuler';

  @override
  String get expertReject => 'Rejeter';

  @override
  String get expertValidate => 'Valider';

  @override
  String get expertLogoutQuestion => 'Se déconnecter ?';

  @override
  String get irrigationRetry => 'Réessayer';

  @override
  String get irrigationRefresh => 'Actualiser les appareils';

  @override
  String get irrigationTitle => 'Irrigation intelligente';

  @override
  String get irrigationLoadFarmsError =>
      'Impossible de charger vos exploitations.';

  @override
  String get irrigationNoFarms => 'Aucune exploitation';

  @override
  String get irrigationAddFarmFirst =>
      'Ajoutez d’abord une exploitation pour voir ses appareils d’irrigation.';

  @override
  String get irrigationSelectFarm => 'Sélectionner une exploitation';

  @override
  String get irrigationConnectedDevices => 'Appareils connectés';

  @override
  String get irrigationLoadDevicesError =>
      'Impossible de charger les appareils d’irrigation.';

  @override
  String get irrigationNoDevices => 'Aucun appareil connecté';

  @override
  String get irrigationNoDevicesDescription =>
      'Aucun appareil n’est encore enregistré pour cette exploitation.';

  @override
  String get irrigationInfo =>
      'Les relevés des appareils sont affichés lorsqu’ils sont disponibles. Les commandes et la programmation de l’arrosage ne sont pas encore prises en charge par l’API connectée.';

  @override
  String get irrigationMonitorFarm => 'Surveillez votre exploitation';

  @override
  String get irrigationMonitorDescription =>
      'Consultez les appareils d’irrigation connectés et leurs dernières mesures.';

  @override
  String get irrigationDevice => 'Appareil d’irrigation';

  @override
  String get irrigationRegistered => 'Enregistré';

  @override
  String get irrigationDeviceIdUnavailable => 'ID de l’appareil indisponible';

  @override
  String get irrigationLatestReading => 'Dernière mesure';

  @override
  String get irrigationDeviceIdUnreadable =>
      'Cet appareil ne possède pas d’identifiant lisible.';

  @override
  String get irrigationReadingUnavailable =>
      'La dernière mesure est actuellement indisponible.';

  @override
  String get irrigationNoReadings =>
      'Aucune mesure n’a encore été enregistrée pour cet appareil.';

  @override
  String get dashboardOperations => 'Activités de l’exploitation';

  @override
  String get dashboardDevices => 'Appareils enregistrés';

  @override
  String get dashboardViewIrrigation => 'Voir l’irrigation';

  @override
  String get dashboardNoDevices =>
      'Aucun appareil enregistré pour cette exploitation.';

  @override
  String get dashboardDeviceLoadError =>
      'Impossible de charger l’état des appareils.';

  @override
  String get dashboardActive => 'Actif';

  @override
  String get dashboardInactive => 'Inactif';

  @override
  String get dashboardLatestMoisture => 'Dernière humidité du sol';

  @override
  String get dashboardNoReading => 'Aucune mesure disponible';

  @override
  String dashboardReadingTime(String time) {
    return 'Enregistré à $time';
  }

  @override
  String get dashboardSimulated => 'Mesure simulée';

  @override
  String get dashboardWeatherAction => 'Ouvrir les prévisions météo';

  @override
  String get dashboardFarmProfile => 'Profil de l’exploitation';

  @override
  String get dashboardAlerts => 'Alertes de l’exploitation';

  @override
  String get dashboardNoAlerts =>
      'Aucune alerte active. Les événements des capteurs apparaîtront ici lorsque les seuils seront atteints.';

  @override
  String get dashboardAcknowledge => 'Acquitter';

  @override
  String get dashboardOnline => 'En ligne';

  @override
  String get dashboardStale => 'Données anciennes';

  @override
  String get dashboardUnknown => 'Inconnu';

  @override
  String get dashboardDisabled => 'Désactivé';

  @override
  String get weatherLocationSaved =>
      'Emplacement de l’exploitation enregistré.';

  @override
  String get authTitleWelcome => 'Bon retour';

  @override
  String get authTitleCreate => 'Cr?ez votre compte';

  @override
  String get authTitleVerify => 'V?rifiez votre adresse e-mail';

  @override
  String get authSubtitle => 'Votre plateforme agricole intelligente.';

  @override
  String get authVerifyHint =>
      'Saisissez le code ? six chiffres envoy? par e-mail.';

  @override
  String get authCodeLabel => 'Code de v?rification';

  @override
  String get authCodeInvalid => 'Saisissez le code ? six chiffres.';

  @override
  String get authResend => 'Renvoyer le code de v?rification';

  @override
  String get authNameLabel => 'Nom complet';

  @override
  String get authNameRequired => 'Saisissez votre nom complet.';

  @override
  String get authAccountType => 'Type de compte';

  @override
  String get authChooseRole => 'Choisir le type de compte';

  @override
  String get authFarmer => 'Agriculteur';

  @override
  String get authExpert => 'Expert';

  @override
  String get authEmailLabel => 'Adresse e-mail';

  @override
  String get authEmailInvalid => 'Saisissez une adresse e-mail valide.';

  @override
  String get authPasswordLabel => 'Mot de passe';

  @override
  String get authPasswordRequired => 'Saisissez votre mot de passe.';

  @override
  String get authPasswordLength => 'Utilisez au moins 12 caract?res.';

  @override
  String get authTerms =>
      'J?accepte les conditions et la politique de confidentialit?.';

  @override
  String get authVerifyButton => 'V?RIFIER L?E-MAIL';

  @override
  String get authCreateButton => 'CR?ER UN COMPTE';

  @override
  String get authSignInButton => 'SE CONNECTER';

  @override
  String get authDivider => 'OU';

  @override
  String get authGoogleButton => 'Continuer avec Google';

  @override
  String get authSwitchSignIn => 'Vous avez d?j? un compte ? Connectez-vous';

  @override
  String get authSwitchSignUp => 'Nouveau sur AETHERA ? Cr?ez un compte';

  @override
  String get adminHeader => 'Tableau de bord admin';

  @override
  String get adminOverview => 'Vue d?ensemble';

  @override
  String get adminTotalUsers => 'Utilisateurs';

  @override
  String get adminActiveUsers => 'Utilisateurs actifs';

  @override
  String get adminFarmers => 'Agriculteurs';

  @override
  String get adminExperts => 'Experts';

  @override
  String get adminPendingExperts => 'Experts en attente';

  @override
  String get adminApplications => 'Candidatures d?experts';

  @override
  String get adminNoApplications => 'Aucune candidature d?expert ? examiner.';

  @override
  String get adminUsers => 'Comptes utilisateurs';

  @override
  String get adminNoUsers => 'Aucun compte utilisateur trouv?.';

  @override
  String get adminApprove => 'Approuver';

  @override
  String get adminReject => 'Refuser';

  @override
  String get adminUserActive => 'Actif';

  @override
  String get adminUserInactive => 'Inactif';

  @override
  String get adminLogout => 'Se d?connecter';

  @override
  String get adminLoadFailed =>
      'Impossible de charger le tableau de bord admin.';

  @override
  String get adminRetry => 'R?essayer';

  @override
  String get adminRoleAdmin => 'Administrateur';

  @override
  String get adminStatusUpdated => 'Statut du compte mis ? jour.';

  @override
  String get diagnosisTitle => 'Diagnostic des cultures';

  @override
  String get diagnosisRefresh => 'Actualiser les dossiers';

  @override
  String get diagnosisLoadError =>
      'Impossible de charger les donn?es. V?rifiez votre connexion.';

  @override
  String get diagnosisPhotoError => 'Impossible d?ouvrir la photo.';

  @override
  String get diagnosisAddFarm => 'Veuillez d?abord ajouter une exploitation.';

  @override
  String get diagnosisSelectPhoto => 'Veuillez choisir une photo de culture.';

  @override
  String get diagnosisDescribeSymptoms =>
      'D?crivez les sympt?mes plus en d?tail.';

  @override
  String get diagnosisNew => 'Nouveau diagnostic de culture';

  @override
  String get diagnosisInstructions =>
      'Envoyez une photo et les sympt?mes ? un expert agricole.';

  @override
  String get diagnosisSelectFarm => 'Choisissez votre exploitation';

  @override
  String get diagnosisChoosePhoto => 'Choisir une photo';

  @override
  String get diagnosisChangePhoto => 'Changer la photo';

  @override
  String get diagnosisSymptoms => 'D?crire les sympt?mes';

  @override
  String get diagnosisSymptomExample =>
      'Exemple : taches jaunes sur les feuilles, fl?trissement?';

  @override
  String get diagnosisSubmitting => 'Envoi?';

  @override
  String get diagnosisSubmit => 'Envoyer ? un expert';

  @override
  String get diagnosisFarmRequired =>
      'Ajoutez une exploitation dans l?onglet Exploitations avant le diagnostic.';

  @override
  String get diagnosisCaseSubmitted =>
      'Dossier envoy?. Un expert peut maintenant l?examiner.';

  @override
  String diagnosisSubmissionFailed(String error) {
    return '?chec de l?envoi : $error';
  }

  @override
  String diagnosisServerError(String status) {
    return 'Erreur du serveur ($status)';
  }

  @override
  String get diagnosisPendingStatus => 'En attente d?un expert';

  @override
  String get diagnosisValidatedStatus => 'Valid? par un expert';

  @override
  String get diagnosisRejectedStatus => 'Refus? / ? r?examiner';

  @override
  String get diagnosisExpertDiagnosis => 'Diagnostic de l?expert';

  @override
  String get diagnosisExpertRecommendation => 'Recommandation de l?expert';

  @override
  String diagnosisSubmittedAt(String time) {
    return 'Envoy? : $time';
  }

  @override
  String get diagnosisMyCases => 'Mes dossiers de diagnostic';

  @override
  String get diagnosisCasesDescription =>
      'Suivez vos envois et les retours des experts.';

  @override
  String get diagnosisNoCases => 'Aucun dossier de diagnostic.';

  @override
  String get diagnosisRetry => 'R?essayer';

  @override
  String get authInvalidCredentials =>
      'Adresse e-mail ou mot de passe incorrect.';

  @override
  String get authGoogleConfiguration =>
      'La connexion Google n?est pas configur?e sur le serveur. Ajoutez les identifiants Firebase Admin puis red?marrez l?API.';

  @override
  String get authGoogleInvalid =>
      'La connexion Google n?a pas pu ?tre v?rifi?e. V?rifiez la configuration Firebase.';

  @override
  String get authConnectionError => 'Connexion impossible. Veuillez r?essayer.';
}
