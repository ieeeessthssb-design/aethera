import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('ar'),
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'AETHERA'**
  String get appName;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Grow smarter. Farm better.'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your intelligent agricultural companion.'**
  String get welcomeSubtitle;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Your farm at a glance'**
  String get dashboardTitle;

  /// No description provided for @dashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Everything you need to grow with confidence.'**
  String get dashboardSubtitle;

  /// No description provided for @greeting.
  ///
  /// In en, this message translates to:
  /// **'Welcome back!'**
  String get greeting;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get theme;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @french.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get french;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// No description provided for @assistant.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get assistant;

  /// No description provided for @diagnosis.
  ///
  /// In en, this message translates to:
  /// **'Crop Diagnosis'**
  String get diagnosis;

  /// No description provided for @irrigation.
  ///
  /// In en, this message translates to:
  /// **'Smart Irrigation'**
  String get irrigation;

  /// No description provided for @community.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get community;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get profile;

  /// No description provided for @weather.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get weather;

  /// No description provided for @soilMoisture.
  ///
  /// In en, this message translates to:
  /// **'Soil Moisture'**
  String get soilMoisture;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Application Preferences'**
  String get preferences;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get chooseLanguage;

  /// No description provided for @chooseTheme.
  ///
  /// In en, this message translates to:
  /// **'Choose your appearance'**
  String get chooseTheme;

  /// No description provided for @backToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to home'**
  String get backToHome;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @farms.
  ///
  /// In en, this message translates to:
  /// **'Farms'**
  String get farms;

  /// No description provided for @messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// No description provided for @collapseSidebar.
  ///
  /// In en, this message translates to:
  /// **'Collapse sidebar'**
  String get collapseSidebar;

  /// No description provided for @expandSidebar.
  ///
  /// In en, this message translates to:
  /// **'Expand sidebar'**
  String get expandSidebar;

  /// No description provided for @openNavigation.
  ///
  /// In en, this message translates to:
  /// **'Open navigation'**
  String get openNavigation;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @managePersonalDetails.
  ///
  /// In en, this message translates to:
  /// **'Manage your personal details'**
  String get managePersonalDetails;

  /// No description provided for @manageAccountPreferences.
  ///
  /// In en, this message translates to:
  /// **'Manage your AETHERA account and preferences.'**
  String get manageAccountPreferences;

  /// No description provided for @farmerAccount.
  ///
  /// In en, this message translates to:
  /// **'Farmer account'**
  String get farmerAccount;

  /// No description provided for @personalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal information'**
  String get personalInformation;

  /// No description provided for @personalInformationMessage.
  ///
  /// In en, this message translates to:
  /// **'Your farmer account information will appear here.'**
  String get personalInformationMessage;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help and support'**
  String get helpSupport;

  /// No description provided for @helpSupportMessage.
  ///
  /// In en, this message translates to:
  /// **'For assistance with AETHERA, please contact our support team.'**
  String get helpSupportMessage;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @logoutQuestion.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get logoutQuestion;

  /// No description provided for @logoutConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get logoutConfirmation;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @addFarm.
  ///
  /// In en, this message translates to:
  /// **'Add a farm'**
  String get addFarm;

  /// No description provided for @farmName.
  ///
  /// In en, this message translates to:
  /// **'Farm name *'**
  String get farmName;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location *'**
  String get location;

  /// No description provided for @areaHectares.
  ///
  /// In en, this message translates to:
  /// **'Area in hectares'**
  String get areaHectares;

  /// No description provided for @soilType.
  ///
  /// In en, this message translates to:
  /// **'Soil type'**
  String get soilType;

  /// No description provided for @irrigationType.
  ///
  /// In en, this message translates to:
  /// **'Irrigation type'**
  String get irrigationType;

  /// No description provided for @saveFarm.
  ///
  /// In en, this message translates to:
  /// **'Save farm'**
  String get saveFarm;

  /// No description provided for @farmAdded.
  ///
  /// In en, this message translates to:
  /// **'Farm added successfully!'**
  String get farmAdded;

  /// No description provided for @farmLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load farms. Please check your connection.'**
  String get farmLoadError;

  /// No description provided for @farmSaveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save farm: {error}'**
  String farmSaveError(String error);

  /// No description provided for @noFarms.
  ///
  /// In en, this message translates to:
  /// **'No farms added yet'**
  String get noFarms;

  /// No description provided for @addFirstFarm.
  ///
  /// In en, this message translates to:
  /// **'Tap Add farm to register your first farm.'**
  String get addFirstFarm;

  /// No description provided for @yourFarms.
  ///
  /// In en, this message translates to:
  /// **'Your farms'**
  String get yourFarms;

  /// No description provided for @manageFarms.
  ///
  /// In en, this message translates to:
  /// **'Manage your land and agricultural activities.'**
  String get manageFarms;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @enterTwoChars.
  ///
  /// In en, this message translates to:
  /// **'Please enter at least 2 characters.'**
  String get enterTwoChars;

  /// No description provided for @enterPositiveNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a number greater than zero.'**
  String get enterPositiveNumber;

  /// No description provided for @notSpecified.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get notSpecified;

  /// No description provided for @area.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get area;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @chooseFarm.
  ///
  /// In en, this message translates to:
  /// **'Choose a farm'**
  String get chooseFarm;

  /// No description provided for @locationExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. Sousse, Tunisia'**
  String get locationExample;

  /// No description provided for @areaExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. 5.5'**
  String get areaExample;

  /// No description provided for @soilExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. Clay, sandy, loamy'**
  String get soilExample;

  /// No description provided for @irrigationExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. Drip, sprinkler'**
  String get irrigationExample;

  /// No description provided for @hectares.
  ///
  /// In en, this message translates to:
  /// **'hectares'**
  String get hectares;

  /// No description provided for @fieldIntelligence.
  ///
  /// In en, this message translates to:
  /// **'AETHERA FIELD INTELLIGENCE'**
  String get fieldIntelligence;

  /// No description provided for @fieldTagline.
  ///
  /// In en, this message translates to:
  /// **'Make every field decision count.'**
  String get fieldTagline;

  /// No description provided for @fieldDescription.
  ///
  /// In en, this message translates to:
  /// **'Ask about irrigation, crop symptoms and farm care.'**
  String get fieldDescription;

  /// No description provided for @exploreTools.
  ///
  /// In en, this message translates to:
  /// **'Explore your tools'**
  String get exploreTools;

  /// No description provided for @talkToAethera.
  ///
  /// In en, this message translates to:
  /// **'Talk to AETHERA'**
  String get talkToAethera;

  /// No description provided for @voiceAssistantDescription.
  ///
  /// In en, this message translates to:
  /// **'Press and hold the microphone to speak in Tunisian Derja.'**
  String get voiceAssistantDescription;

  /// No description provided for @voiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Agricultural assistant'**
  String get voiceTitle;

  /// No description provided for @voiceListening.
  ///
  /// In en, this message translates to:
  /// **'Listening… speak now'**
  String get voiceListening;

  /// No description provided for @voiceSpeaking.
  ///
  /// In en, this message translates to:
  /// **'AETHERA is responding…'**
  String get voiceSpeaking;

  /// No description provided for @voiceWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to AETHERA'**
  String get voiceWelcome;

  /// No description provided for @voiceListeningHint.
  ///
  /// In en, this message translates to:
  /// **'Release the microphone when you finish.'**
  String get voiceListeningHint;

  /// No description provided for @voiceInstruction.
  ///
  /// In en, this message translates to:
  /// **'Press and hold the microphone to speak.'**
  String get voiceInstruction;

  /// No description provided for @voicePressHold.
  ///
  /// In en, this message translates to:
  /// **'PRESS & HOLD'**
  String get voicePressHold;

  /// No description provided for @voiceInputHint.
  ///
  /// In en, this message translates to:
  /// **'Or type your question here…'**
  String get voiceInputHint;

  /// No description provided for @voiceAsk.
  ///
  /// In en, this message translates to:
  /// **'Ask AETHERA'**
  String get voiceAsk;

  /// No description provided for @voiceQuestion.
  ///
  /// In en, this message translates to:
  /// **'Your question'**
  String get voiceQuestion;

  /// No description provided for @voiceNoQuestion.
  ///
  /// In en, this message translates to:
  /// **'No question recorded yet.'**
  String get voiceNoQuestion;

  /// No description provided for @voiceAnswer.
  ///
  /// In en, this message translates to:
  /// **'Answer'**
  String get voiceAnswer;

  /// No description provided for @voiceStopAudio.
  ///
  /// In en, this message translates to:
  /// **'Stop audio'**
  String get voiceStopAudio;

  /// No description provided for @voiceListenAnswer.
  ///
  /// In en, this message translates to:
  /// **'Listen to answer'**
  String get voiceListenAnswer;

  /// No description provided for @voiceDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'These suggestions are preliminary. For unclear diseases or pests, consult an agricultural expert before treatment.'**
  String get voiceDisclaimer;

  /// No description provided for @voiceSpeechUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Speech recognition is unavailable. You can type your question instead.'**
  String get voiceSpeechUnavailable;

  /// No description provided for @voiceMicError.
  ///
  /// In en, this message translates to:
  /// **'The microphone could not be started.'**
  String get voiceMicError;

  /// No description provided for @voiceAudioError.
  ///
  /// In en, this message translates to:
  /// **'Audio playback failed. You can read the answer instead.'**
  String get voiceAudioError;

  /// No description provided for @voiceAnswerWater.
  ///
  /// In en, this message translates to:
  /// **'Check soil moisture before watering. Avoid overwatering and consider the crop, soil type and weather.'**
  String get voiceAnswerWater;

  /// No description provided for @voiceAnswerYellow.
  ///
  /// In en, this message translates to:
  /// **'Yellow leaves can result from too much or too little water, or nutrient deficiency. Check soil moisture and whether older or newer leaves are affected. A precise diagnosis may require a photo and expert review.'**
  String get voiceAnswerYellow;

  /// No description provided for @voiceAnswerPest.
  ///
  /// In en, this message translates to:
  /// **'If you suspect a disease or insect, photograph the plant and affected leaves. Do not apply pesticides before identifying the problem. Ask an agricultural expert to review the image.'**
  String get voiceAnswerPest;

  /// No description provided for @voiceAnswerTomato.
  ///
  /// In en, this message translates to:
  /// **'For tomatoes, monitor soil moisture and avoid overwatering. Check leaves and fruit for disease symptoms and consult an expert if symptoms appear.'**
  String get voiceAnswerTomato;

  /// No description provided for @voiceAnswerOlive.
  ///
  /// In en, this message translates to:
  /// **'For olive trees, monitor leaves, soil and weather. Water needs depend on tree age, soil type and growth stage.'**
  String get voiceAnswerOlive;

  /// No description provided for @voiceAnswerGeneral.
  ///
  /// In en, this message translates to:
  /// **'I received your question. I can provide general guidance about irrigation, crops and common symptoms. Personalized AI advice requires connecting an AI service. You can also contact an agricultural expert through the community.'**
  String get voiceAnswerGeneral;

  /// No description provided for @weatherFarmTitle.
  ///
  /// In en, this message translates to:
  /// **'Weather for your farm'**
  String get weatherFarmTitle;

  /// No description provided for @weatherSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search a town or region'**
  String get weatherSearchHint;

  /// No description provided for @weatherChooseLocation.
  ///
  /// In en, this message translates to:
  /// **'Choose your farm location'**
  String get weatherChooseLocation;

  /// No description provided for @weatherSearchDescription.
  ///
  /// In en, this message translates to:
  /// **'Search for the town or region where your farm is located to see its live forecast.'**
  String get weatherSearchDescription;

  /// No description provided for @weatherFeelsLike.
  ///
  /// In en, this message translates to:
  /// **'Feels like'**
  String get weatherFeelsLike;

  /// No description provided for @weatherNextHours.
  ///
  /// In en, this message translates to:
  /// **'Next hours'**
  String get weatherNextHours;

  /// No description provided for @weatherOutlook.
  ///
  /// In en, this message translates to:
  /// **'7-day outlook'**
  String get weatherOutlook;

  /// No description provided for @weatherChanges.
  ///
  /// In en, this message translates to:
  /// **'Notable changes'**
  String get weatherChanges;

  /// No description provided for @weatherNoChanges.
  ///
  /// In en, this message translates to:
  /// **'No notable changes detected in the next 24 hours.'**
  String get weatherNoChanges;

  /// No description provided for @weatherSource.
  ///
  /// In en, this message translates to:
  /// **'Weather data: Open-Meteo. Forecasts are estimates, not guarantees.'**
  String get weatherSource;

  /// No description provided for @weatherRain.
  ///
  /// In en, this message translates to:
  /// **'Rain'**
  String get weatherRain;

  /// No description provided for @weatherHumidity.
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get weatherHumidity;

  /// No description provided for @weatherWind.
  ///
  /// In en, this message translates to:
  /// **'Wind'**
  String get weatherWind;

  /// No description provided for @weatherRainNow.
  ///
  /// In en, this message translates to:
  /// **'Rain now'**
  String get weatherRainNow;

  /// No description provided for @weatherWindDirection.
  ///
  /// In en, this message translates to:
  /// **'Wind direction'**
  String get weatherWindDirection;

  /// No description provided for @weatherSunrise.
  ///
  /// In en, this message translates to:
  /// **'Sunrise'**
  String get weatherSunrise;

  /// No description provided for @weatherSunset.
  ///
  /// In en, this message translates to:
  /// **'Sunset'**
  String get weatherSunset;

  /// No description provided for @weatherUv.
  ///
  /// In en, this message translates to:
  /// **'UV max today'**
  String get weatherUv;

  /// No description provided for @weatherSelectedLocation.
  ///
  /// In en, this message translates to:
  /// **'Selected location'**
  String get weatherSelectedLocation;

  /// No description provided for @weatherLoadError.
  ///
  /// In en, this message translates to:
  /// **'Weather could not be loaded. Check the API connection and location.'**
  String get weatherLoadError;

  /// No description provided for @weatherRainProbability.
  ///
  /// In en, this message translates to:
  /// **'rain'**
  String get weatherRainProbability;

  /// No description provided for @weatherOutlookSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Forecasts and changing field conditions.'**
  String get weatherOutlookSubtitle;

  /// No description provided for @diagnosisSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Capture a crop photo for assessment.'**
  String get diagnosisSubtitle;

  /// No description provided for @irrigationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review irrigation controls and schedules.'**
  String get irrigationSubtitle;

  /// No description provided for @authGoogleError.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed. Please try again.'**
  String get authGoogleError;

  /// No description provided for @authAcceptTerms.
  ///
  /// In en, this message translates to:
  /// **'Please accept the terms and privacy policy.'**
  String get authAcceptTerms;

  /// No description provided for @authEmailVerified.
  ///
  /// In en, this message translates to:
  /// **'Email verified! Please sign in.'**
  String get authEmailVerified;

  /// No description provided for @authCodeSent.
  ///
  /// In en, this message translates to:
  /// **'Verification code sent to your email.'**
  String get authCodeSent;

  /// No description provided for @authNewCodeSent.
  ///
  /// In en, this message translates to:
  /// **'A new code has been sent.'**
  String get authNewCodeSent;

  /// No description provided for @communityRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh feed'**
  String get communityRefresh;

  /// No description provided for @communitySearch.
  ///
  /// In en, this message translates to:
  /// **'Search by name...'**
  String get communitySearch;

  /// No description provided for @communityAsk.
  ///
  /// In en, this message translates to:
  /// **'Ask'**
  String get communityAsk;

  /// No description provided for @communityRemovePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get communityRemovePhoto;

  /// No description provided for @communityAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get communityAddPhoto;

  /// No description provided for @communityAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get communityAccept;

  /// No description provided for @communityDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get communityDecline;

  /// No description provided for @communityRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get communityRetry;

  /// No description provided for @communityConnectionSent.
  ///
  /// In en, this message translates to:
  /// **'Connection request sent to'**
  String get communityConnectionSent;

  /// No description provided for @communityImageError.
  ///
  /// In en, this message translates to:
  /// **'Could not select image'**
  String get communityImageError;

  /// No description provided for @communityPostTooLong.
  ///
  /// In en, this message translates to:
  /// **'Posts cannot exceed 5000 characters.'**
  String get communityPostTooLong;

  /// No description provided for @communityPostPublished.
  ///
  /// In en, this message translates to:
  /// **'Your post was published.'**
  String get communityPostPublished;

  /// No description provided for @messageTooLong.
  ///
  /// In en, this message translates to:
  /// **'Messages cannot exceed 5000 characters.'**
  String get messageTooLong;

  /// No description provided for @messageHint.
  ///
  /// In en, this message translates to:
  /// **'Write a message...'**
  String get messageHint;

  /// No description provided for @messageRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get messageRetry;

  /// No description provided for @expertQueueTitle.
  ///
  /// In en, this message translates to:
  /// **'Diagnosis review queue'**
  String get expertQueueTitle;

  /// No description provided for @expertPhotoUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Photo unavailable'**
  String get expertPhotoUnavailable;

  /// No description provided for @expertRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh queue'**
  String get expertRefresh;

  /// No description provided for @expertCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get expertCancel;

  /// No description provided for @expertReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get expertReject;

  /// No description provided for @expertValidate.
  ///
  /// In en, this message translates to:
  /// **'Validate'**
  String get expertValidate;

  /// No description provided for @expertLogoutQuestion.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get expertLogoutQuestion;

  /// No description provided for @irrigationRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get irrigationRetry;

  /// No description provided for @irrigationRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh devices'**
  String get irrigationRefresh;

  /// No description provided for @irrigationTitle.
  ///
  /// In en, this message translates to:
  /// **'Smart Irrigation'**
  String get irrigationTitle;

  /// No description provided for @irrigationLoadFarmsError.
  ///
  /// In en, this message translates to:
  /// **'Could not load your farms.'**
  String get irrigationLoadFarmsError;

  /// No description provided for @irrigationNoFarms.
  ///
  /// In en, this message translates to:
  /// **'No farms yet'**
  String get irrigationNoFarms;

  /// No description provided for @irrigationAddFarmFirst.
  ///
  /// In en, this message translates to:
  /// **'Add a farm first to view its irrigation devices.'**
  String get irrigationAddFarmFirst;

  /// No description provided for @irrigationSelectFarm.
  ///
  /// In en, this message translates to:
  /// **'Select farm'**
  String get irrigationSelectFarm;

  /// No description provided for @irrigationConnectedDevices.
  ///
  /// In en, this message translates to:
  /// **'Connected devices'**
  String get irrigationConnectedDevices;

  /// No description provided for @irrigationLoadDevicesError.
  ///
  /// In en, this message translates to:
  /// **'Could not load irrigation devices.'**
  String get irrigationLoadDevicesError;

  /// No description provided for @irrigationNoDevices.
  ///
  /// In en, this message translates to:
  /// **'No devices connected'**
  String get irrigationNoDevices;

  /// No description provided for @irrigationNoDevicesDescription.
  ///
  /// In en, this message translates to:
  /// **'There are no registered devices for this farm yet.'**
  String get irrigationNoDevicesDescription;

  /// No description provided for @irrigationInfo.
  ///
  /// In en, this message translates to:
  /// **'Device readings are shown when available. Watering controls and scheduling are not currently supported by the connected API.'**
  String get irrigationInfo;

  /// No description provided for @irrigationMonitorFarm.
  ///
  /// In en, this message translates to:
  /// **'Monitor your farm'**
  String get irrigationMonitorFarm;

  /// No description provided for @irrigationMonitorDescription.
  ///
  /// In en, this message translates to:
  /// **'View connected irrigation devices and their latest readings.'**
  String get irrigationMonitorDescription;

  /// No description provided for @irrigationDevice.
  ///
  /// In en, this message translates to:
  /// **'Irrigation device'**
  String get irrigationDevice;

  /// No description provided for @irrigationRegistered.
  ///
  /// In en, this message translates to:
  /// **'Registered'**
  String get irrigationRegistered;

  /// No description provided for @irrigationDeviceIdUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Device ID unavailable'**
  String get irrigationDeviceIdUnavailable;

  /// No description provided for @irrigationLatestReading.
  ///
  /// In en, this message translates to:
  /// **'Latest reading'**
  String get irrigationLatestReading;

  /// No description provided for @irrigationDeviceIdUnreadable.
  ///
  /// In en, this message translates to:
  /// **'This device does not have a readable ID.'**
  String get irrigationDeviceIdUnreadable;

  /// No description provided for @irrigationReadingUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Latest reading is currently unavailable.'**
  String get irrigationReadingUnavailable;

  /// No description provided for @irrigationNoReadings.
  ///
  /// In en, this message translates to:
  /// **'No readings have been recorded for this device yet.'**
  String get irrigationNoReadings;

  /// No description provided for @dashboardOperations.
  ///
  /// In en, this message translates to:
  /// **'Farm operations'**
  String get dashboardOperations;

  /// No description provided for @dashboardDevices.
  ///
  /// In en, this message translates to:
  /// **'Registered devices'**
  String get dashboardDevices;

  /// No description provided for @dashboardViewIrrigation.
  ///
  /// In en, this message translates to:
  /// **'View irrigation'**
  String get dashboardViewIrrigation;

  /// No description provided for @dashboardNoDevices.
  ///
  /// In en, this message translates to:
  /// **'No devices registered for this farm.'**
  String get dashboardNoDevices;

  /// No description provided for @dashboardDeviceLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load device status.'**
  String get dashboardDeviceLoadError;

  /// No description provided for @dashboardActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get dashboardActive;

  /// No description provided for @dashboardInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get dashboardInactive;

  /// No description provided for @dashboardLatestMoisture.
  ///
  /// In en, this message translates to:
  /// **'Latest soil moisture'**
  String get dashboardLatestMoisture;

  /// No description provided for @dashboardNoReading.
  ///
  /// In en, this message translates to:
  /// **'No sensor reading yet'**
  String get dashboardNoReading;

  /// No description provided for @dashboardReadingTime.
  ///
  /// In en, this message translates to:
  /// **'Recorded {time}'**
  String dashboardReadingTime(String time);

  /// No description provided for @dashboardSimulated.
  ///
  /// In en, this message translates to:
  /// **'Simulated reading'**
  String get dashboardSimulated;

  /// No description provided for @dashboardWeatherAction.
  ///
  /// In en, this message translates to:
  /// **'Open weather forecast'**
  String get dashboardWeatherAction;

  /// No description provided for @dashboardFarmProfile.
  ///
  /// In en, this message translates to:
  /// **'Farm profile'**
  String get dashboardFarmProfile;

  /// No description provided for @dashboardAlerts.
  ///
  /// In en, this message translates to:
  /// **'Farm alerts'**
  String get dashboardAlerts;

  /// No description provided for @dashboardNoAlerts.
  ///
  /// In en, this message translates to:
  /// **'No active alerts. Sensor conditions will appear here when thresholds are reached.'**
  String get dashboardNoAlerts;

  /// No description provided for @dashboardAcknowledge.
  ///
  /// In en, this message translates to:
  /// **'Acknowledge'**
  String get dashboardAcknowledge;

  /// No description provided for @dashboardOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get dashboardOnline;

  /// No description provided for @dashboardStale.
  ///
  /// In en, this message translates to:
  /// **'Stale'**
  String get dashboardStale;

  /// No description provided for @dashboardUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get dashboardUnknown;

  /// No description provided for @dashboardDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get dashboardDisabled;

  /// No description provided for @weatherLocationSaved.
  ///
  /// In en, this message translates to:
  /// **'Farm location saved.'**
  String get weatherLocationSaved;
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
      <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
